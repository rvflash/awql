package awql_test

import (
	"database/sql/driver"
	"reflect"
	"testing"

	awql "github.com/rvflash/awql-driver"
)

var rowsTests = []struct {
	rows    *awql.Rows
	columns []string
}{
	{&awql.Rows{}, nil},
	{&awql.Rows{
		Size: 2,
		Data: [][]string{{"id", "name"}, {"19", "rv"}}},
		[]string{"id", "name"},
	},
}

// TestAwqlRows_Close tests the method Close on Rows struct.
func TestAwqlRows_Close(t *testing.T) {
	for _, rt := range rowsTests {
		if err := rt.rows.Close(); err != nil {
			t.Errorf("Expected no error when we close the rows, received %v", err)
		}
	}
}

// TestAwqlRows_Columns tests the method Columns on Rows struct.
func TestAwqlRows_Columns(t *testing.T) {
	for _, rt := range rowsTests {
		if c := rt.rows.Columns(); !reflect.DeepEqual(c, rt.columns) {
			t.Errorf("Expected %v as colums, received %v", rt.columns, c)
		}
	}
}

// TestAwqlRows_Next tests the method Next on Rows struct.
func TestAwqlRows_Next(t *testing.T) {
	for _, rs := range rowsTests {
		size := len(rs.rows.Columns())
		dest := make([]driver.Value, size)
		if err := rs.rows.Next(dest); err != nil {
			if size > 0 {
				t.Errorf("Expected no error when we get the first row, received %v", err)
			}
		} else if dest[0] != rs.columns[0] || dest[1] != rs.columns[1] {
			t.Errorf("Expected %v as colums, received %v, with err %v", rs.columns, dest, err)
		}
	}
}
