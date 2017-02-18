package ui

import (
	"bytes"
	"strings"

	"regexp"

	db "github.com/rvflash/awql-db"
	parser "github.com/rvflash/awql-parser"
)

// Implements the readline.AutoCompleter interface.
type completer struct {
	db *db.Database
}

func (c *completer) Do(line []rune, pos int) (newLine [][]rune, length int) {
	if l := len(line); l == 0 || l < pos {
		return
	}
	// Gets the main method name.
	var buf bytes.Buffer
	for i, r := range line {
		if i == pos {
			// Current position of the cursor reached.
			break
		}
		if r == ' ' {
			if buf.Len() == 0 {
				// Trims left space
				continue
			}
			break
		}
		buf.WriteRune(r)
	}
	switch strings.ToUpper(buf.String()) {
	case "CREATE":
		return c.createCompleter(line, pos)
	case "DESC", "DESCRIBE":
		return c.describeCompleter(line, pos)
	case "SELECT":
		return c.selectCompleter(line, pos)
	case "SHOW":
		return c.showCompleter(line, pos)
	}
	return
}

func (c *completer) createCompleter(line []rune, pos int) (newLine [][]rune, length int) {
	return
}

// describeCompleter
func (c *completer) describeCompleter(line []rune, pos int) ([][]rune, int) {
	t := splitRunesBySpace(line[:pos])
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
	return stringsAsCandidate(v, len(t[l-1]))
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

func (c *completer) selectCompleter(line []rune, pos int) ([][]rune, int) {
	// columns parses the columns list to returns the column names.
	// It also returns true as second parameter if the completion is still enable.
	var columns = func(s string) (list []string, complete bool) {
		for _, s := range strings.Split(s, ",") {
			p := strings.Split(s, " ")
			l := len(p)
			ok, _ := regexp.MatchString("[[:alnum:]]", p[l-1])
			if ok && !strings.EqualFold("AS", p[l-1]) {
				list = append(list, p[l-1])
				complete = l == 1
			} else {
				complete = false
			}
		}
		return
	}

	// withCompletion splits a string and returns true if the last element can be completed.
	var withCompletion = func(s, split string) bool {
		v := strings.Split(s, split)
		return len(strings.Split(strings.TrimSpace(v[len(v)-1]), " ")) == 1
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
	t := splitRunesBySpace(line[:pos])
	l := len(t)
	tk := allColumn

	var bs, bw, bg, bo bytes.Buffer
	var tb, s string
	for i := 1; i < l; i++ {
		// Searches term like FROM, WHERE, etc.
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
			if tb != "" && s != "" {
				// Too much name for this table!
				tk = void
			} else {
				tb = s
			}
		case allColumn:
			// Concatenates strings between SELECT and FROM
			bs.WriteString(s)
		case column:
			// Concatenates strings after WHERE, until the next SQL keyword.
			bw.WriteString(s)
		case groupColumn:
			// Concatenates strings after GROUP BY, until the next SQL keyword.
			bg.WriteString(s)
		case orderColumn:
			// Concatenates strings after ORDER BY, until the next SQL keyword.
			bo.WriteString(s)
		case during:
			if strings.Contains(s, ",") {
				tk = void
			}
		}
	}

	// Completes the analyze by retrieving the names of each selected column.
	cols, ok := columns(bs.String())
	if tk == allColumn && !ok {
		tk = void
	}

	// @debug ioutil.WriteFile("/tmp/rv", []byte(fmt.Sprintf("%v-%v\n", tk, s)), 0644)

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
		if withCompletion(bw.String(), " AND ") {
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
		v = listDurings(s)
	case void:
		return nil, 0
	}
	return stringsAsCandidate(v, len(s))
}

// showCompleter
func (c *completer) showCompleter(line []rune, pos int) ([][]rune, int) {
	t := splitRunesBySpace(line[:pos])
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
		// Expected: `[SHOW FULL TABLES WITH ]`// Expected: `[SHOW FULL TABLES WITH ]`
		return nil, 0
	}
	return stringsAsCandidate(c.db.ColumnNamesPrefixedBy(t[cpos]), len(t[cpos]))
}

// listTableColumns returns the name of column's table prefixed by this pattern.
func (c *completer) listTableColumns(tb db.DataTable, prefix string) []string {
	var columns []parser.DynamicField
	if prefix == "" {
		columns = tb.Columns()
	} else {
		columns = tb.ColumnsPrefixedBy(prefix)
	}
	var names []string
	names = make([]string, len(columns))
	for i, c := range columns {
		names[i] = c.Name()
	}
	return names
}

// listTables returns the name of all known tables prefixed by this pattern.
func (c *completer) listTables(prefix string) []string {
	var err error
	var tables []db.DataTable
	if prefix == "" {
		tables, err = c.db.Tables()
	} else {
		tables = c.db.TablesPrefixedBy(prefix)
	}
	if err != nil {
		return nil
	}
	var names []string
	names = make([]string, len(tables))
	for i, t := range tables {
		names[i] = t.SourceName()
	}
	return names
}

// listDurings returns the during values beginning by the prefix.
func listDurings(prefix string) []string {
	during := []string{
		"TODAY", "YESTERDAY", "THIS_WEEK_SUN_TODAY", "THIS_WEEK_MON_TODAY", "THIS_MONTH",
		"LAST_WEEK", "LAST_7_DAYS", "LAST_14_DAYS", "LAST_30_DAYS", "LAST_BUSINESS_WEEK",
		"LAST_WEEK_SUN_SAT"}
	if prefix == "" {
		return during
	}
	return stringsPrefixedBy(during, prefix)
}

// splitRunesBySpace returns a slice of string by splitting a slice of runes by space.
func splitRunesBySpace(r []rune) []string {
	return strings.Split(strings.TrimLeft(string(r), " "), " ")
}

// stringAsCandidate returns a slice of runes with candidates for auto-completion.
func stringsAsCandidate(list []string, start int) ([][]rune, int) {
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
	for _, v := range f {
		if strings.HasPrefix(v, s) {
			t = append(t, v)
		}
	}
	return
}
