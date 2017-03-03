package conf

import (
	"bufio"
	"errors"
	"fmt"
	"io/ioutil"
	"os"
	"strings"

	"gopkg.in/yaml.v2"
)

// Credentials represents all information required to authenticate to Google API.
type Credentials struct {
	AccessToken,
	DeveloperToken,
	ClientID,
	ClientSecret,
	RefreshToken string
}

// NewCredentials returns an instance of Credentials.
func NewCredentials() *Credentials {
	return &Credentials{}
}

// NewTmpCredentials returns an instance of Credentials with limited time.
func NewTmpCredentials(access, developer string) *Credentials {
	return &Credentials{
		AccessToken:    access,
		DeveloperToken: developer,
	}
}

// AskCredentials retrieves authenticate properties from console.
func AskCredentials() *Credentials {
	// Welcome to the process to install Awql.
	fmt.Println("Thanks for using the Awql Command-Line Tool.")
	fmt.Println("Take a moment to save the default authentication credentials used to sign in to Google Adwords API.")

	// Asks authentication credentials.
	reader := bufio.NewReader(os.Stdin)
	o := NewCredentials()
	o.DeveloperToken = ask(reader, "Your Google developer token: ")
	o.ClientID = ask(reader, "Your Google client ID: ")
	o.ClientSecret = ask(reader, "Your Google client secret: ")
	o.RefreshToken = ask(reader, "Your Google refresh token: ")

	return o
}

// Get returns  it in Yaml format in the file to this path.
func (o *Credentials) Get(path string) error {
	if path == "" {
		return errors.New("ToolError.INVALID_CONFIG_PATH")
	}
	data, err := ioutil.ReadFile(path)
	if err != nil {
		return err
	}
	return yaml.Unmarshal([]byte(data), o)
}

// Save writes it in Yaml format in the file to this path.
func (o *Credentials) Save(path string) error {
	if path == "" {
		return errors.New("ToolError.INVALID_CONFIG_PATH")
	}
	yml, err := yaml.Marshal(o)
	if err != nil {
		return err
	}
	return ioutil.WriteFile(path, yml, 0666)
}

// ask reads the term to return user response.
func ask(reader *bufio.Reader, text string) (resp string) {
	for {
		fmt.Print(text)
		resp, _ = reader.ReadString('\n')
		if resp = strings.TrimSpace(resp); resp != "" {
			break
		}
	}
	return resp
}
