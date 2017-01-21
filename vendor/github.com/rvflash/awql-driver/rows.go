package awql

import (
	"database/sql/driver"
	"io"
)

// Rows is an iterator over an executed query's results.
type Rows struct {
	Position, Size uint
	Data           [][]string
}

// Close usual closes the rows iterator.
func (r *Rows) Close() error {
	return nil
}

// Columns returns the names of the columns.
func (r *Rows) Columns() []string {
	if r.Size == 0 {
		return nil
	}
	return r.Data[0]
}

// Next is called to populate the next row of data into the provided slice.
func (r *Rows) Next(dest []driver.Value) error {
	if r.Position == r.Size {
		return io.EOF
	}
	// Converts slice of string into slice of interface, expected value of sql driver.
	for k, v := range r.Data[r.Position] {
		dest[k] = driver.Value(v)
	}
	r.Position++

	return nil
}
