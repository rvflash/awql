package driver

import "strings"

// Error messages.
var (
	ErrMultipleQueries = NewQueryError("unsupported multi queries")
	ErrQuery           = NewQueryError("unsupported query")
)

// CacheError represents a cache error.
type CacheError struct {
	s string
}

// NewCacheError returns an error of type Cache with the given text.
func NewCacheError(text string) error {
	return &CacheError{formatError(text)}
}

// Error outputs a query error message.
func (e *CacheError) Error() string {
	return "CacheError." + e.s
}

// QueryError represents a query error.
type QueryError struct {
	s string
}

// NewQueryError returns an error of type Query with the given text.
func NewQueryError(text string) error {
	return &QueryError{formatError(text)}
}

// Error outputs a query error message.
func (e *QueryError) Error() string {
	return "QueryError." + e.s
}

// formatError returns a string in upper case with underscore instead of space.
// As the Adwords API outputs its errors.
func formatError(s string) string {
	return strings.Replace(strings.ToUpper(strings.TrimSpace(s)), " ", "_", -1)
}
