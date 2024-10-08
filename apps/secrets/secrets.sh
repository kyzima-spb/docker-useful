#!/usr/bin/env sh
#FILE:secrets.sh

# Clears environment variables with a specific prefix.
# 
# Takes a single argument, VAR_PREFIX, which is used to identify
# the environment variables that should be cleared. Any environment variable whose name starts
# with the specified prefix followed by an underscore (_) will be unset.
# 
# If VAR_PREFIX is not provided, the function will output an error message to stderr and exit
# with a status code of 1.
# 
# Usage:
#   clearEnvironment VAR_PREFIX
#
# Parameters:
#   VAR_PREFIX - The prefix of the environment variables to be cleared. This parameter is required.
#
# Example:
#   # Assuming the environment contains the variables PREFIX_VAR1 and PREFIX_VAR2
#   # The following command will clear both of these variables
#   clearEnvironment PREFIX
#
# Exit Codes:
#   0 - Success
#   1 - Error due to missing VAR_PREFIX
clearEnvironment() {
    varPrefix="$1"

    test -z "$varPrefix" && echo >&2 "Variable prefix is required." && exit 1
    
    for name in $(printenv | grep "${varPrefix}_" | cut -d= -f1); do
        unset "$name"
    done
}


# Handles environment variables that can either be set directly or read from a file. 
# It ensures that only one method is used at a time and provides default values when necessary.
#
# Usage:
#   fileEnv VAR_NAME [DEFAULT_VALUE]
# 
# Parameters:
#   VAR_NAME - The name of the environment variable to be set.
#   DEFAULT_VALUE - A default value to use if neither the environment variable nor the file variable is set.
#
# Example 1: Direct Value
#   export MY_VAR="some_value"
#   fileEnv MY_VAR
#   echo $MY_VAR  # Output: some_value
#
# Example 2: Value from File
#   echo "file_value" > /path/to/my_var_file
#   export MY_VAR_FILE="/path/to/my_var_file"
#   fileEnv MY_VAR
#   echo $MY_VAR  # Output: file_value
#
# Example 3: Default Value
#   fileEnv MY_VAR "default_value"
#   echo $MY_VAR  # Output: default_value
#
# Example 4: Error on Both Values Set
#   export MY_VAR="some_value"
#   export MY_VAR_FILE="/path/to/my_var_file"
#   fileEnv MY_VAR
#   # Output: Both MY_VAR and MY_VAR_FILE are set (but are exclusive).
#   # Exits with status 1
#
# Example 5: Error on Missing Value
#   fileEnv MY_VAR
#   # Output: MY_VAR or MY_VAR_FILE require a value.
#   # Exits with status 1
fileEnv() {
    var="$1"
    fileVar="${var}_FILE"
    default="${2:-}"

    # for backwards compatibility with sh
    eval "local value=\$$var"
    eval "local secretPath=\$$fileVar"
    
  	if [ -n "$value" ] && [ -n "$secretPath" ]; then
        echo >&2 "Both $var and $fileVar are set (but are exclusive)."
        exit 1
  	fi

    if [ -n "$secretPath" ]; then
        value="$(cat "$secretPath")"
    fi
    
    if [ -z "$value" ]; then
        if [ $# -eq 1 ]; then
            echo >&2 "$var or $fileVar require a value."
            exit 1
        else
            value="$default"
        fi
    fi

    unset "$var"
    unset "$fileVar"
    
    export "$var"="$value"
}


usage() {
  program="$(basename "$0")"

  cat 1>&2 <<-ENDOFUSAGE
	Usage:
	  $program VAR_NAME [DEFAULT_VALUE]

	Arguments:
    VAR_NAME The name of the environment variable to be set.
    [DEFAULT_VALUE] A default value to use if neither the environment variable nor the file variable is set.

	Examples:
	  $program PASSWORD
	  $program PASSWORD 'very_secret_password'

	URL (https://kyzima-spb.github.io/docker-useful/apps/secrets/secrets.sh)
	ENDOFUSAGE
}


main() {
  if [ $# -lt 1 ]; then
    usage
    exit 1
  fi

  fileEnv "$@"
  eval "echo \$$1"
}


if grep '^#FILE:secrets.sh' "$0" > /dev/null 2>&1; then
  main "$@"
fi
