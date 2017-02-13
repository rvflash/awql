package awqldb

import (
	"fmt"
	"strings"
)

// DatabaseError represents an database error.
type DatabaseError struct {
	s string
	a interface{}
}

// NewDatabaseError returns an error about the database.
func NewDatabaseError(text string) error {
	return &DatabaseError{s: formatError(text)}
}

// NewDatabaseError returns an error about the database.
func NewXDatabaseError(text string, arg interface{}) error {
	return &DatabaseError{s: formatError(text), a: arg}
}

// Error returns the error message.
func (e *DatabaseError) Error() string {
	if e.a != nil {
		return fmt.Sprintf("ParserError.%v (%v)", e.s, e.a)
	}
	return "DatabaseError." + e.s
}

// formatError returns a string in upper case with underscore instead of space.
// As the Adwords API outputs its errors.
func formatError(s string) string {
	return strings.Replace(strings.ToUpper(strings.TrimSpace(s)), " ", "_", -1)
}
