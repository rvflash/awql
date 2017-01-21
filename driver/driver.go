package driver

import (
	"database/sql"
	"database/sql/driver"
	"errors"
	"io"
	"strings"

	db "github.com/rvflash/awql-db"
	awql "github.com/rvflash/awql-driver"
	parser "github.com/rvflash/awql-parser"
)

// Driver implements all methods to pretend as a sql database driver.
// It is an advanced version of Awql driver.
// It adds cache, the possibility to get database details.
type AdvancedDriver struct{}

// init adds advanced awql as sql database driver.
// @see https://github.com/golang/go/wiki/SQLDrivers
func init() {
	sql.Register("aawql", &AdvancedDriver{})
}

// Open returns a new connection to the database.
// @see DatabaseDir|AdwordsId[:ApiVersion]|DeveloperToken[|AccessToken]
// @see DatabaseDir|AdwordsId[:ApiVersion]|DeveloperToken[|ClientId][|ClientSecret][|RefreshToken]
// @see DatabaseDir|AdwordsId[:ApiVersion:SupportsZeroImpressions]|DeveloperToken[|ClientId][|ClientSecret][|RefreshToken]
// @example /data/base/dir|123-456-7890:v201607:true|dEve1op3er7okeN|1234567890-c1i3n7iD.com|c1ien753cr37|1/R3Fr35h-70k3n
func (d *AdvancedDriver) Open(dsn string) (driver.Conn, error) {
	// Gets the dsn and the database directory.
	var dataSource = func(s string) (dsn, src string) {
		d := strings.SplitN(s, awql.DsnSep, 2)
		if len(d) == 1 {
			return d[0], ""
		}
		return d[1], d[0]
	}
	// Gets the API version to use.
	var apiVersion = func(s string) string {
		d := strings.Split(strings.Split(s, awql.DsnSep)[0], awql.DsnOptSep)
		if len(d) > 1 {
			return d[1]
		}
		return awql.ApiVersion
	}
	dsn, src := dataSource(dsn)

	// Wraps the Awql driver.
	dd := &awql.Driver{}
	conn, err := dd.Open(dsn)
	if err != nil {
		return nil, err
	}

	// Loads all information about the database.
	c := &Conn{
		cn: conn.(*awql.Conn),
		db: db.NewDb(apiVersion(dsn), src),
	}
	if err := c.db.Load(); err != nil {
		return nil, err
	}

	return c, nil
}

// Conn represents a connection to a database and implements driver.Conn.
type Conn struct {
	cn *awql.Conn
	db *db.Database
}

// Close marks this connection as no longer in use.
func (c *Conn) Close() error {
	return c.cn.Close()
}

// Begin is dedicated to start a transaction and awql does not support it.
func (c *Conn) Begin() (driver.Tx, error) {
	return c.cn.Begin()
}

// Prepare returns a prepared statement, bound to this connection.
func (c *Conn) Prepare(q string) (driver.Stmt, error) {
	if q == "" {
		// No query to prepare.
		return nil, io.EOF
	}
	return &Stmt{si: &awql.Stmt{Db: c.cn, SrcQuery: q}, db: c.db}, nil
}

// Stmt is a prepared statement.
type Stmt struct {
	si *awql.Stmt
	db *db.Database
	p  parser.Stmt
}

// Bind applies the required argument replacements on the query.
func (s *Stmt) Bind(args []driver.Value) error {
	// Binds all arguments on the query.
	if err := s.si.Bind(args); err != nil {
		return err
	}
	// Parses the statement to manage it as expected by Google Adwords.
	stmts, err := parser.NewParser(strings.NewReader(s.si.SrcQuery)).Parse()
	if err != nil {
		return err
	}
	if len(stmts) > 1 {
		return errors.New("QueryError.UNSUPPORTED_MULTI_QUERIES")
	}
	s.p = stmts[0]

	return nil
}

// Close closes the statement.
func (s *Stmt) Close() error {
	return s.si.Close()
}

// NumInput returns the number of placeholder parameters.
func (s *Stmt) NumInput() int {
	return s.si.NumInput()
}

// Exec executes a query that doesn't return rows, such as an INSERT or UPDATE.
func (s *Stmt) Exec(args []driver.Value) (driver.Result, error) {
	// Binds all arguments.
	if err := s.Bind(args); err != nil {
		return nil, err
	}
	// Executes query.
	switch s.p.(type) {
	case parser.CreateViewStmt:
		return NewCreateViewStmt(s).Exec()
	}
	return s.si.Exec(args)
}

// Query sends request to Google Adwords API and retrieves its content.
func (s *Stmt) Query(args []driver.Value) (driver.Rows, error) {
	// Binds all arguments.
	if err := s.Bind(args); err != nil {
		return nil, err
	}
	// Executes query.
	switch s.p.(type) {
	case parser.DescribeStmt:
		return NewDescribeStmt(s).Query()
	case parser.ShowStmt:
		return NewShowStmt(s).Query()
	case parser.SelectStmt:
		return NewSelectStmt(s).Query()
	}
	return nil, errors.New("QueryError.UNSUPPORTED_QUERY")
}

// Rows is an iterator over an executed query's results.
type Rows struct {
	data *awql.Rows
	cols []string
}

// Columns returns the names of the columns.
func (r *Rows) Columns() []string {
	return r.cols
}

// Close closes the rows iterator.
func (r *Rows) Close() error {
	return r.data.Close()
}

// Next is called to populate the next row of data into the provided slice.
func (r *Rows) Next(dest []driver.Value) error {
	return r.data.Next(dest)
}

// Result is the result of a query execution.
type Result struct {
	err error
}

// LastInsertId returns the database's auto-generated ID
// after, for example, an INSERT into a table with primary key.
func (r *Result) LastInsertId() (int64, error) {
	return 0, driver.ErrSkip
}

// RowsAffected returns the number of rows affected by the query.
func (r *Result) RowsAffected() (int64, error) {
	return 0, r.err
}
