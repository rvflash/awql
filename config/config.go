package config

import (
	"os"
	"os/user"
	"path/filepath"

	"github.com/rvflash/awql/driver"
)

type Options interface {
	AccountId() string
	ApiVersion() string
	ExecuteStmt() string
	IsInteractive() bool
	SupportsZeroImpressions() bool
	UseBatchMode() bool
	UseVerboseMode() bool
	WithAutoRehash() bool
	WithCache() bool
}

type Config interface {
	Options
	Dsn() string
	CacheDir() string
	DatabaseDir() string
	HistoryFile() string
	Init() error
}

// Settings represents the program properties.
type Settings struct {
	homeDir string
	tk      *Credentials
	opts    *Flag
}

// NewCredentials returns an instance of Credentials.
func New() *Settings {
	return &Settings{opts: Parse()}
}

// AccountId returns the Account ID.
func (c *Settings) AccountId() string {
	return *c.opts.AccountId
}

// AccountId returns the API version.
func (c *Settings) ApiVersion() string {
	return *c.opts.ApiVersion
}

// CacheDir returns the path to store cache files.
func (c *Settings) CacheDir() string {
	if c.homeDir == "" {
		return ""
	}
	return filepath.Join(c.homeDir, "cache")
}

// DatabaseFile returns the path to the database.
func (c *Settings) DatabaseDir() string {
	dir, err := filepath.Abs("vendor/github.com/rvflash/awql-db")
	if err != nil {
		return ""
	}
	return dir
}

// Dsn outputs the data source name.
func (c *Settings) Dsn() string {
	// Data source name used to connect to Adwords.
	dsn := driver.NewDsn(c.AccountId(), c.DatabaseDir())
	dsn.ApiVersion = c.ApiVersion()
	dsn.SupportsZeroImpressions = c.SupportsZeroImpressions()
	dsn.WithCache = c.WithCache()

	// Credentials to authenticate.
	dsn.AccessToken = c.tk.AccessToken
	dsn.ClientId = c.tk.ClientId
	dsn.ClientSecret = c.tk.ClientSecret
	dsn.DeveloperToken = c.tk.DeveloperToken
	dsn.RefreshToken = c.tk.RefreshToken

	return dsn.String()
}

// ExecuteStmt returns the statement to execute.
func (c *Settings) ExecuteStmt() string {
	return *c.opts.Query
}

// HistoryFilePath returns the path to the history file.
func (c *Settings) HistoryFile() string {
	if c.homeDir == "" {
		return ""
	}
	return filepath.Join(c.homeDir, "history")
}

// Set retrieves and saves the default authenticate information.
func (c *Settings) Init() error {
	// Checks for required flags.
	if err := c.opts.Check(); err != nil {
		return err
	}
	// Create the tool home directory.
	if err := c.mkDirHome(); err != nil {
		return err
	}
	// Checks credential to authenticate to Adwords.
	switch {
	case *c.opts.AccessToken != "":
		// Use temporary credential.
		c.tk = NewTmpCredentials(*c.opts.AccessToken, *c.opts.DeveloperToken)
	case !c.useDefaultAuth():
		// Aks authenticate credentials to user.
		c.tk = AskCredentials()
		if err := c.tk.Save(c.filePath()); err != nil {
			return err
		}
	default:
		// Get authenticate credentials from configuration file.
		c.tk = NewCredentials()
		if err := c.tk.Get(c.filePath()); err != nil {
			return err
		}
	}
	return nil
}

// IsInteractive returns true if query as passed as flag.
func (c *Settings) IsInteractive() bool {
	return *c.opts.Query == ""
}

// SupportsZeroImpressions returns true if the support of zero impressions is enable.
func (c *Settings) SupportsZeroImpressions() bool {
	return *c.opts.ZeroImpressions
}

// UseBatchMode returns true if raw mode is required.
// It will print results using colon as the column separator,
// with each row on a new line.
func (c *Settings) UseBatchMode() bool {
	return *c.opts.Batch
}

// UseVerboseMode returns true if more output about what the program does is required.
func (c *Settings) UseVerboseMode() bool {
	return *c.opts.Verbose
}

// WithAutoRehash returns true if automatic rehashing is enable.
func (c *Settings) WithAutoRehash() bool {
	return !*c.opts.NoRehash
}

// WithCache returns true if the cache is enable.
func (c *Settings) WithCache() bool {
	return *c.opts.Caching
}

// filePath returns the path to the config file.
func (c *Settings) filePath() string {
	if c.homeDir == "" {
		return ""
	}
	return filepath.Join(c.homeDir, "config")
}

// mkDirHome creates if not already exists the home directory.
func (c *Settings) mkDirHome() error {
	if c.homeDir != "" {
		// Directory already made.
		return nil
	}
	// Gets user properties.
	usr, err := user.Current()
	if err != nil {
		return err
	}
	// If not exists, create the home directory of Awql tool.
	path := filepath.Join(usr.HomeDir, ".awql")
	if _, err := os.Stat(path); os.IsNotExist(err) {
		if err := os.Mkdir(path, os.ModePerm); err != nil {
			// Unable to create directory: .awql
			return err
		}
		c.homeDir = path

		if err := os.Mkdir(c.CacheDir(), os.ModePerm); err != nil {
			// Unable to create directory: .awql/cache
			return err
		}
	} else {
		c.homeDir = path
	}
	return nil
}

// Valid returns true if the config file exists.
func (c *Settings) useDefaultAuth() bool {
	if c.homeDir == "" {
		return false
	}
	// Checks if config file exists.
	_, err := os.Stat(c.filePath())

	return err == nil
}
