package awql

import "strconv"

// Dsn represents a data source name.
type Dsn struct {
	AdwordsID, APIVersion,
	DeveloperToken, AccessToken,
	ClientID, ClientSecret,
	RefreshToken string
	SkipColumnHeader,
	SupportsZeroImpressions,
	UseRawEnumValues bool
}

// NewDsn returns a new instance of Dsn.
func NewDsn(id string) *Dsn {
	return &Dsn{AdwordsID: id}
}

// String outputs the data source name as string.
// Output:
// 123-456-7890:v201607:true:false:false|dEve1op3er7okeN|1234567890-c1i3n7iD.com|c1ien753cr37|1/R3Fr35h-70k3n
func (d *Dsn) String() (n string) {
	if d.AdwordsID == "" {
		return
	}

	n = d.AdwordsID
	n += DsnOptSep + d.APIVersion
	n += DsnOptSep + strconv.FormatBool(d.SupportsZeroImpressions)
	n += DsnOptSep + strconv.FormatBool(d.SkipColumnHeader)
	n += DsnOptSep + strconv.FormatBool(d.UseRawEnumValues)

	if d.DeveloperToken != "" {
		n += DsnSep + d.DeveloperToken
	}
	if d.AccessToken != "" {
		n += DsnSep + d.AccessToken
	}
	if d.ClientID != "" {
		n += DsnSep + d.ClientID
	}
	if d.ClientSecret != "" {
		n += DsnSep + d.ClientSecret
	}
	if d.RefreshToken != "" {
		n += DsnSep + d.RefreshToken
	}

	return
}
