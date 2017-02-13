package driver

import (
	"database/sql/driver"
	"io"
	"sort"
	"time"
)

// Rows is an iterator over an executed query's results.
// It implements sort and driver.Rows interfaces.
type Rows struct {
	data       [][]driver.Value
	less       []lessFunc
	cols, kind []string
	size, pos  int
}

// Len
func (r *Rows) Len() int {
	return r.size
}

// Less
func (r *Rows) Less(i, j int) bool {
	// Extracts data to compare.
	p, q := r.data[i], r.data[j]
	// Sets the number of iterations to do to compare.
	// Subtraction of 1 because a final comparison is done if all checks said "equal".
	b := len(r.less) - 1
	// Try all but the last comparison.
	var k int
	for k = 0; k < b; k++ {
		less := r.less[k]
		switch {
		case less(p, q):
			// p < q, so we have a decision.
			return true
		case less(q, p):
			// p > q, so we have a decision.
			return false
		}
		// p == q; try the next comparison.
	}
	return r.less[k](p, q)
}

// Swap
func (r *Rows) Swap(i, j int) {
	r.data[i], r.data[j] = r.data[j], r.data[i]
}

// Columns returns the names of the columns.
func (r *Rows) Columns() []string {
	return r.cols
}

// Close closes the rows iterator.
func (r *Rows) Close() error {
	return nil
}

// Next is called to populate the next row of data into the provided slice.
func (r *Rows) Next(dest []driver.Value) error {
	if r.pos == r.size {
		return io.EOF
	}
	// formatTime  returns a textual representation of the time value formatted
	// according to layout.
	var formatTime = func(layout string, t time.Time) string {
		if t.IsZero() {
			return doubleDash
		}
		return t.Format(layout)
	}
	for i := 0; i < len(r.cols); i++ {
		// Overrides the data's kind to display it as expected.
		switch r.kind[i] {
		case "DOUBLE_TO_INT":
			dest[i] = int64(r.data[r.pos][i].(float64))
		case "DATETIME":
			dest[i] = formatTime("2006/01/02 15:04:05", r.data[r.pos][i].(time.Time))
		case "DATE":
			dest[i] = formatTime("2006-01-02", r.data[r.pos][i].(time.Time))
		default:
			dest[i] = r.data[r.pos][i]
		}
	}
	r.pos++

	return nil
}

// Limit bounds the slice of rows.
func (r *Rows) Limit(offset, rowCount int) {
	if offset < 0 {
		offset = 0
	}
	r.pos = offset

	rowCount += offset
	if rowCount >= r.size {
		rowCount = r.size - 1
	}
	r.size = rowCount
}

// Sort
func (r *Rows) Sort() {
	sort.Sort(r)
}
