package awql

import (
	"encoding/xml"
	"strings"
)

var (
	ErrQuery        = NewQueryError("missing")
	ErrQueryBinding = NewQueryError("binding not match")
	ErrNoDsn        = NewConnectionError("missing data source")
	ErrNoNetwork    = NewConnectionError("not found")
	ErrBadNetwork   = NewConnectionError("service unavailable")
	ErrBadToken     = NewConnectionError("invalid access token")
	ErrAdwordsID    = NewConnectionError("adwords id")
	ErrDevToken     = NewConnectionError("developer token")
)

// In case of error, Google Adwords API provides more information in a XML response
// @example
// <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
// <reportDownloadError>
// 	<ApiError>
// 		<type>ReportDefinitionError.CUSTOMER_SERVING_TYPE_REPORT_MISMATCH</type>
// 		<trigger></trigger>
// 		<fieldPath>selector</fieldPath>
// 	</ApiError>
// </reportDownloadError>
//
// ApiError represents a Google Report Download Error.
// Voluntary ignores trigger field.
type ApiError struct {
	Type    string `xml:"ApiError>type"`
	Trigger string `xml:"ApiError>trigger"`
	Field   string `xml:"ApiError>fieldPath"`
}

// NewApiError parses a XML document that represents a download report error.
// It returns the given message as error.
func NewApiError(d []byte) error {
	if len(d) == 0 {
		return ErrNoDsn
	}
	e := &ApiError{}
	err := xml.Unmarshal(d, e)
	if err != nil {
		e.Type = err.Error()
	}
	return e
}

// String returns a representation of the api error.
func (e *ApiError) Error() string {
	switch e.Field {
	case "":
		if e.Trigger == "" || e.Trigger == "<null>" {
			return e.Type
		}
		return e.Type + " (" + e.Trigger + ")"
	case "selector":
		return e.Type
	default:
		return e.Type + " on " + e.Field
	}
}

// ConnectionError represents an connection error.
type ConnectionError struct {
	s string
}

// NewConnectionError returns an error of type Connection with the given text.
func NewConnectionError(text string) error {
	return &ConnectionError{formatError(text)}
}

// Error outputs a connection error message.
func (e *ConnectionError) Error() string {
	return "ConnectionError." + e.s
}

// QueryError represents a query error.
type QueryError struct {
	s string
}

// NewQueryError returns an error of type Internal with the given text.
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
