package awqlparse_test

import (
	"strings"
	"testing"

	awql "github.com/rvflash/awql-parser"
)

// Ensure the scanner can scan tokens correctly.
func TestScanner_Scan(t *testing.T) {
	var tests = []struct {
		s string
		t awql.Token
		l string
	}{
		// Special tokens (EOF, ILLEGAL, etc.)
		{s: ``, t: awql.EOF},
		{s: `#`, t: awql.ILLEGAL, l: `#`},
		{s: `8`, t: awql.DIGIT, l: `8`},
		{s: `1.0`, t: awql.DECIMAL, l: `1.0`},
		{s: `2.0b`, t: awql.DECIMAL, l: `2.0`},
		{s: `\G`, t: awql.G_MODIFIER, l: `\G`},
		{s: `\g`, t: awql.G_MODIFIER, l: `\g`},
		{s: `\p`, t: awql.ILLEGAL, l: `\`},

		// Misc characters
		{s: `*`, t: awql.ASTERISK, l: `*`},
		{s: `,`, t: awql.COMMA, l: `,`},
		{s: `(`, t: awql.LEFT_PARENTHESIS, l: `(`},
		{s: `)`, t: awql.RIGHT_PARENTHESIS, l: `)`},
		{s: `[`, t: awql.LEFT_SQUARE_BRACKETS, l: `[`},
		{s: `]`, t: awql.RIGHT_SQUARE_BRACKETS, l: `]`},
		{s: `;`, t: awql.SEMICOLON, l: `;`},

		// Literal
		{s: ` `, t: awql.WHITE_SPACE, l: ` `},
		{s: `   a`, t: awql.WHITE_SPACE, l: `   `},
		{s: "\t", t: awql.WHITE_SPACE, l: "\t"},
		{s: "\n", t: awql.WHITE_SPACE, l: "\n"},
		{s: `'string'`, t: awql.STRING, l: `string`},
		{s: `"string"`, t: awql.STRING, l: `string`},
		{s: `"stri`, t: awql.ILLEGAL, l: `stri`},
		{s: `"my \"tiny\" string"`, t: awql.STRING, l: `my \"tiny\" string`},
		{s: `a.b`, t: awql.VALUE_LITERAL, l: `a.b`},

		// Operator
		{s: `=`, t: awql.EQUAL, l: `=`},
		{s: `!=`, t: awql.DIFFERENT, l: `!=`},
		{s: `!-`, t: awql.ILLEGAL, l: `!`},
		{s: `>`, t: awql.SUPERIOR, l: `>`},
		{s: `>=`, t: awql.SUPERIOR_OR_EQUAL, l: `>=`},
		{s: `<`, t: awql.INFERIOR, l: `<`},
		{s: `<=`, t: awql.INFERIOR_OR_EQUAL, l: `<=`},
		{s: `IN`, t: awql.IN, l: `IN`},
		{s: `NOT_IN`, t: awql.NOT_IN, l: `NOT_IN`},
		{s: `STARTS_WITH`, t: awql.STARTS_WITH, l: `STARTS_WITH`},
		{s: `STARTS_WITH_IGNORE_CASE`, t: awql.STARTS_WITH_IGNORE_CASE, l: `STARTS_WITH_IGNORE_CASE`},
		{s: `CONTAINS`, t: awql.CONTAINS, l: `CONTAINS`},
		{s: `CONTAINS_IGNORE_CASE`, t: awql.CONTAINS_IGNORE_CASE, l: `CONTAINS_IGNORE_CASE`},
		{s: `DOES_NOT_CONTAIN`, t: awql.DOES_NOT_CONTAIN, l: `DOES_NOT_CONTAIN`},
		{s: `DOES_NOT_CONTAIN_IGNORE_CASE`, t: awql.DOES_NOT_CONTAIN_IGNORE_CASE, l: `DOES_NOT_CONTAIN_IGNORE_CASE`},

		// Identifiers
		{s: `Criteria`, t: awql.IDENTIFIER, l: `Criteria`},
		{s: `CRITERIA_PERFORMANCE_REPORT`, t: awql.IDENTIFIER, l: `CRITERIA_PERFORMANCE_REPORT`},
		{s: `Z6P0_C3P0_-`, t: awql.IDENTIFIER, l: `Z6P0_C3P0_`},

		// Keywords
		{s: `DESCRIBE`, t: awql.DESCRIBE, l: `DESCRIBE`},
		{s: `select`, t: awql.SELECT, l: `select`},
		{s: `CREATE`, t: awql.CREATE, l: `CREATE`},
		{s: `replace`, t: awql.REPLACE, l: `replace`},
		{s: `VIEW`, t: awql.VIEW, l: `VIEW`},
		{s: `SHOW`, t: awql.SHOW, l: `SHOW`},
		{s: `FULL`, t: awql.FULL, l: `FULL`},
		{s: `TABLES`, t: awql.TABLES, l: `TABLES`},
		{s: `DISTINCT`, t: awql.DISTINCT, l: `DISTINCT`},
		{s: `AS`, t: awql.AS, l: `AS`},
		{s: `FROM`, t: awql.FROM, l: `FROM`},
		{s: `WHERE`, t: awql.WHERE, l: `WHERE`},
		{s: `LIKE`, t: awql.LIKE, l: `LIKE`},
		{s: `WITH`, t: awql.WITH, l: `WITH`},
		{s: `AND`, t: awql.AND, l: `AND`},
		{s: `OR`, t: awql.OR, l: `OR`},
		{s: `DURING`, t: awql.DURING, l: `DURING`},
		{s: `ORDER`, t: awql.ORDER, l: `ORDER`},
		{s: `GROUP`, t: awql.GROUP, l: `GROUP`},
		{s: `BY`, t: awql.BY, l: `BY`},
		{s: `ASC`, t: awql.ASC, l: `ASC`},
		{s: `DESC`, t: awql.DESC, l: `DESC`},
		{s: `LIMIT`, t: awql.LIMIT, l: `LIMIT`},
	}

	for i, tt := range tests {
		s := awql.NewScanner(strings.NewReader(tt.s))
		tk, l := s.Scan()
		if tt.t != tk {
			t.Errorf("%d. %q token mismatch: exp=%q got=%q <%q>", i, tt.s, tt.t, tk, l)
		} else if tt.l != l {
			t.Errorf("%d. %q literal mismatch: exp=%q got=%q", i, tt.s, tt.l, l)
		}
	}
}
