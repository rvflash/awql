package awql

import (
	"database/sql"
	"database/sql/driver"
	"net/http"
	"strconv"
	"strings"
	"time"
)

const (
	ApiVersion = "v201609"
	DsnSep     = "|"
	DsnOptSep  = ":"
)

// Driver implements all methods to pretend as a sql database driver.
type Driver struct{}

// init adds  awql as sql database driver
// @see https://github.com/golang/go/wiki/SQLDrivers
// @implements https://golang.org/src/database/sql/driver/driver.go
func init() {
	sql.Register("awql", &Driver{})
}

// Open returns a new connection to the database.
// @see AdwordsId[:ApiVersion]|DeveloperToken[|AccessToken]
// @see AdwordsId[:ApiVersion]|DeveloperToken[|ClientId][|ClientSecret][|RefreshToken]
// @see AdwordsId[:ApiVersion:SupportsZeroImpressions]|DeveloperToken[|ClientId][|ClientSecret][|RefreshToken]
// @example 123-456-7890:v201607:true|dEve1op3er7okeN|1234567890-c1i3n7iD.com|c1ien753cr37|1/R3Fr35h-70k3n
func (d *Driver) Open(dsn string) (driver.Conn, error) {
	conn, err := unmarshal(dsn)
	if err != nil {
		return nil, err
	}
	if conn.oAuth != nil {
		// An authentication is required to connect to Adwords API.
		conn.authenticate()
	}
	return conn, nil
}

// parseDsn returns an pointer to an Conn by parsing a DSN string.
// It throws an error on fails to parse it.
func unmarshal(dsn string) (*Conn, error) {
	var adwordsId = func(s string) string {
		return strings.Split(s, DsnOptSep)[0]
	}
	var apiVersion = func(s string) string {
		d := strings.Split(s, DsnOptSep)
		if len(d) > 1 {
			return d[1]
		}
		return ""
	}
	var useZeroImpressions = func(s string) (ok bool) {
		d := strings.Split(s, DsnOptSep)
		if len(d) > 2 {
			ok, _ = strconv.ParseBool(d[2])
		}
		return
	}
	conn := &Conn{}
	if dsn == "" {
		return conn, driver.ErrBadConn
	}

	parts := strings.Split(dsn, DsnSep)
	size := len(parts)
	if size < 2 || size > 5 || size == 4 {
		return conn, driver.ErrBadConn
	}
	// @example 123-456-7890|dEve1op3er7okeN
	conn.client = http.DefaultClient
	conn.adwordsID = adwordsId(parts[0])
	if conn.adwordsID == "" {
		return conn, ErrAdwordsID
	}
	conn.developerToken = parts[1]
	if conn.developerToken == "" {
		return conn, ErrDevToken
	}
	conn.opts = NewOpts(apiVersion(parts[0]), useZeroImpressions(parts[0]))

	var err error
	switch size {
	case 3:
		// @example 123-456-7890|dEve1op3er7okeN|ya29.AcC3s57okeN
		conn.oAuth, err = NewAuthByToken(parts[2])
	case 5:
		// @example 123-456-7890|dEve1op3er7okeN|1234567890-c1i3n7iD.apps.googleusercontent.com|c1ien753cr37|1/R3Fr35h-70k3n
		conn.oAuth, err = NewAuthByClient(parts[2], parts[3], parts[4])
	}
	return conn, err
}

// AuthToken contains the properties of the Google access token.
type AuthToken struct {
	AccessToken,
	TokenType string
	Expiry time.Time
}

// AuthKey represents the keys used to retrieve an access token.
type AuthKey struct {
	ClientId,
	ClientSecret,
	RefreshToken string
}

// Auth contains all information to deal with an access token via OAuth Google.
// It implements Stringer interface
type Auth struct {
	AuthKey
	AuthToken
}

// IsSet returns true if the auth struct has keys to refresh access token.
func (a *Auth) IsSet() bool {
	return a.ClientId != ""
}

// String returns a representation of the access token.
func (a *Auth) String() string {
	return a.TokenType + " " + a.AccessToken
}

// Valid returns in success is the access token is not expired.
// The delta in seconds is used to avoid delay expiration of the token.
func (a *Auth) Valid() bool {
	if a.Expiry.IsZero() {
		return false
	}
	return !a.Expiry.Add(-tokenExpiryDelta).Before(time.Now())
}

// NewAuthByToken returns an Auth struct only based on the access token.
func NewAuthByToken(tk string) (*Auth, error) {
	if tk == "" {
		return &Auth{}, ErrBadToken
	}
	return &Auth{
		AuthToken: AuthToken{
			AccessToken: tk,
			TokenType:   "Bearer",
			Expiry:      time.Now().Add(tokenExpiryDuration),
		},
	}, nil
}

// NewAuthByClient returns an Auth struct only based on the client keys.
func NewAuthByClient(clientId, clientSecret, refreshToken string) (*Auth, error) {
	if clientId == "" || clientSecret == "" || refreshToken == "" {
		return &Auth{}, ErrBadToken
	}
	return &Auth{
		AuthKey: AuthKey{
			ClientId:     clientId,
			ClientSecret: clientSecret,
			RefreshToken: refreshToken,
		},
	}, nil
}

// Opts lists the available Adwords API properties.
type Opts struct {
	Version string
	SkipReportHeader,
	SkipColumnHeader,
	SkipReportSummary,
	IncludeZeroImpressions,
	UseRawEnumValues bool
}

// NewOpts returns a Opts with default options.
func NewOpts(version string, zero bool) *Opts {
	if version == "" {
		version = ApiVersion
	}
	return &Opts{
		IncludeZeroImpressions: zero,
		SkipReportHeader:       true,
		SkipReportSummary:      true,
		Version:                version,
	}
}
