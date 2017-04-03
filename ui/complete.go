package ui

import (
	"bytes"
	"regexp"
	"strings"

	db "github.com/rvflash/awql-db"
	parser "github.com/rvflash/awql-parser"
)

// Implements the readline.AutoCompleter interface.
type completer struct {
	db *db.Database
}

// Do
func (c *completer) Do(line []rune, pos int) (newLine [][]rune, length int) {
	l := len(line)
	if l == 0 || l < pos {
		return
	}
	// Gets the main method name.
	var buf bytes.Buffer
	for i := 0; i < l; i++ {
		if i == pos {
			// Current position of the cursor reached.
			break
		}
		if line[i] == ' ' {
			if buf.Len() == 0 {
				// Trims left space
				continue
			}
			break
		}
		buf.WriteRune(line[i])
	}
	if s := buf.String(); len(s) < l {
		// Expected: `METHOD `
		switch strings.ToUpper(s) {
		case "CREATE":
			return c.createCompleter(line, pos)
		case "DESC", "DESCRIBE":
			return c.describeCompleter(line, pos)
		case "SELECT":
			return c.selectCompleter(line, pos)
		case "SHOW":
			return c.showCompleter(line, pos)
		}
	}
	return
}

// createCompleter
func (c *completer) createCompleter(line []rune, pos int) ([][]rune, int) {
	str := string(line[:pos])
	t := tokenize(str)

	var i int
	var s string
	for i, s = range t {
		if strings.EqualFold("SELECT", s) {
			break
		}
	}
	if i > 0 {
		pos = pos - strings.Index(str, s)
		return c.selectCompleter([]rune(strings.Join(t[i:], " ")), pos)
	}
	return nil, 0
}

// describeCompleter
func (c *completer) describeCompleter(line []rune, pos int) ([][]rune, int) {
	t := tokenize(string(line[:pos]))
	l := len(t)
	if l < 2 {
		// Expected: `[DESC ]`
		return nil, 0
	}
	// Searches the position of the table name.
	tpos := 1
	if strings.EqualFold("FULL", t[tpos]) {
		tpos++
	}
	if tpos == l {
		// Expected: `[DESC FULL ]`
		return nil, 0
	}
	// Searches terms to use to complete the statement.
	var v []string
	switch tpos {
	case l - 1:
		// Lists all table names.
		v = c.listTables(t[tpos])
	case l - 2:
		// Lists all columns of the specified table matching its prefix.
		tb, err := c.db.Table(t[tpos])
		if err != nil {
			return nil, 0
		}
		v = c.listTableColumns(tb, t[l-1])
	}
	return candidates(v, len(t[l-1]))
}

// token represents a kind of AWQL struct.
type token int

// List of parts of statement to distinguish during the completion.
const (
	void        token = iota
	table             // Table names
	allColumn         // Columns names
	groupColumn       // Column names used to group in select statement
	orderColumn       // Column names used to order in select statement
	column            // Column names of the table
	during            // During values
)

var duringList = []string{
	"TODAY", "YESTERDAY", "THIS_WEEK_SUN_TODAY", "THIS_WEEK_MON_TODAY",
	"THIS_MONTH", "LAST_WEEK", "LAST_7_DAYS", "LAST_14_DAYS",
	"LAST_30_DAYS", "LAST_BUSINESS_WEEK", "LAST_WEEK_SUN_SAT",
}

// selectCompleter
func (c *completer) selectCompleter(line []rune, pos int) ([][]rune, int) {
	// isColumnName returns true if the string is only literal `[0-9A-Za-z]`.
	var isColumnName = func(s string) bool {
		if ok, _ := regexp.MatchString("[[:alnum:]]", s); ok {
			return !strings.EqualFold("AS", s)
		}
		return false
	}

	// columns parses the columns list to returns the column names.
	// If the completion is possible, it also returns true as second parameter.
	var columns = func(s string) (list []string, incomplete bool) {
		for _, s := range strings.Split(s, ",") {
			if p := strings.Index(s, "("); p > -1 {
				// Method detected. Starts on the parenthesis to allow completion inside.
				s = s[p+1:]
			}
			p := tokenize(s)
			l := len(p)
			if l > 0 && isColumnName(p[l-1]) {
				list = append(list, p[l-1])
			}
			incomplete = l < 2
		}
		return
	}

	// withCompletion splits a string and returns true if the last element can be completed.
	var withCompletion = func(s, split string) bool {
		// Splits by the given pattern.
		v := regexp.MustCompile(split).Split(s, -1)
		// Splits around each instance of one or more consecutive white space characters.
		return len(tokenize(v[len(v)-1])) < 2
	}

	// keyword fetches current and previous word to verify if it's a keyword.
	// If yes, the second parameter is set to true and the first contains the token's kind.
	var keyword = func(c, p string) (token, bool) {
		if strings.EqualFold("FROM", c) {
			return table, true
		}
		if strings.EqualFold("WHERE", c) {
			return column, true
		}
		if strings.EqualFold("DURING", c) {
			return during, true
		}
		if strings.EqualFold("GROUP", c) {
			return void, true
		}
		if strings.EqualFold("ORDER", c) {
			return void, true
		}
		if strings.EqualFold("BY", c) {
			if strings.EqualFold("GROUP", p) {
				return groupColumn, true
			}
			if strings.EqualFold("ORDER", p) {
				return orderColumn, true
			}
		}
		if strings.EqualFold("LIMIT", c) {
			return void, true
		}
		return void, false
	}

	// Parses the statement to find the kind of completion to do.
	t := tokenize(string(line[:pos]))
	l := len(t)
	if l < 2 {
		return nil, 0
	}
	// Without table as context, statement begins with list of all columns.
	tk := allColumn

	var bs, bw, bg, bo bytes.Buffer
	var tb, s string
	for i := 1; i < l; i++ {
		// Searches keyword like `FROM`, `WHERE`, etc.
		nk, ok := keyword(t[i], t[i-1])
		if ok {
			// Keyword found. Checks if statement is not ending.
			if i+1 < l {
				tk = nk
			}
			continue
		}
		s = t[i]

		switch tk {
		case table:
			if tb == "" {
				tb = s
			} else {
				tk = void
			}
		case allColumn:
			// Concatenates strings between `SELECT` and `FROM`
			bs.WriteString(" " + s)
		case column:
			// Concatenates strings after `WHERE`, until the next SQL keyword.
			bw.WriteString(" " + s)
		case groupColumn:
			// Concatenates strings after `GROUP BY`, until the next SQL keyword.
			bg.WriteString(" " + s)
		case orderColumn:
			// Concatenates strings after `ORDER BY`, until the next SQL keyword.
			bo.WriteString(" " + s)
		case during:
			if strings.Contains(s, ",") {
				tk = void
			}
		}
	}

	// Completes the analyze by retrieving the names of each selected column.
	cols, ok := columns(bs.String())
	if tk == allColumn && !ok {
		// The `FROM` keyword does not occurred yet.
		tk = void
	}

	// Searches for candidate to complete the statement.
	var v []string
	switch tk {
	case table:
		// Lists all table names.
		v = c.listTables(s)
	case allColumn:
		// Lists all columns of the database.
		v = c.db.ColumnNamesPrefixedBy(s)
	case column:
		// Lists all columns of the specified table matching the prefix.
		// Splits where clause with ` and ` in case-insensitive mode.
		if withCompletion(bw.String(), "(?i) and ") {
			tb, err := c.db.Table(tb)
			if err != nil {
				v = c.db.ColumnNamesPrefixedBy(s)
			} else {
				v = c.listTableColumns(tb, s)
			}
		}
	case orderColumn:
		if withCompletion(bo.String(), ",") {
			v = stringsPrefixedBy(cols, s)
		}
	case groupColumn:
		if withCompletion(bg.String(), ",") {
			v = stringsPrefixedBy(cols, s)
		}
	case during:
		v = stringsPrefixedBy(duringList, s)
	case void:
		return nil, 0
	}
	return candidates(v, len(s))
}

// showCompleter
func (c *completer) showCompleter(line []rune, pos int) ([][]rune, int) {
	t := tokenize(string(line[:pos]))
	l := len(t)
	if l < 4 {
		// Expected: `[SHOW TABLES WITH ]`
		return nil, 0
	}
	// Searches the position of the column name.
	cpos := 1
	if strings.EqualFold("FULL", t[cpos]) {
		cpos++
	}
	if strings.EqualFold("TABLES", t[cpos]) {
		cpos++
	}
	if strings.EqualFold("WITH", t[cpos]) {
		cpos++
	}
	if cpos == l {
		// Expected: `[SHOW FULL TABLES WITH ]`
		return nil, 0
	}
	return candidates(c.db.ColumnNamesPrefixedBy(t[cpos]), len(t[cpos]))
}

// listTableColumns returns the name of column's table prefixed by this pattern.
func (c *completer) listTableColumns(tb db.DataTable, prefix string) (names []string) {
	var columns []parser.DynamicField
	if prefix == "" {
		columns = tb.Columns()
	} else {
		columns = tb.ColumnsPrefixedBy(prefix)
	}
	names = make([]string, len(columns))
	for i, c := range columns {
		names[i] = c.Name()
	}
	return
}

// listTables returns the name of all known tables prefixed by this pattern.
func (c *completer) listTables(prefix string) (names []string) {
	var tables []db.DataTable
	if prefix == "" {
		var err error
		tables, err = c.db.Tables()
		if err != nil {
			return nil
		}

	} else {
		tables = c.db.TablesPrefixedBy(prefix)
	}
	names = make([]string, len(tables))
	for i, t := range tables {
		names[i] = t.SourceName()
	}
	return
}

// tokenize returns a slice of string by splitting it by space.
func tokenize(s string) []string {
	// Also manages `(` as separator to manage the methods.
	s = strings.Replace(s, "(", "( ", -1)
	// Splits the string s around each instance of one or more consecutive space.
	v := strings.Fields(s)
	if strings.HasSuffix(s, " ") {
		v = append(v, "")
	}
	return v
}

// candidates returns a slice of runes with candidates for auto-completion.
func candidates(list []string, start int) ([][]rune, int) {
	size := len(list)
	if size == 0 {
		return nil, 0
	}
	newLine := make([][]rune, size)
	for i, s := range list {
		newLine[i] = []rune(s)[start:]
	}
	return newLine, start
}

// stringsPrefixedBy returns a slice of strings with values matching the prefix.
func stringsPrefixedBy(f []string, s string) (t []string) {
	if s == "" {
		// No given prefix, all values are available.
		return f
	}
	for _, v := range f {
		if strings.HasPrefix(v, s) {
			t = append(t, v)
		}
	}
	return
}
