# bash-packages

## Package array

* Function arrayDiff ( array haystack1, array haystack2 ) array `?=0`
* Function arrayKeyExists ( string needle, array haystack1) void  `?=0 if needle exists as key in array, 1 otherwise`
* Function arrayMerge ( array haystack1, array haystack2 ) array `?=0`
* Function arraySearch ( string needle, array haystack ) mixed `?=0 if needle is found, 1 otherwise`
* Function arrayToString ( string arrayDeclaration ) string `?=0`
* Function count ( mixed value ) int `?=0`
* Function inArray ( string needle, array haystack ) void `?=0 if needle is found, 1 otherwise`


## Package database/mysql

> The mysql command is mandatory for this package
> The mysqldump command is mandatory only for the method named mysqlDump

* Function mysqlAffectedRows ( int resultLink ) int `?=0`
* Function mysqlClose ( int databaseLink ) void `?>0 If database link does not exist`
* Function mysqlConnect ( string host, string user, string pass, string database [ , int connectTimeout 0, int cached 0 ] ) int `?=2 If mysql command does not exist, 1 in case of error, 0 otherwise`
* Function mysqlDump ( int databaseLink [ , string table, string options ] ) string `?=2 If mysqldump command does not exist, 1 in case of error, 0 otherwise`
* Function mysqlEscapeString ( string str ) string `?=0`
* Function mysqlLastError ( int databaseLink ) string `?=0`
* Function mysqlLoad ( int databaseLink, string filePath ) void `?=2 If mysql command does not exist, 1 in case of error, 0 otherwise`
* Function mysqlFetchAll ( int databaseLink, string query [ , string options[ "raw", "num", "assoc" ] "num" ] ) string `?>0 In case of error`
* Function mysqlFetchAssoc ( int databaseLink, string query ) string `?>0 In case of error`
* Function mysqlFetchArray ( int databaseLink, string query ) string `?>0 In case of error`
* Function mysqlFetchRaw ( int databaseLink, string query ) string `?>0 In case of error`
* Function mysqlNumRows ( int resultLink ) int `?=0`
* Function mysqlOption ( int databaseLink, string name, mixed value ) void `?>0 In case of error`
* Function mysqlQuery ( int databaseLink, string query ) int `?>0 In case of error`


## Package encoding/yaml

* Function yamlDecode ( string str ) array `?>0 In case of error`
* Function yamlEncode ( array str ) string `?>0 In case of error`
* Function yamlFileDecode ( string filePath ) array `?>0 In case of error`
* Function yamlFileEncode ( string str, string filePath ) void `?>0 In case of error`


## Package encoding/base64

> The base64 command is mandatory for this package

* Function base64Decode ( string str ) string `?=2 If base64 method does not exist, 1 in case of error, 0 otherwise`
* Function base64Encode ( string str ) string `?=2 If base64 method does not exist, 1 in case of error, 0 otherwise`


## Package file

* Function import ( ...string path ) void `?>0 If one of the list of file path does not exist`
* Function include ( string path [ , int onceMode 0 ] ) void `?>0 If file does not exist`
* Function includeOnce ( string path ) void `?>0 If file does not exist`
* Function physicalDirname ( string path ) string `?>0 If directory does not exist`
* Function realpath ( string path ) string `?>0 If file does not exist`
* Function resolvePath ( [ string path, string sourceDir ] ) string  `?=0`
* Function scanDirectory ( string path [ , int withFile 0, int completePath 0 ] ) string `?>0 If directory does not exist`
* Function userHome ( ) string `?>0 In case of error`


## Package log

By default, log will not be prefixed by the date and time or level. You can override it by using appropriate methods.
You can also add your own prefix by using the method named `logUsePrefix`.

* Function logIsMuted ( ) void `?=0 if log methods are disabled, 1 otherwise`
* Function logMute ( int enable ) void `?=0`
* Function logPrefix ( ) string `?=0`
* Function logUsePrefix ( string prefix ) void `?=0`
* Function logUseDateTime ( int enable ) void `?=0`
* Function logUseLevel ( int enable ) void `?=0`
* Function logWithDateTime ( ) void `?=0 if each log are prefixed by datetime, 1 otherwise`
* Function logWithLevel ( ) void `?=0 if each log are prefixed by level, 1 otherwise`

## Package log/print

> Print on default output

* Function pInfo ( string str ) string `?=0`
* Function pInfoF ( string formatstr [, ...string args ] ) string `?>0 If the print datas does not match with the formatstring`
* Function pWarn ( string str ) string `?=0`
* Function pWarnF ( string formatstr [, ...string args ] ) string `?>0 If the print datas does not match with the formatstring`
* Function pError ( string str ) string `?=0`
* Function pErrorF ( string formatstr [, ...string args ] ) string `?>0 If the print datas does not match with the formatstring`
* Function pFatal ( string str ) string `#=1`
* Function pFatalF ( string formatstr [, ...string args ] ) string `#=1`

## Package log/file

> Write into a file

* Function wInfo ( string filepath, string str ) void `?>0 In case of error for writing into file`
* Function wInfoF ( string filepath, string formatstr [ , ...string args ] ) void `?>0 In case of error for writing into file`
* Function wWarn ( string filepath, string str ) void `?>0 In case of error for writing into file`
* Function wWarnF ( string filepath, string formatstr [ , ...string args ] ) void `?>0 In case of error for writing into file`
* Function wError ( string filepath, string str ) void `?>0 In case of error for writing into file`
* Function wErrorF ( string filepath, string formatstr [ , ...string args ] ) void `?>0 In case of error for writing into file`
* Function wFatal ( string filepath, string str ) void `#>0 In case of error for writing into file`
* Function wFatalF ( string filepath, string formatstr [ , ...string args ] ) void `?>0 In case of error for writing into file`


## Package math

> The bc command is not mandatory for this package, but used if exists

* Function decimal ( mixed value ) int `?>0 In case of error`
* Function int ( mixed value ) int `?>0 In case of error`
* Function isFloat ( mixed value ) void `?=0 if it is a float value, 1 otherwise`
* Function isInt ( mixed value ) void `?=0 if it is a integer value, 1 otherwise`
* Function isNumeric ( mixed value ) void `?=0 if it is a numeric value, 1 otherwise`
* Function isFloatGreaterThan ( float var1, mixed var2 ) void `?=0 if var 1 is lower, 1 otherwise`
* Function isFloatLowerThan ( float var1, mixed var2 ) void `?=0 if var 1 is greater, 1 otherwise`
* Function floor ( float value ) int `?>0 If value is not a number`
* Function numericType ( mixed Str ) string[ "integer", "float", "unknown" ] `?=0`
* Function rand ( ) int `?=0`


## Package net

* Function parseUrl ( string url ) array `?>0 If Url is empty or invalid`


## Package strings

* Function checksum ( string str ) int `?>0 In case of error`
* Function isEmpty ( string str ) `?=0 if not empty, 1 if empty`
* Function printLeftPadding ( string str, int padLength [ , string padChar ] ) string `?=0`
* Function printRightPadding ( string str, int padLength [ , string padChar ] ) string `?=0`
* Function trim ( string str [ , string charToMask ] ) string `?=0`


## Package term

* Function confirm ( string message [ , string extendedMessage ] ) void `?=0 for yes, 1 for no`
* Function dialog ( string message [ , int mandatory 1, string mandatoryMessage ] ) string `?=0`
* Function progressBar ( string name, int step, int max, [ , string error "An error occured", int width 20, string charEmpty -, string charFilled + ] ) string `?>0 In case of error`
* Function windowSize ( [ string type ] ) int | array `?>0 If stty size method returns in error`


## Package testing

* Function bashUnit ( string name, string expected, string received ) string `?>0 If one of the three parameters are empty`
* Function launchAllTests ( string directory ) string `?=0`


## Package time

* Function timestamp ( ) int `?>0 If date method does not exists`
* Function timeTodo ( string command ) array `?>0 In case of error`
* Function userTimeTodo ( string command ) float `?>0 In case of error`
* Function isUserTimeTodoExceeded ( string command, float duration ) void `?=0 if time not exceeds, 1 otherwise`
* Function utcDateTimeFromTimestamp ( int timestamp ) string `?>0 In case of error`
* Function timestampFromUtcDateTime ( string utcDatetime ) int `?>0 In case of error`