package main

import (
	"fmt"
	"log"
	"os"

	"github.com/rvflash/awql/config"
	"github.com/rvflash/awql/io"
)

func main() {
	conf := config.New()
	if err := conf.Init(); err != nil {
		exit(err)
	}
	// Launch the environment.
	var src io.Scanner
	if conf.IsInteractive() {
		src = io.NewTerminal(conf)
	} else {
		src = io.NewCommandLine(conf)
	}
	if err := src.Scan(); err != nil {
		exit(err)
	}
}

// Exit causes the current program to exit with the appropriate status code.
func exit(err error) {
	if err == nil {
		// See you soon.
		os.Exit(0)
	}
	// An error occurred, exits with the appropriate behavior.
	switch err.(type) {
	case *config.FlagError:
		fmt.Println(err)
		config.Usage()
		os.Exit(1)
	default:
		log.Fatal(err)
	}
}
