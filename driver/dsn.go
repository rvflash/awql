package driver

import (
	"strconv"

	awql "github.com/rvflash/awql-driver"
)

// Dsn represents a data source name.
type Dsn struct {
	DatabaseDir,
	Src string
	WithCache bool
}

// NewDsn returns a new instance of Dsn.
func NewDsn(db, src string, cached bool) *Dsn {
	return &Dsn{
		DatabaseDir: db,
		Src:         src,
		WithCache:   cached,
	}
}

// String outputs the data source name as string.
// /data/base/dir:false|123-456-7890:v201607|dEve1op3er7okeN|1234567890-c1i3n7iD.com|c1ien753cr37|1/R3Fr35h-70k3n
func (d *Dsn) String() (s string) {
	s = d.DatabaseDir
	s += awql.DsnOptSep + strconv.FormatBool(d.WithCache)
	s += awql.DsnSep + d.Src

	return
}
