package ui

import (
	"bufio"
	"encoding/csv"
	"fmt"
	"io"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"
)

// Ascii table separators.
const (
	asciiBorderX = "-"
	asciiBorderY = "|"
	asciiBorderI = "+"
)

// Writer
type Writer interface {
	Error() error
	Flush()
	Write(record []string) error
	WriteHead(record []string) error
}

// Positioner
type Positioner interface {
	Position() int
}

// PositionWriter
type PositionWriter interface {
	Positioner
	Writer
}

// CsvWriter
type CsvWriter struct {
	w *csv.Writer
}

// NewCsvWriter
func NewCsvWriter(w io.Writer) Writer {
	return &CsvWriter{w: csv.NewWriter(w)}
}

// Error
func (w *CsvWriter) Error() error {
	return w.w.Error()
}

// Flush writes any buffered data to the underlying writer.
func (w *CsvWriter) Flush() {
	w.w.Flush()
}

// Write
func (w *CsvWriter) Write(record []string) error {
	return w.w.Write(record)
}

// WriteHead
func (w *CsvWriter) WriteHead(record []string) error {
	return w.Write(record)
}

// StatsWriter
type StatsWriter struct {
	w        *bufio.Writer
	affected bool
	size     int
	t0, t1   time.Time
}

// NewStatsWriter
func NewStatsWriter(w io.Writer, exec bool) PositionWriter {
	return &StatsWriter{
		w:        bufio.NewWriter(w),
		t0:       time.Now(),
		affected: exec,
	}
}

// Error
func (w *StatsWriter) Error() error {
	return nil
}

// Write any buffered data to the underlying writer.
func (w *StatsWriter) Flush() {
	// In case of the end date is not defined, sets it.
	if w.t1.IsZero() {
		// Statement using exec mode.
		w.t1 = time.Now()
	}

	// Outputs statistics about the result set.
	var format string
	switch {
	case w.affected:
		// Exec query like CREATE VIEW.
		format = "Query OK, %d rows affected (%.3f sec)\n\n"
		fallthrough
	case w.size > 0:
		if format == "" {
			format = "%d row"
			if w.size > 1 {
				// Manages the plural :)
				format += "s"
			}
			format += " in set (%.3f sec)\n\n"
		}
		w.w.WriteString(fmt.Sprintf(format, w.size, w.t1.Sub(w.t0).Seconds()))
	default:
		format = "Empty set (%.3f sec)\n\n"
		w.w.WriteString(fmt.Sprintf(format, w.t1.Sub(w.t0).Seconds()))
	}
	w.w.Flush()
}

// Position returns the current size of the result set.
func (w *StatsWriter) Position() int {
	return w.size + 1
}

// Write
func (w *StatsWriter) Write(record []string) error {
	// Increments the number of rows in the result set.
	w.size++

	return nil
}

// WriteHead
func (w *StatsWriter) WriteHead(record []string) error {
	// Stops the timer, data has been retrieved.
	w.t1 = time.Now()

	return nil
}

// AsciiWriter
type AsciiWriter struct {
	w        *bufio.Writer
	s        PositionWriter
	fmt, sep string
}

// NewAsciiWriter
func NewAsciiWriter(w io.Writer) Writer {
	return &AsciiWriter{
		w:   bufio.NewWriter(w),
		s:   NewStatsWriter(w, false),
		fmt: asciiBorderY,
		sep: asciiBorderI,
	}
}

// Error
func (w *AsciiWriter) Error() error {
	return w.s.Error()
}

// Flush
func (w *AsciiWriter) Flush() {
	// Outputs the terminal table.
	if w.s.Position() > 1 {
		// Prints the end of the table only if it contains at less one line.
		fmt.Fprint(w.w, w.sep)
	}
	// Writes any buffered data.
	w.w.Flush()
	// Outputs statistics about it.
	w.s.Flush()
}

// Write
func (w *AsciiWriter) Write(record []string) error {
	// Prints the records
	data := make([]interface{}, len(record))
	for i, v := range record {
		data[i] = v
	}
	fmt.Fprintf(w.w, w.fmt, data...)

	return w.s.Write(record)
}

// WriteHead writes the table header and defines column sizes.
func (w *AsciiWriter) WriteHead(record []string) error {
	// Defines the format to use as separator line for a column.
	var fmtColumn = func(size int, end string) string {
		return " %-" + strconv.Itoa(size) + "v" + end
	}
	// Builds the ascii table
	data := make([]interface{}, len(record))
	var size int
	for i := range record {
		// Converts string's slice to slice of interface.
		data[i] = record[i]
		// Defines the columns size surround by space.
		size = utf8.RuneCountInString(record[i]) + 1
		// Defines the format to use to display each line.
		w.fmt += fmtColumn(size, asciiBorderY)
		// Builds the line to separate each records
		w.sep += strings.Repeat(asciiBorderX, size+1) + asciiBorderI
	}
	// Finalizes the formats.
	w.fmt += "\n"
	w.sep += "\n"
	// Prints the table's head.
	fmt.Fprintf(w.w, w.sep)
	fmt.Fprintf(w.w, w.fmt, data...)
	fmt.Fprintf(w.w, w.sep)

	return w.s.WriteHead(record)
}

// VAsciiWriter
type VAsciiWriter struct {
	w    *bufio.Writer
	s    PositionWriter
	fmt  string
	head []string
}

// NewVAsciiWriter
func NewVAsciiWriter(w io.Writer) Writer {
	return &VAsciiWriter{
		w: bufio.NewWriter(w),
		s: NewStatsWriter(w, false),
	}
}

// Error
func (w *VAsciiWriter) Error() error {
	return w.s.Error()
}

// Flush
func (w *VAsciiWriter) Flush() {
	// Writes any buffered data.
	w.w.Flush()
	// Outputs statistics about it.
	w.s.Flush()
}

// Write
func (w *VAsciiWriter) Write(record []string) error {
	// Prints the separator line.
	head := strings.Repeat("*", 28)
	fmt.Fprintf(w.w, "%s %d. row %s\n", head, w.s.Position(), head)

	// Prints each record column as a line.
	for i := range record {
		fmt.Fprintf(w.w, w.fmt, w.head[i], record[i])
	}

	return w.s.Write(record)
}

// WriteHead
func (w *VAsciiWriter) WriteHead(record []string) error {
	// Saves the column names.

	// Get the length of the header column to define output format.
	max := 0
	size := len(record)
	w.head = make([]string, size)
	for i := 0; i < size; i++ {
		w.head[i] = strings.TrimSpace(record[i])
		if size := len(w.head[i]); size > max {
			max = size
		}
	}
	w.fmt = "%" + strconv.Itoa(max) + "v: %v\n"

	return w.s.WriteHead(record)
}
