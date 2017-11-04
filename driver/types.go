package driver

import (
	"database/sql"
	"database/sql/driver"
	"strconv"
	"time"
)

// Generic patterns in Google reports.
const (
	// Google can prefix a value by `auto:` or just return `auto` to symbolize an automatic strategy.
	auto      = "auto"
	autoValue = auto + ": "

	// Google uses `Excluded` to tag null value by context.
	excluded = "Excluded"

	// Google uses ` --` instead of an empty string to symbolize the fact that the field was never set.
	doubleDash = " --"

	// Google sometimes uses special value like `> 90%` or `< 10%`.
	almost10 = "< 10"
	almost90 = "> 90"
)

// PercentNullFloat64 represents a float64 that may be a percentage.
type PercentNullFloat64 struct {
	NullFloat64     sql.NullFloat64
	Almost, Percent bool
}

// Value implements the driver Valuer interface.
func (n PercentNullFloat64) Value() (driver.Value, error) {
	if !n.NullFloat64.Valid {
		return doubleDash, nil
	}
	var v string
	if n.Almost {
		if n.NullFloat64.Float64 > 90 {
			v = almost90
		} else {
			v = almost10
		}
	} else {
		v = strconv.FormatFloat(n.NullFloat64.Float64, 'f', 2, 64)
	}
	if n.Percent {
		return v + "%", nil
	}
	return v, nil
}

// AutoExcludedNullInt64 represents a int64 that may be null or defined as auto valuer.
type AutoExcludedNullInt64 struct {
	NullInt64 sql.NullInt64
	Auto,
	Excluded bool
}

// Value implements the driver Valuer interface.
func (n AutoExcludedNullInt64) Value() (driver.Value, error) {
	var v string
	if n.Auto {
		if !n.NullInt64.Valid {
			return auto, nil
		}
		v = autoValue
	}
	if n.Excluded {
		return excluded, nil
	}
	if !n.NullInt64.Valid {
		return doubleDash, nil
	}
	v += strconv.FormatInt(n.NullInt64.Int64, 10)

	return v, nil
}

// AggregatedNullFloat64 represents a float64 that may be null and rounded by using its precision.
type AggregatedNullFloat64 struct {
	NullFloat64 sql.NullFloat64
	Precision   int
	Layout      string
}

// Value implements the driver Valuer interface.
func (n AggregatedNullFloat64) Value() (driver.Value, error) {
	if !n.NullFloat64.Valid {
		return doubleDash, nil
	}
	if n.Layout == "" {
		return strconv.FormatFloat(n.NullFloat64.Float64, 'f', n.Precision, 64), nil
	}
	// A layout is provided, it's a date.
	return time.Unix(int64(n.NullFloat64.Float64), 0).Format(n.Layout), nil
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
