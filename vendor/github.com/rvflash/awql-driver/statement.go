package awql

import (
	"database/sql/driver"
	"encoding/csv"
	"fmt"
	"hash/fnv"
	"io"
	"io/ioutil"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

const (
	apiURL     = "https://adwords.google.com/api/adwords/reportdownload/"
	apiFmt     = "CSV"
	apiTimeout = time.Duration(10 * time.Minute)
)

// Stmt is a prepared statement.
type Stmt struct {
	Db       *Conn
	SrcQuery string
}

// Bind applies the required argument replacements on the query.
func (s *Stmt) Bind(args []driver.Value) error {
	if na := s.NumInput(); len(args) < na {
		// Number of placements to replace exceeds the number of inputs.
		return ErrQueryBinding
	}
	q := s.SrcQuery
	for _, rv := range args {
		var v string
		switch rv.(type) {
		case float64, float32:
			// Decimal point
			v = fmt.Sprintf("%f", rv)
		case int64, int:
			// Decimal (base 10)
			v = fmt.Sprintf("%d", rv)
		case bool:
			// TRUE or FALSE
			v = strings.ToUpper(fmt.Sprintf("%t", rv))
		default:
			// Double-quoted string safely escaped
			v = fmt.Sprintf("%q", rv)
		}
		q = strings.Replace(q, "?", v, 1)
	}
	s.SrcQuery = q

	return nil
}

// Close closes the statement.
func (s *Stmt) Close() error {
	return nil
}

// Exec executes a query that doesn't return rows, such as an INSERT or UPDATE.
func (s *Stmt) Exec(args []driver.Value) (driver.Result, error) {
	return nil, driver.ErrSkip
}

// Hash returns a hash that represents the statement.
// Of course, the binding must have already been done to make sense.
func (s *Stmt) Hash() (string, error) {
	if s.SrcQuery == "" {
		return "", ErrQuery
	}
	h := fnv.New64()
	if _, err := h.Write([]byte(strings.ToLower(s.SrcQuery))); err != nil {
		return "", err
	}
	return strconv.FormatUint(h.Sum64(), 10), nil
}

// NumInput returns the number of placeholder parameters.
func (s *Stmt) NumInput() int {
	return strings.Count(s.SrcQuery, "?")
}

// Query sends request to Google Adwords API and retrieves its content.
func (s *Stmt) Query(args []driver.Value) (driver.Rows, error) {
	// Binds all the args on the query
	if err := s.Bind(args); err != nil {
		return nil, err
	}
	// Saves response in a file named with the hash64 of the query.
	f, err := s.filePath()
	if err != nil {
		return nil, err
	}
	// Downloads the report
	if err := s.download(f); err != nil {
		return nil, err
	}
	// Parse the CSV report.
	d, err := os.Open(f)
	if err != nil {
		return nil, err
	}
	defer d.Close()

	rs, err := csv.NewReader(d).ReadAll()
	if err != nil {
		return nil, err
	}
	// Starts the index to 1 in order to ignore the column header.
	var offset int
	if !s.Db.opts.SkipColumnHeader {
		offset = 1
	}
	if l := len(rs); l > offset {
		return &Rows{Size: l, Data: rs, Position: offset}, nil
	}
	return &Rows{}, nil
}

// download calls Adwords API and saves response in a file.
func (s *Stmt) download(name string) error {
	rq, err := http.NewRequest(
		"POST", apiURL+s.Db.opts.Version,
		strings.NewReader(url.Values{"__rdquery": {s.SrcQuery}, "__fmt": {apiFmt}}.Encode()),
	)
	if err != nil {
		return err
	}
	s.Db.client.Timeout = apiTimeout

	// @see https://developers.google.com/adwords/api/docs/guides/reporting#request_headers
	rq.Header.Add("Content-Type", "application/x-www-form-urlencoded; param=value")
	rq.Header.Add("Accept", "*/*")
	rq.Header.Add("clientCustomerId", s.Db.adwordsID)
	rq.Header.Add("developerToken", s.Db.developerToken)
	rq.Header.Add("includeZeroImpressions", strconv.FormatBool(s.Db.opts.IncludeZeroImpressions))
	rq.Header.Add("skipColumnHeader", strconv.FormatBool(s.Db.opts.SkipColumnHeader))
	rq.Header.Add("skipReportHeader", strconv.FormatBool(s.Db.opts.SkipReportHeader))
	rq.Header.Add("skipReportSummary", strconv.FormatBool(s.Db.opts.SkipReportSummary))
	rq.Header.Add("useRawEnumValues", strconv.FormatBool(s.Db.opts.UseRawEnumValues))

	// Uses access token to fetch report
	if s.Db.oAuth != nil {
		if err := s.Db.authenticate(); err != nil {
			return ErrBadToken
		}
		rq.Header.Add("Authorization", s.Db.oAuth.String())
	}

	// Downloads the report
	resp, err := s.Db.client.Do(rq)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	// Manages response in error
	if resp.StatusCode != http.StatusOK {
		switch resp.StatusCode {
		case 0:
			return ErrNoNetwork
		case http.StatusBadRequest:
			out, _ := ioutil.ReadAll(resp.Body)
			return NewAPIError(out)
		default:
			return ErrBadNetwork
		}
	}

	// Saves response in a file
	out, err := os.Create(name)
	if err != nil {
		return err
	}
	defer out.Close()

	_, err = io.Copy(out, resp.Body)
	return err
}

// filePath returns the file path to save the response of the query.
// @example /tmp/awql16027257112758723916.csv
func (s *Stmt) filePath() (string, error) {
	hash, err := s.Hash()
	if err != nil {
		return "", nil
	}
	path := []string{"awql", hash, ".", strings.ToLower(apiFmt)}

	return filepath.Join(os.TempDir(), strings.Join(path, "")), nil
}
