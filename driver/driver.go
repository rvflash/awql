package driver

import (
	"database/sql"
	"database/sql/driver"
	"io"
	"strconv"
	"strings"
	"time"

	db "github.com/rvflash/awql-db"
	awql "github.com/rvflash/awql-driver"
	cache "github.com/rvflash/csv-cache"
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
// @see DatabaseDir:CacheDir:WithCache|AdwordsId[:ApiVersion:SupportsZeroImpressions]|DeveloperToken[|ClientId][|ClientSecret][|RefreshToken]
// @example /data/base/dir:/cache/dir:false|123-456-7890:v201607:true|dEve1op3er7okeN|1234567890-c1i3n7iD.com|c1ien753cr37|1/R3Fr35h-70k3n
func (d *AdvancedDriver) Open(dsn string) (driver.Conn, error) {
	// Extracts database directory and caching option.
	var dbCache = func(s string) (db, cache string, caching bool) {
		d := strings.Split(s, awql.DsnOptSep)
		switch len(d) {
		case 3:
			caching, _ = strconv.ParseBool(d[2])
			fallthrough
		case 2:
			cache = d[1]
			fallthrough
		case 1:
			db = d[0]
		}
		return
	}
	// Validates the data source name.
	src := strings.SplitN(dsn, awql.DsnSep, 2)
	if len(src) != 2 {
		return nil, driver.ErrBadConn
	}
	dbd, cached, wc := dbCache(src[0])

	// Initializes the cache to save result sets inside.
	ttl := 10 * time.Minute
	if wc {
		ttl = 24 * time.Hour
	}
	c := cache.New(cached, ttl)
	if wc {
		// Cache enabled, only removes outdated files.
		c.FlushAll()
	} else {
		// Cache disabled, removes all existing file caches.
		c.DeleteAll()
	}

	// Wraps the Awql driver.
	dd := &awql.Driver{}
	conn, err := dd.Open(src[1])
	if err != nil {
		return nil, err
	}

	// Gets the API version to use.
	var idVersion = func(s string) (string, string) {
		d := strings.Split(strings.Split(s, awql.DsnSep)[0], awql.DsnOptSep)
		if len(d) > 1 {
			return d[0], d[1]
		}
		return d[0], awql.APIVersion
	}
	id, v := idVersion(src[1])

	// Loads all information about the database.
	awqlDb, err := db.Open(v + "|" + dbd)
	if err != nil {
		return nil, err
	}
	return &Conn{cn: conn.(*awql.Conn), fc: c, db: awqlDb, id: id}, nil
}

// Conn represents a connection to a database and implements driver.Conn.
type Conn struct {
	cn *awql.Conn
	db *db.Database
	fc *cache.Cache
	id string
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
	return &Stmt{si: &awql.Stmt{Db: c.cn, SrcQuery: q}, db: c.db, fc: c.fc, id: c.id}, nil
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
