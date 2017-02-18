package ui

import (
	"bufio"
	"encoding/csv"
	"fmt"
	"io"
	"strconv"
	"strings"
	"time"

	"github.com/apcera/termtables"
)

type Writer interface {
	Error() error
	Flush()
	Write(record []string) error
	WriteHead(record []string) error
}

type Positioner interface {
	Position() int
}

type PositionWriter interface {
	Positioner
	Writer
}

type CsvWriter struct {
	w *csv.Writer
}

func NewCsvWriter(w io.Writer) Writer {
	return &CsvWriter{w: csv.NewWriter(w)}
}

func (w *CsvWriter) Error() error {
	return w.w.Error()
}

// Write any buffered data to the underlying writer.
func (w *CsvWriter) Flush() {
	w.w.Flush()
}

func (w *CsvWriter) Write(record []string) error {
	return w.w.Write(record)
}

func (w *CsvWriter) WriteHead(record []string) error {
	return w.Write(record)
}

// Data
type StatsWriter struct {
	w        *bufio.Writer
	affected bool
	size     int
	t0, t1   time.Time
}

func NewStatsWriter(w io.Writer, exec bool) PositionWriter {
	return &StatsWriter{
		w:        bufio.NewWriter(w),
		t0:       time.Now(),
		affected: exec,
	}
}

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

func (w *StatsWriter) Write(record []string) error {
	// Increments the number of rows in the result set.
	w.size++

	return nil
}

func (w *StatsWriter) WriteHead(record []string) error {
	// Stops the timer, data has been retrieved.
	w.t1 = time.Now()

	return nil
}

type AsciiWriter struct {
	t *termtables.Table
	w *bufio.Writer
	s PositionWriter
}

func NewAsciiWriter(w io.Writer) Writer {
	return &AsciiWriter{
		t: termtables.CreateTable(),
		w: bufio.NewWriter(w),
		s: NewStatsWriter(w, false),
	}
}

func (w *AsciiWriter) Error() error {
	return w.s.Error()
}

func (w *AsciiWriter) Flush() {
	// Outputs the terminal table.
	if w.s.Position() > 1 {
		// Do not print anything if the data table is empty.
		fmt.Fprint(w.w, w.t.Render())
	}
	// Writes any buffered data.
	w.w.Flush()
	// Outputs statistics about it.
	w.s.Flush()
}

func (w *AsciiWriter) Write(record []string) error {
	w.t.AddRow(sliceConv(record)...)

	return w.s.Write(record)
}

func (w *AsciiWriter) WriteHead(record []string) error {
	w.t.AddHeaders(sliceConv(record)...)

	return w.s.WriteHead(record)
}

type VAsciiWriter struct {
	w    *bufio.Writer
	s    PositionWriter
	fmt  string
	head []string
}

func NewVAsciiWriter(w io.Writer) Writer {
	return &VAsciiWriter{
		w: bufio.NewWriter(w),
		s: NewStatsWriter(w, false),
	}
}

func (w *VAsciiWriter) Error() error {
	return w.s.Error()
}

func (w *VAsciiWriter) Flush() {
	// Writes any buffered data.
	w.w.Flush()
	// Outputs statistics about it.
	w.s.Flush()
}

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

func (w *VAsciiWriter) WriteHead(record []string) error {
	// Saves the column names.
	w.head = record

	// Get the length of the header column to define output format.
	max := 0
	for _, c := range record {
		if size := len(c); size > max {
			max = size
		}
	}
	w.fmt = "%" + strconv.Itoa(max) + "v: %v\n"
	return w.s.WriteHead(record)
}

// sliceConv converts []string to []interface {}.
func sliceConv(src []string) []interface{} {
	dest := make([]interface{}, len(src))
	for i, v := range src {
		dest[i] = v
	}
	return dest
}
