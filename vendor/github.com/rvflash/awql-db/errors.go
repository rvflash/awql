package awql_db

import "strings"

// DatabaseError represents an database error.
type DatabaseError struct {
	s string
}

// NewDatabaseError returns an error about the database.
func NewDatabaseError(text string) error {
	return &DatabaseError{s: formatError(text)}
}

// Error returns the error message.
func (e *DatabaseError) Error() string {
	return "DatabaseError." + e.s
}

// formatError returns a string in upper case with underscore instead of space.
// As the Adwords API outputs its errors.
func formatError(s string) string {
	return strings.Replace(strings.ToUpper(strings.TrimSpace(s)), " ", "_", -1)
}
