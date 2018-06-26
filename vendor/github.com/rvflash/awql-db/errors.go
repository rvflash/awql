package awqldb

import (
	"strings"
)

// DatabaseError represents an database error.
type DatabaseError struct {
	text string
}

// NewDatabaseError returns an error about the database based on the given text.
func NewDatabaseError(text string) error {
	return &DatabaseError{text: formatError(text)}
}

// Error returns the error message.
func (e *DatabaseError) Error() string {
	return "DatabaseError." + e.text
}

// As the Adwords API, formatError returns a string in upper case with underscore instead of space.
func formatError(text string) string {
	return strings.Replace(strings.ToUpper(strings.TrimSpace(text)), " ", "_", -1)
}
