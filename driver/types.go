package driver

import (
	"database/sql"
	"database/sql/driver"
	"strconv"
	"time"
)

// Generic patterns in Google reports.
const (
	// Google can prefix a value by auto: or just return auto to symbolize an automatic strategy.
	auto      = "auto"
	autoValue = auto + ": "

	// Google uses ' --' instead of an empty string to symbolize the fact that the field was never set
	doubleDash = " --"
)

// PercentFloat64 represents a float64 that may be a percentage.
type PercentFloat64 struct {
	Float64 float64
	Percent bool
}

// Value implements the driver Valuer interface.
func (n PercentFloat64) Value() (driver.Value, error) {
	v := strconv.FormatFloat(n.Float64, 'f', 2, 64)
	if n.Percent {
		return v + "%", nil
	}
	return v, nil
}

// AutoNullInt64 represents a int64 that may be null or defined as auto valuer.
type AutoNullInt64 struct {
	NullInt64 sql.NullInt64
	Auto      bool
}

// Value implements the driver Valuer interface.
func (n AutoNullInt64) Value() (driver.Value, error) {
	var v string
	if n.Auto {
		if !n.NullInt64.Valid {
			return auto, nil
		}
		v = autoValue
	}
	if !n.NullInt64.Valid {
		return doubleDash, nil
	}
	v += strconv.FormatInt(n.NullInt64.Int64, 10)

	return v, nil
}

// Float64 represents a float64 that may be rounded by using its precision.
type Float64 struct {
	Float64   float64
	Precision int
}

// Value implements the driver Valuer interface.
func (n Float64) Value() (driver.Value, error) {
	return strconv.FormatFloat(n.Float64, 'f', n.Precision, 64), nil
}

// NullString represents a string that may be null.
type NullString struct {
	String string
	Valid  bool // Valid is true if String is not NULL
}

// Value implements the driver Valuer interface.
func (n NullString) Value() (driver.Value, error) {
	if !n.Valid {
		return doubleDash, nil
	}
	return n.String, nil
}

// Time represents a Time that may be not set.
type Time struct {
	Time   time.Time
	Layout string
}

// Value implements the driver Valuer interface.
func (n Time) Value() (driver.Value, error) {
	if n.Time.IsZero() {
		return doubleDash, nil
	}
	return n.Time.Format(n.Layout), nil
}
