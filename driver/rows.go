package driver

import (
	"database/sql/driver"
	"io"
	"sort"
)

// Rows is an iterator over an executed query's results.
// It implements sort and driver.Rows interfaces.
type Rows struct {
	data      [][]driver.Value
	less      []lessFunc
	cols      []string
	size, pos int
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
	if r.size == 0 {
		return nil
	}
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
	for i := 0; i < len(r.cols); i++ {
		// todo Improves with Scanner interface.
		switch r.data[r.pos][i].(type) {
		case AutoExcludedNullInt64:
			dest[i], _ = r.data[r.pos][i].(AutoExcludedNullInt64).Value()
		case PercentNullFloat64:
			dest[i], _ = r.data[r.pos][i].(PercentNullFloat64).Value()
		case AggregatedNullFloat64:
			dest[i], _ = r.data[r.pos][i].(AggregatedNullFloat64).Value()
		case Time:
			dest[i], _ = r.data[r.pos][i].(Time).Value()
		case NullString:
			dest[i], _ = r.data[r.pos][i].(NullString).Value()
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
	if rowCount > r.size {
		rowCount = r.size
	}
	r.size = rowCount
}

// Sort sorts rows as expected by less functions.
func (r *Rows) Sort() {
	sort.Sort(r)
}
