package driver

import (
	"fmt"
	"strings"
)

// Error messages.
var (
	ErrMultipleQueries = NewError("unsupported multi queries")
	ErrQuery           = NewError("unsupported query")
	ErrOutRange          = NewError("out of scope")
)

// Error represents a internal error.
type Error struct {
	s string
	a interface{}
}

// NewError returns an error of type Driver with the given text.
func NewError(text string) error {
	return &Error{s: formatError(text)}
}

// NewXError returns an error of type Driver with the given text.
func NewXError(text string, arg interface{}) error {
	return &Error{s: formatError(text), a: arg}
}

// Error outputs a query error message.
func (e *Error) Error() string {
	if e.a != nil {
		return fmt.Sprintf("DriverError.%v (%v)", e.s, e.a)
	}
	return "DriverError." + e.s
}

// formatError returns a string in upper case with underscore instead of space.
// As the Adwords API outputs its errors.
func formatError(s string) string {
	return strings.Replace(strings.ToUpper(strings.TrimSpace(s)), " ", "_", -1)
}
