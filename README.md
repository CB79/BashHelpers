# BashHelpers

This repository contains shell scripts with functions that can directly be sourced within other Bash scripts.

## logger.sh
Provides simple logging functions.

### Loglevels:
fail, error, warn, info, debug, trace, ultra

Default: info

All loglevels except ultra have a function with the same name. For usage see the example below.

All log messages issued are prepended with a capitalized loglevel and timestamp separated by "|"

Special Loglevels: 
* ultra: is mostly the same as trace but sets "set -x".
* error, fail:
  * require an additional numeric argument as first parameter.
  * the numeric argument represents the error code and will be appended to the log message in brackets: (e.g. "ErrorCode: 123")
  * the fail function will exit the script with the same return code
  * both functions will print the call stack which caused the message
* trace:
  * When TRACE_SHOW_STACK is turned on then the call stack is printed in addition to the log message.
  * on = the complete stack is printed
    off = stack printing is turned off
    number (e.g. TRACE_SHOW_STACK=5) = the call stack is printed until the 5th level (mostly useful for very deep call hierarchies)

### Environment parameters:
* LOGFILE: Full path and name of the logfile. If unset no logfile is written.
* TRACE_SHOW_STACK: takes the values "on", "off" or a number. See "Special Loglevels".
  * on (default) = the complete stack is printed
  * off = stack printing is turned off
  * number = the call stack is printed until the 5th (if set to 5) level (mostly useful for very deep call hierarchies)
* QUIET: Disable logging to stdout/stderr - useful when combined with a LOGFILE
  * on = console logging disabled
  * off (default) = console logging enabled
* DATE_FORMAT: contains the format string of the logging timestamp. (default: "%F %T")

### Misc Functions:
* increaseLoglevel - raise maximum log level
* decreaseLoglevel - lower maximum log level
* log              - the main routine, should mostly not be called directly

### Misc
The script requires Bash v.4 or newer

### Usage
```bash
#!/bin/bash
source logger.sh

function subfunction1() {
  subfunction2
}

function subfunction2() {
  trace "We are within subfunction2"
}

info "Welcome to logger.sh"

# Increase log level from info to debug
increaseLoglevel

# Increase log level once again (to trace)
increaseLoglevel

# Issue a trace message in main script
trace "Test message for tracing"
# Issue a trace message in a subfunction
subfunction1

# Decrease log level down to info
decreaseLoglevel
decreaseLoglevel

# An error message
error 66 "This is an error"
fail 99 "We will fail here"
info "This can never be reached"
```

*Result:*
```shell
2018-05-31 13:54:04|INFO |Welcome to logger.sh
2018-05-31 13:54:04|TRACE|Test message for tracing
2018-05-31 13:54:04|TRACE|      caused by main (./test.sh:24)
2018-05-31 13:54:04|TRACE|We are within subfunction2
2018-05-31 13:54:04|TRACE|      caused by subfunction2 (./test.sh:11)
2018-05-31 13:54:04|TRACE|      caused by subfunction1 (./test.sh:7)
2018-05-31 13:54:04|TRACE|      caused by main (./test.sh:26)
2018-05-31 13:54:04|ERROR|This is an error (ErrorCode: 66)
2018-05-31 13:54:04|ERROR|      caused by main (./test.sh:33)
2018-05-31 13:54:04|FAIL |We will fail here (ErrorCode: 99)
2018-05-31 13:54:04|FAIL |      caused by main (./test.sh:35)
```

