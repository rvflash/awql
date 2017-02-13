package awql

import (
	"database/sql/driver"
	"io"
	"net/http"
	"testing"
)

var connTests = []struct {
	conn  *Conn
	query string
	err   error
}{
	{&Conn{client: http.DefaultClient}, "", io.EOF},
	{&Conn{client: http.DefaultClient}, "SELECT AccountDescriptiveName FROM ACCOUNT_PERFORMANCE_REPORT;", nil},
}

// TestAwqlConn_Close tests the method named Close on Conn strict.
func TestAwqlConn_Close(t *testing.T) {
	for _, ct := range connTests {
		if err := ct.conn.Close(); err != nil {
			t.Errorf("Expected no error when we close the connection, received %v", err)
		} else if ct.conn.client != nil {
			t.Errorf("Expected nil client when we close the connection, received %v", ct.conn.client)
		}
	}
}

// TestAwqlConn_Begin tests the method named Begin on Conn strict.
func TestAwqlConn_Begin(t *testing.T) {
	for _, ct := range connTests {
		if _, err := ct.conn.Begin(); err != driver.ErrSkip {
			t.Errorf("Expected driver.ErrSkip when we begin a transaction, received %v", err)
		}
	}
}

// TestAwqlConn_Prepare tests the method named Prepare on Conn strict.
func TestAwqlConn_Prepare(t *testing.T) {
	for _, ct := range connTests {
		if _, err := ct.conn.Prepare(ct.query); err != ct.err {
			t.Errorf("Expected driver.ErrSkip when we begin a transaction, received %v", err)
		}
	}
}
