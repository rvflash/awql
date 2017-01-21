package awql

import (
	"database/sql/driver"
	"encoding/json"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
)

const (
	tokenUrl            = "https://accounts.google.com/o/oauth2/token"
	tokenTimeout        = time.Duration(4 * time.Second)
	tokenExpiryDelta    = 10 * time.Second
	tokenExpiryDuration = 60 * time.Minute
)

// Conn represents a connection to a database and implements driver.Conn.
type Conn struct {
	client         *http.Client
	adwordsID      string
	developerToken string
	oAuth          *Auth
	opts           *Opts
}

// Close marks this connection as no longer in use.
func (c *Conn) Close() error {
	// Resets client
	c.client = nil
	return nil
}

// Begin is dedicated to start a transaction and awql does not support it.
func (c *Conn) Begin() (driver.Tx, error) {
	return nil, driver.ErrSkip
}

// Prepare returns a prepared statement, bound to this connection.
func (c *Conn) Prepare(q string) (driver.Stmt, error) {
	if q == "" {
		// No query to prepare.
		return nil, io.EOF
	}
	return &Stmt{Db: c, SrcQuery: q}, nil
}

// Auth returns an error if it can not download or parse the Google access token.
func (c *Conn) authenticate() error {
	if c.oAuth == nil || c.oAuth.Valid() {
		// Authentication is not required or already validated.
		return nil
	}
	if !c.oAuth.IsSet() {
		// No client information to refresh the token.
		return ErrBadToken
	}
	d, err := c.downloadToken()
	if err != nil {
		return err
	}
	return c.retrieveToken(d)
}

// downloadToken calls Google Auth Api to retrieve an access token.
// @example Google Token
// {
//     "access_token": "ya29.ExaMple",
//     "token_type": "Bearer",
//     "expires_in": 60
// }
func (c *Conn) downloadToken() (io.ReadCloser, error) {
	rq, err := http.NewRequest(
		"POST", tokenUrl,
		strings.NewReader(url.Values{
			"client_id":     {c.oAuth.ClientId},
			"client_secret": {c.oAuth.ClientSecret},
			"refresh_token": {c.oAuth.RefreshToken},
			"grant_type":    {"refresh_token"},
		}.Encode()),
	)
	if err != nil {
		return nil, err
	}
	c.client.Timeout = tokenTimeout
	rq.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	// Retrieves an access token
	resp, err := c.client.Do(rq)
	if err != nil {
		return nil, err
	}
	// Manages response in error
	if resp.StatusCode != http.StatusOK {
		switch resp.StatusCode {
		case 0:
			return nil, ErrNoNetwork
		case http.StatusBadRequest:
			return nil, ErrBadToken
		default:
			return nil, ErrBadNetwork
		}
	}
	return resp.Body, nil
}

// retrieveToken parses the JSON response in order to map it to a AuthToken.
// An error occurs if the JSON is invalid.
func (c *Conn) retrieveToken(d io.ReadCloser) error {
	var tk struct {
		AccessToken  string `json:"access_token"`
		ExpiresInSec int    `json:"expires_in"`
		TokenType    string `json:"token_type"`
	}
	defer d.Close()

	err := json.NewDecoder(d).Decode(&tk)
	if err != nil {
		// Unable to parse the JSON response.
		return ErrBadToken
	}
	if tk.ExpiresInSec == 0 || tk.AccessToken == "" {
		// Invalid format of the token.
		return ErrBadToken
	}
	c.oAuth.AccessToken = tk.AccessToken
	c.oAuth.TokenType = tk.TokenType
	c.oAuth.Expiry = time.Now().Add(time.Duration(tk.ExpiresInSec) * time.Second)

	return nil
}
