package awql

import (
	"database/sql/driver"
	"testing"
	"time"
)

// TestAwqlDriver_Open tests the method named Open on Driver struct.
func TestAwqlDriver_Open(t *testing.T) {
	var driverTests = []struct {
		dsn  string
		conn driver.Conn
		err  error
	}{
		// Errors.
		// 0
		{"", nil, driver.ErrBadConn},
		{"123-456-7890", nil, driver.ErrBadConn},
		{"123-456-7890|dEve1op3er7okeN|ya29.AcC3s57okeN|Oops", nil, driver.ErrBadConn},
		{"123-456-7890:v201607||ya29.AcC3s57okeN", nil, ErrDevToken},
		{"|dEve1op3er7okeN|ya29.AcC3s57okeN", nil, ErrAdwordsID},
		// 5
		{"123-456-7890:v201607|dEve1op3er7okeN|", nil, ErrBadToken},
		{"123-456-7890|dEve1op3er7okeN||c1ien753cr37|1/R3Fr35h-70k3n", nil, ErrBadToken},

		// Ok.
		{
			"123-456-7890|dEve1op3er7okeN",
			&Conn{adwordsID: "123-456-7890", developerToken: "dEve1op3er7okeN"},
			nil,
		},
		{
			"123-456-7890|dEve1op3er7okeN|ya29.AcC3s57okeN",
			&Conn{
				adwordsID: "123-456-7890", developerToken: "dEve1op3er7okeN",
				oAuth: &Auth{AuthKey{}, AuthToken{AccessToken: "ya29.AcC3s57okeN"}},
			},
			nil,
		},
		{
			"123-456-7890:v201607|dEve1op3er7okeN|ya29.AcC3s57okeN",
			&Conn{
				adwordsID: "123-456-7890", developerToken: "dEve1op3er7okeN",
				oAuth: &Auth{AuthKey{}, AuthToken{AccessToken: "ya29.AcC3s57okeN"}},
				opts:  &Opts{Version: "v201607"},
			},
			nil,
		},
		// 10
		{
			"123-456-7890|dEve1op3er7okeN|1234567890-c1i3n7iD.apps.googleusercontent.com|c1ien753cr37|1/R3Fr35h-70k3n",
			&Conn{
				adwordsID: "123-456-7890", developerToken: "dEve1op3er7okeN",
				oAuth: &Auth{
					AuthKey{
						ClientID:     "1234567890-c1i3n7iD.apps.googleusercontent.com",
						ClientSecret: "c1ien753cr37", RefreshToken: "1/R3Fr35h-70k3n",
					},
					AuthToken{
						AccessToken: "ya29.AcC3s57okeN",
						TokenType:   "Bearer",
						Expiry:      time.Now().Add(tokenExpiryDuration),
					},
				},
			},
			nil,
		},
	}

	d := &Driver{}
	for _, dt := range driverTests {
		if _, err := d.Open(dt.dsn); err == nil {
			if dt.err != nil {
				t.Errorf("Expected error %v, received no error with %v", dt.err, dt.dsn)
			}
		} else if dt.err == nil {
			t.Errorf("Expected no error with %s, received %v", dt.dsn, err)
		} else if err.Error() != dt.err.Error() {
			t.Errorf("Expected error %v with %s, received %v", dt.err, dt.dsn, err)
		}
	}
}

var authTests = []struct {
	token          *Auth  // in
	str            string // out
	isValid, isSet bool
}{
	{
		&Auth{
			AuthKey{},
			AuthToken{TokenType: "Bearer", AccessToken: "ya29.AcC3s57okeN"},
		},
		"Bearer ya29.AcC3s57okeN", false, false,
	},
	{
		&Auth{
			AuthKey{},
			AuthToken{TokenType: "Bearer", AccessToken: "ya29.A", Expiry: time.Now()},
		},
		"Bearer ya29.A", false, false,
	},
	{
		&Auth{
			AuthKey{},
			AuthToken{TokenType: "Bearer", AccessToken: "ya29.B", Expiry: time.Now().Add(tokenExpiryDuration)},
		},
		"Bearer ya29.B", true, false,
	},
	{
		&Auth{
			AuthKey{
				ClientID:     "1234567890-c1i3n7iD.apps.googleusercontent.com",
				ClientSecret: "c1ien753cr37", RefreshToken: "1/R3Fr35h-70k3n",
			},
			AuthToken{TokenType: "Bearer", AccessToken: "ya29.AcC3s57okeN", Expiry: time.Now().Add(tokenExpiryDuration)},
		},
		"Bearer ya29.AcC3s57okeN", true, true,
	},
}

// TestAwqlAuth_Valid test the Auth method named Valid.
func TestAwqlAuth_IsSet(t *testing.T) {
	for _, a := range authTests {
		if a.token.IsSet() != a.isSet {
			t.Errorf("Expected %v for the check of setting of the access token %v, received %v", a.isSet, a.token, a.token.IsSet())
		}
	}
}

// TestAwqlAuth_String test the Auth method named String.
func TestAwqlAuth_String(t *testing.T) {
	for _, a := range authTests {
		if a.token.String() != a.str {
			t.Errorf("Expected %v as access token, received %v", a.str, a.token.String())
		}
	}
}

// TestAwqlAuth_Valid test the Auth method named Valid.
func TestAwqlAuth_Valid(t *testing.T) {
	for _, a := range authTests {
		if a.token.Valid() != a.isValid {
			t.Errorf("Expected %v as access token validity for %v, received %v", a.isValid, a.token, a.token.Valid())
		}
	}
}
