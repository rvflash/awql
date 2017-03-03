package conf

import (
	"flag"
	"fmt"
	"regexp"

	awql "github.com/rvflash/awql-driver"
)

// Usage messages.
const (
	UsageAccountID      = "Google Adwords account ID"
	UsageAccessToken    = "Google OAuth access token"
	UsageDeveloperToken = "Google OAuth developer token"
	UsageAPIVersion     = "Google Adwords API version"
	UsageQuery          = "Execute AWQL statement"
)

// CmdError represents an error for the command-line tool.
type FlagError struct {
	s string
}

// NewCmdError returns an error of the parse error.
func NewFlagError(text string) error {
	return &FlagError{s: text}
}

// Error returns the message of the parse error.
func (e *FlagError) Error() string {
	return fmt.Sprintf("FlagError.INVALID (%v)", e.s)
}

// Flag represents all options passed by the program.
type Flag struct {
	AccountID,
	AccessToken,
	APIVersion,
	DeveloperToken,
	Query *string
	Batch,
	ZeroImpressions,
	NoRehash,
	Verbose,
	Caching *bool
}

// Check checks all required inputs.
func (o *Flag) Check() error {
	// Expected account identifier like 123-456-7890
	if ok, _ := regexp.MatchString("^[0-9]{3}-[0-9]{3}-[0-9]{4}$", *o.AccountID); !ok {
		return NewFlagError(UsageAccountID)
	}
	// Adwords API version support.
	if ok, _ := regexp.MatchString("^v[0-9]{6}$", *o.APIVersion); !ok {
		return NewFlagError(UsageAPIVersion)
	}
	// Authenticate credentials.
	if *o.AccessToken != "" && *o.DeveloperToken == "" {
		return NewFlagError(UsageDeveloperToken)
	}
	if *o.AccessToken == "" && *o.DeveloperToken != "" {
		return NewFlagError(UsageAccessToken)
	}
	return nil
}

// Parse parses the command-line flags from os.Args[1:]
// It returns an instance of Flag.
func Parse() *Flag {
	opts := &Flag{}
	// Google Adwords account ID.
	opts.AccountID = flag.String("i", "", UsageAccountID)
	// Google OAuth access token.
	opts.AccessToken = flag.String("T", "", UsageAccessToken)
	// Google OAuth developer token.
	opts.DeveloperToken = flag.String("D", "", UsageDeveloperToken)
	// Google Adwords API version.
	opts.APIVersion = flag.String("V", awql.APIVersion, UsageAPIVersion)
	// Awql query (non interactive use).
	opts.Query = flag.String("e", "", UsageQuery+", disables interactive use")
	// Disables automatic rehashing.
	opts.NoRehash = flag.Bool("A", false, "Disables automatic rehashing")
	// Enables batch mode.
	opts.Batch = flag.Bool("B", false, "Enables printing of results using comma as the column separator")
	// Supports zero impressions
	opts.ZeroImpressions = flag.Bool("z", false, "Enables fetching of reports with the support of zero impressions")
	// Verbose mode.
	opts.Verbose = flag.Bool("v", false, "Enables verbose mode")
	// Data caching.
	opts.Caching = flag.Bool("c", false, "Enables data caching")
	// Parses the command-line flags.
	flag.Parse()

	return opts
}

// Usage prints a usage message documenting all defined command-line flags.
func Usage() {
	flag.Usage()
}
