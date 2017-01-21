package awql

import "strconv"

// Dsn represents a data source name.
type Dsn struct {
	AdwordsId, ApiVersion,
	DeveloperToken, AccessToken,
	ClientId, ClientSecret,
	RefreshToken string
	SupportsZeroImpressions bool
}

// NewDsn returns a new instance of Dsn.
func NewDsn(id string) *Dsn {
	return &Dsn{AdwordsId: id}
}

// String outputs the data source name as string.
// Output:
// 123-456-7890:v201607:true|dEve1op3er7okeN|1234567890-c1i3n7iD.com|c1ien753cr37|1/R3Fr35h-70k3n
func (d *Dsn) String() (n string) {
	if d.AdwordsId == "" {
		return
	}
	n = d.AdwordsId
	n += DsnOptSep + d.ApiVersion
	n += DsnOptSep + strconv.FormatBool(d.SupportsZeroImpressions)

	if d.DeveloperToken != "" {
		n += DsnSep + d.DeveloperToken
	}
	if d.AccessToken != "" {
		n += DsnSep + d.AccessToken
	}
	if d.ClientId != "" {
		n += DsnSep + d.ClientId
	}
	if d.ClientSecret != "" {
		n += DsnSep + d.ClientSecret
	}
	if d.RefreshToken != "" {
		n += DsnSep + d.RefreshToken
	}
	return
}
