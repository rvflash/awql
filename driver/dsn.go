package driver

import (
	"strconv"

	awql "github.com/rvflash/awql-driver"
)

// Dsn represents a data source name.
type Dsn struct {
	AdwordsId, ApiVersion,
	DeveloperToken, DatabaseDir,
	AccessToken, ClientId,
	ClientSecret, RefreshToken string
	SupportsZeroImpressions,
	WithCache bool
}

// NewDsn returns a new instance of Dsn.
func NewDsn(id, db string) *Dsn {
	return &Dsn{AdwordsId: id, DatabaseDir: db}
}

// String outputs the data source name as string.
// /data/base/dir|123-456-7890:v201607:true:false|dEve1op3er7okeN|1234567890-c1i3n7iD.com|c1ien753cr37|1/R3Fr35h-70k3n
func (d *Dsn) String() (n string) {
	if d.AdwordsId == "" || d.DatabaseDir == "" {
		return
	}
	n = d.DatabaseDir + awql.DsnSep + d.AdwordsId

	n += awql.DsnOptSep + d.ApiVersion
	n += awql.DsnOptSep + strconv.FormatBool(d.SupportsZeroImpressions)
	n += awql.DsnOptSep + strconv.FormatBool(d.WithCache)

	if d.DeveloperToken != "" {
		n += awql.DsnSep + d.DeveloperToken
	}
	if d.AccessToken != "" {
		n += awql.DsnSep + d.AccessToken
	}
	if d.ClientId != "" {
		n += awql.DsnSep + d.ClientId
	}
	if d.ClientSecret != "" {
		n += awql.DsnSep + d.ClientSecret
	}
	if d.RefreshToken != "" {
		n += awql.DsnSep + d.RefreshToken
	}

	return
}
