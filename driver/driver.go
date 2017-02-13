package driver

import (
	"database/sql"
	"database/sql/driver"
	"io"
	"strconv"
	"strings"

	db "github.com/rvflash/awql-db"
	awql "github.com/rvflash/awql-driver"
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
// @see DatabaseDir:WithCache|AdwordsId[:ApiVersion:SupportsZeroImpressions]|DeveloperToken[|ClientId][|ClientSecret][|RefreshToken]
// @example /data/base/dir:false|123-456-7890:v201607:true|dEve1op3er7okeN|1234567890-c1i3n7iD.com|c1ien753cr37|1/R3Fr35h-70k3n
func (d *AdvancedDriver) Open(dsn string) (driver.Conn, error) {
	// Gets the API version to use.
	var apiVersion = func(s string) string {
		d := strings.Split(strings.Split(s, awql.DsnSep)[0], awql.DsnOptSep)
		if len(d) > 1 {
			return d[1]
		}
		return awql.APIVersion
	}
	// Extracts database directory and caching option.
	var dbCache = func(s string) (dir string, caching bool) {
		d := strings.Split(s, awql.DsnOptSep)
		if len(d) > 1 {
			caching, _ = strconv.ParseBool(d[1])
		}
		dir = d[0]

		return
	}
	// Validates the data source name.
	src := strings.SplitN(dsn, awql.DsnSep, 2)
	if len(src) != 2 {
		return nil, driver.ErrBadConn
	}
	dbd, wc := dbCache(src[0])

	// Wraps the Awql driver.
	dd := &awql.Driver{}
	conn, err := dd.Open(src[1])
	if err != nil {
		return nil, err
	}

	// Loads all information about the database.
	awqlDb, err := db.Open(apiVersion(src[1]) + "|" + dbd)
	if err != nil {
		return nil, err
	}
	return &Conn{cn: conn.(*awql.Conn), c: wc, db: awqlDb}, nil
}

// Conn represents a connection to a database and implements driver.Conn.
type Conn struct {
	cn *awql.Conn
	db *db.Database
	c  bool
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
