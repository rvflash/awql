package driver

import (
	parser "github.com/rvflash/awql-parser"
)

func (r *Rows) Aggregate(columns []parser.DynamicField, groups []parser.FieldPosition) {

}

// Limit bounds the slice of rows.
func (r *Rows) Limit(offset, rowCount int) {
	max := int(r.data.Size)
	switch {
	case offset > max || offset < 0:
		// Start offset exceeds the bounds, returns nothing.
		r.data.Data = r.data.Data[:]
	case offset+rowCount > max:
		// End of rows reached.
		rowCount = max
		fallthrough
	default:
		r.data.Data = r.data.Data[offset:rowCount]
	}
}

// Sort sorts the rows by columns values.
func (r *Rows) Sort(columns []parser.Orderer) {
	if len(columns) == 0 {
		return
	}
}
