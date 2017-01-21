package io

import (
	"database/sql"
	"fmt"
	"os"
	"strings"

	"github.com/chzyer/readline"
	parser "github.com/rvflash/awql-parser"
	"github.com/rvflash/awql/config"
)

const (
	// Shell prompts
	Prompt          = "awql> "
	PromptMultiLine = "   -> "

	// Ends of statement.
	StdEnd      = ";"
	VerticalEnd = "\\g"

	// Commands
	ShortCmdClear = "c"
	ShortCmdHelp  = "h"
	ShortCmdExit  = "q"
)

// Command represents a command.
type Command struct {
	text, cmd, usage string
}

// ShortForm returns the short-form command.
// Output: \c
func (c Command) ShortForm() string {
	return `\` + c.cmd
}

// String returns a readable representation of a command.
// It implements fmt.String() interface.
// Output:
// clear      (\c) Clear the current input statement.
func (c Command) String() string {
	return fmt.Sprintf("%-10s (%s) %s", c.text, c.ShortForm(), c.usage)
}

// Set of available commands that the tool itself interprets.
var CmdClear = Command{"clear", ShortCmdClear, "Clear the current input statement."}
var CmdHelp = Command{"help", ShortCmdHelp, "Display this help."}
var CmdExit = Command{"exit", ShortCmdExit, "Exit awql. Same as quit."}
var CmdQuit = Command{"quit", ShortCmdExit, "Quit awql command line tool."}
var Commands = [4]Command{CmdClear, CmdHelp, CmdExit, CmdQuit}

// Scanner
type Scanner interface {
	Scan() error
}

// Seeker
type Seeker interface {
	Seek(s string) error
}

// ScanSeeker
type ScanSeeker interface {
	Scanner
	Seeker
}

// Stdin represents a basic input.
type CommandLine struct {
	c config.Config
	d *sql.DB
}

// NewCommandLine returns a basic input.
func NewCommandLine(conf config.Config) ScanSeeker {
	return &CommandLine{c: conf}
}

// Scan starts the engine with only the query query to execute from args.
func (e *CommandLine) Scan() (err error) {
	// Sends statement to Advanced Awql driver.
	e.d, err = sql.Open("aawql", e.c.Dsn())
	if err != nil {
		return
	}
	return e.Seek(e.c.ExecuteStmt())
}

// Seek
func (e *CommandLine) Seek(s string) error {
	// Executes each query one after the other.
	stmts, err := parser.NewParser(strings.NewReader(s)).Parse()
	if err != nil {
		return err
	}
	for _, stmt := range stmts {
		var w Writer
		if _, ok := stmt.(parser.CreateViewStmt); ok {
			// Use a basic writer, just to aggregate statistics.
			w = NewStatsWriter(os.Stdout, true)

			// Sends the query.
			if _, err = e.d.Exec(stmt.String()); err != nil {
				fmt.Println(err)
				continue
			}
			w.Flush()
		} else {
			// Chooses the table writer.
			switch {
			case e.c.UseBatchMode():
				w = NewCsvWriter(os.Stdout)
			case stmt.VerticalOutput():
				w = NewVAsciiWriter(os.Stdout)
			default:
				w = NewAsciiWriter(os.Stdout)
			}

			// Sends the query.
			rs, err := e.d.Query(stmt.String())
			if err != nil {
				fmt.Println(err)
				continue
			}

			// Get the column names.
			cols, err := rs.Columns()
			if err != nil {
				fmt.Println(err)
				continue
			}
			if err := w.WriteHead(cols); err != nil {
				return err
			}

			// Create slices to manage the rows.
			size := len(cols)
			vals := make([]string, size)
			ints := make([]interface{}, size)
			for i := range ints {
				ints[i] = &vals[i]
			}
			for rs.Next() {
				rs.Scan(ints...)
				if err := w.Write(vals); err != nil {
					return err
				}
			}

			// Write any buffered data and statistics.
			w.Flush()

			if err := w.Error(); err != nil {
				return err
			}
		}
	}

	return nil
}

// Terminal represents a terminal as stdin.
type Terminal struct {
	CommandLine
}

// NewTerm returns an instance of Terminal.
func NewTerminal(conf config.Config) ScanSeeker {
	return &Terminal{CommandLine{c: conf}}
}

// Scan starts the engine with a listening of the terminal as stdin.
func (e *Terminal) Scan() error {
	// Prints to standard output the welcome message.
	e.printWelcome()

	// Initializes the line reader.
	reader, err := readline.NewEx(&readline.Config{
		Prompt:                 Prompt,
		HistoryFile:            e.c.HistoryFile(),
		DisableAutoSaveHistory: true,
	})
	if err != nil {
		return fmt.Errorf("ToolError.INVALID_TERM (%s)", err)
	}
	defer reader.Close()

	// Establishes the connection.
	e.d, err = sql.Open("aawql", e.c.Dsn())
	if err != nil {
		return err
	}

	// Listens and reads statements from the shell.
	for {
		// Expects one statement or command.
		q, err := e.readLine(reader)
		if err != nil {
			// Terminal error or command aborted.
			// @todo Improves management by fetching error type.
			e.printAborted()
			return nil
		}
		if cmd, ok := useCommand(q); ok {
			// List of commands that the tool itself interprets.
			if cmd.cmd == ShortCmdClear {
				// Clears the current input statement.
				continue
			} else if cmd.cmd == ShortCmdHelp {
				// Prints help.
				e.printHelp()
			} else {
				// Quits the tool.
				e.printExit()
				break
			}
		} else {
			// Sends statement to Advanced Awql driver.
			return e.Seek(q)
		}
	}

	return nil
}

// printAborted writes the unhappy end message.
func (e *Terminal) printAborted() {
	fmt.Println("Aborted")
}

// printExit writes the happy end message.
func (e *Terminal) printExit() {
	fmt.Println("Bye")
}

// printHelp writes to standard output the welcome message.
func (e *Terminal) printHelp() {
	fmt.Println("The AWQL command line tool is developed by Hervé GOUCHET.")
	fmt.Println("For developer information, visit:")
	fmt.Printf("  %s\n", "https://github.com/rvflash/awql/")
	fmt.Println("For information about AWQL language, visit:")
	fmt.Printf("  %s\n", "https://developers.google.com/adwords/api/docs/guides/awql")
	fmt.Println("")
	fmt.Println("List of all AWQL commands:")
	fmt.Println("Note that all text commands must be first on line and end with ';'")

	// List all commands
	for _, c := range Commands {
		fmt.Println(c)
	}
	fmt.Println("")
}

// printWelcome writes to standard output the help.
func (e *Terminal) printWelcome() {
	fmt.Println("Welcome to the AWQL monitor. Commands end with ; or \\g.")
	if e.c.SupportsZeroImpressions() {
		fmt.Println("Your AWQL connection supports zero impressions.")
	} else {
		fmt.Println("Your AWQL connection implicitly excludes zero impressions.")
	}
	fmt.Printf("Adwords API version: %s\n\n", e.c.ApiVersion())
	fmt.Println("Reading table information for completion of table and column names.")
	fmt.Println("You can turn off this feature to get a quicker startup with -A")
	fmt.Println("")
	fmt.Println("Type 'help;' or '\\h' for help. Type '\\c' to clear the current input statement.")
	fmt.Println("")
}

// readLine returns the last statement or an error.
func (e *Terminal) readLine(reader *readline.Instance) (string, error) {
	var lines []string
	for {
		line, err := reader.Readline()
		if err != nil {
			return "", err
		}

		// Ignores he empty line.
		if line = strings.TrimSpace(line); line == "" {
			continue
		}
		lines = append(lines, line)

		// Continue until the end of the query.
		if !withLineEnd(line) {
			reader.SetPrompt(PromptMultiLine)
			continue
		}

		// Resets the environment for the next read line.
		reader.SetPrompt(Prompt)

		// Computes all lines in one.
		q := strings.Join(lines, " ")

		// Saves the query in history.
		if _, ok := useCommand(q); !ok {
			reader.SaveHistory(q)
		}
		return q, nil
	}
}

// withStmtEnd returns true if the statement ends with ";" or "\g".
func withStmtEnd(q string) bool {
	switch {
	case
		strings.HasSuffix(q, StdEnd),
		strings.HasSuffix(q, VerticalEnd):
		return true
	}
	return false
}

// withLineEnd returns true if it's the end of the statement or a command.
func withLineEnd(q string) bool {
	if withStmtEnd(q) || withCommandEnd(q) {
		return true
	}
	return false
}

// withCommandEnd returns true if it's ending by a command like "\c", or "\h".
func withCommandEnd(q string) bool {
	for _, c := range Commands {
		if strings.HasSuffix(q, c.ShortForm()) {
			return true
		}
	}
	return false
}

// command returns the command matching the given term.
// If it exists, it returns the second parameter to true.
func useCommand(q string) (*Command, bool) {
	for i, c := range Commands {
		switch {
		case strings.HasPrefix(q, c.text):
			if withStmtEnd(q) {
				return &Commands[i], true
			}
		case strings.HasSuffix(q, c.ShortForm()):
			return &Commands[i], true
		}
	}
	return nil, false
}
