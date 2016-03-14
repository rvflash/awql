#!/usr/bin/env bash

# Reset color
declare -r BP_ASCII_COLOR_OFF='\033[0m'

# Foreground colors
declare -r BP_ASCII_COLOR_RED='\033[0;31m'
declare -r BP_ASCII_COLOR_IRED='\033[0;91m'
declare -r BP_ASCII_COLOR_GREEN='\033[0;32m'
declare -r BP_ASCII_COLOR_YELLOW='\033[0;33m'
declare -r BP_ASCII_COLOR_BLUE='\033[0;34m'
declare -r BP_ASCII_COLOR_GRAY='\033[0;90m'

# Background colors
declare -r BP_ASCII_COLOR_RED_BG='\033[101m'
declare -r BP_ASCII_COLOR_GREEN_BG='\033[42m'

# Reset current line
declare -r BP_ASCII_RESET_LINE='\r\033[[K'

# Move cursor
declare -r BP_ASCII_CURSOR_POS='\r\033[%sC'