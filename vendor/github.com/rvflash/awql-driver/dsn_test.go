package awql_test

import (
	"testing"

	"github.com/rvflash/awql-driver"
)

// TestNewDsn tests the NewDsn struct
func TestNewDsn(t *testing.T) {
	var dsnTests = []struct {
		d *awql.Dsn
		s string
	}{
		{d: awql.NewDsn(""), s: ""},
		{d: &awql.Dsn{AdwordsID: "123-456-7890"}, s: "123-456-7890::false:false:false"},
		{
			d: &awql.Dsn{AdwordsID: "123-456-7890", APIVersion: "v201609", SupportsZeroImpressions: true},
			s: "123-456-7890:v201609:true:false:false",
		},
		{
			d: &awql.Dsn{AdwordsID: "123-456-7890", APIVersion: "v201609", SkipColumnHeader: true},
			s: "123-456-7890:v201609:false:true:false",
		},
		{
			d: &awql.Dsn{AdwordsID: "123-456-7890", APIVersion: "v201609", UseRawEnumValues: true},
			s: "123-456-7890:v201609:false:false:true",
		},
		{
			d: &awql.Dsn{AdwordsID: "123-456-7890", APIVersion: "v201609", DeveloperToken: "dEve1op3er7okeN"},
			s: "123-456-7890:v201609:false:false:false|dEve1op3er7okeN",
		},
		{
			d: &awql.Dsn{AdwordsID: "123-456-7890", APIVersion: "v201609", AccessToken: "ya29.Acc3ss-7ok3n"},
			s: "123-456-7890:v201609:false:false:false|ya29.Acc3ss-7ok3n",
		},
		{
			d: &awql.Dsn{
				AdwordsID: "123-456-7890", APIVersion: "v201609",
				DeveloperToken: "dEve1op3er7okeN", AccessToken: "ya29.Acc3ss-7ok3n",
			},
			s: "123-456-7890:v201609:false:false:false|dEve1op3er7okeN|ya29.Acc3ss-7ok3n",
		},

		{
			d: &awql.Dsn{
				AdwordsID: "123-456-7890", APIVersion: "v201609",
				DeveloperToken: "dEve1op3er7okeN", ClientID: "1234567890-Aw91.apps.googleusercontent.com",
				ClientSecret: "C13nt5e0r3t", RefreshToken: "1/n-R3fr35h70k3n",
			},
			s: "123-456-7890:v201609:false:false:false|dEve1op3er7okeN|1234567890-Aw91.apps.googleusercontent.com|C13nt5e0r3t|1/n-R3fr35h70k3n",
		},
	}

	for i, dt := range dsnTests {
		if dt.d.String() != dt.s {
			t.Errorf("%d. Expected %v, received %v", i, dt.s, dt.d)
		}
	}
}
