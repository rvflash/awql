package awqlparse

import (
	"fmt"
	"strings"
)

// ParserError represents an error of parse.
type ParserError struct {
	s string
	a interface{}
}

// NewParserError returns an error with the parsing.
func NewParserError(text string) error {
	return &ParserError{s: formatError(text)}
}

// NewXParserError returns an error with the parsing with more information about it.
func NewXParserError(text string, arg interface{}) error {
	return &ParserError{s: formatError(text), a: arg}
}

// Error returns the message of the parse error.
func (e *ParserError) Error() string {
	if e.a != nil {
		return fmt.Sprintf("ParserError.%v (%v)", e.s, e.a)
	}
	return fmt.Sprintf("ParserError.%v", e.s)
}

// formatError returns a string in upper case with underscore instead of space.
// As the Adwords API outputs its errors.
func formatError(s string) string {
	return strings.Replace(strings.ToUpper(strings.TrimSpace(s)), " ", "_", -1)
}
