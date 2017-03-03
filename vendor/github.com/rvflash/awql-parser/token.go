package awqlparse

/*
Base AWQL grammar
https://developers.google.com/adwords/api/docs/guides/awql#grammar

Extended AWQL grammar
https://github.com/rvflash/awql/
*/

// Token represents a lexical token.
type Token int

// List of special runes or reserved keywords.
const (
	// Special tokens
	ILLEGAL Token = iota
	EOF
	DIGIT      // [0-9]
	DECIMAL    // [0-9.]
	G_MODIFIER // \G ou \g

	// Literals
	IDENTIFIER  // base element
	WHITE_SPACE // white space
	STRING      // char between single or double quotes
	STRING_LIST
	VALUE_LITERAL // [a-zA-Z0-9_.]
	VALUE_LITERAL_LIST

	// Misc characters
	ASTERISK              // *
	COMMA                 // ,
	LEFT_PARENTHESIS      // (
	RIGHT_PARENTHESIS     // )
	LEFT_SQUARE_BRACKETS  // [
	RIGHT_SQUARE_BRACKETS // ]
	SEMICOLON             // ;

	// Operator
	EQUAL             // =
	DIFFERENT         // !=
	SUPERIOR          // >
	SUPERIOR_OR_EQUAL // >=
	INFERIOR          // <
	INFERIOR_OR_EQUAL // <=
	IN
	NOT_IN
	STARTS_WITH
	STARTS_WITH_IGNORE_CASE
	CONTAINS
	CONTAINS_IGNORE_CASE
	DOES_NOT_CONTAIN
	DOES_NOT_CONTAIN_IGNORE_CASE

	// Base keywords
	DESCRIBE
	SELECT
	CREATE
	REPLACE
	VIEW
	SHOW
	FULL
	TABLES
	DISTINCT
	AS
	FROM
	WHERE
	LIKE
	WITH
	AND
	OR
	DURING
	ORDER
	GROUP
	BY
	ASC
	DESC
	LIMIT
)
