#-------------------------------------------------------------------------------------------------------------------------
# Author: Christian Boerner (https://github.com/CB79)
# License: none
# Version: 1.4
# Changelog:
#   1.0  Initial
#   1.1  More generic functionality for log function
#   1.2  Additional functions to increase or reduce loglevel
#   1.3  More flexible log levels
#   1.4  Auto detect loglevels from callers and add them to message
#-------------------------------------------------------------------------------------------------------------------------


## Loglevel information:
#	0 = fail, 1 = error, 2 = warn, 3 = info (default), 4 = debug, 5 = trace, 6 = ultra (set -x)
declare -a LOGLEVELS
LOGLEVELS=(fail error warn info debug trace ultra)
LOGLEVEL=${LOGLEVEL:-3}

## Some default values - do not change them...
QUIET=${QUIET:-false}		     # enable/disable logging to stdout
TRACE_SHOW_STACK=${TRACE_SHOW_STACK:-on}

DATE_FORMAT=${DATE_FORMAT:-'%F %T'}

function increaseLoglevel() {
	[ $LOGLEVEL -lt $(expr ${#LOGLEVELS[@]} - 1 ) ] && let LOGLEVEL++
	[ $LOGLEVEL -ge $(expr ${#LOGLEVELS[@]} - 1 ) ] && set -x
}

function decreaseLoglevel() {
	[ $LOGLEVEL -gt 0 ] && let LOGLEVEL--
	[ $LOGLEVEL -lt ${#LOGLEVELS[@]} ] && set +x
}

# General logging function
# Usage: <func> "<message>" [<logFile>]
# Note: logFile defaults to /dev/null if no logfile is mentioned or configured globally ($LOGFILE)
function log() {
	TIMESTAMP="$(date +"${DATE_FORMAT}")"
	PREFIX="${TIMESTAMP}|"
	## Get name of the caller function and use it as log level name. :o)
	LEVEL="$( printf "%-5s" ${FUNCNAME[1]^^} )"
	## If we find the name of a log level then we insert it into the message. Otherwise we only add the timestamp.
	if  $(echo "${LOGLEVELS[@]}" | grep -qi "\b${LEVEL}\b"); then
		PREFIX+="${LEVEL}|"
	fi
	MSG="${PREFIX}${1}"
	MY_LOG=${2:-${LOGFILE}}
	MY_LOG=${MY_LOG:-/dev/null} # redirect to /dev/null if neither a custom log nor a global log is defined

	## Add call stack to log message if the message was issued by fail or debug
	case "${FUNCNAME[1]}" in
		error|fail)	
			for (( i=2; i < ${#FUNCNAME[@]}; i++)) do
				MSG="$MSG\n${PREFIX}\tcaused by ${FUNCNAME[$i]} (${BASH_SOURCE[$i]}:${BASH_LINENO[$i-1]})"
			done
			;;
		trace)
			## Set stack limit to maximum when on or off when off 
			if [[ "${TRACE_SHOW_STACK,,}" =~ ^on$ ]]; then
				local TRACE_STACK=${#FUNCNAME[@]}
			elif [[ "${TRACE_SHOW_STACK,,}" =~ ^off$ ]]; then
				local TRACE_STACK=0
			else
				local TRACE_STACK=${TRACE_SHOW_STACK:-0}
			fi
			for (( i=2; i < ${#FUNCNAME[@]}; i++)) do
				[ $TRACE_STACK -le 0 ] && break
				MSG="$MSG\n${PREFIX}\tcaused by ${FUNCNAME[$i]} (${BASH_SOURCE[$i]}:${BASH_LINENO[$i-1]})"
				let TRACE_STACK--
			done
			;;
	esac

	# special handling of stderr because tee does not handle it itself
	if ! $QUIET; then
		if [ "${FUNCNAME[1]}" == "fail" ]; then
			echo -e "$MSG" >&2
			echo -e "$MSG" >> $MY_LOG
		else
			echo -e "$MSG" | tee -a $MY_LOG
		fi
	else
		# Logging only to log in quiet mode
		echo -e "$MSG" >> $MY_LOG
	fi
}

# Function to echo out a failure message and exit with errorcode
# Usage: <func> <errCode> <Message>
function fail() {
	[ $# -lt 2 ] && fail 255 "Invalid usage of function $FUNCNAME (Message was \"$FUNCNAME $@\")";
	ERR_CODE=$1; shift
	log "${@} (ErrorCode: $ERR_CODE)"
	exit $ERR_CODE
}

# Error function, same as fail but without the exit and call stack
function error() {
	[ ${LOGLEVEL} -lt 1 ] && return
	[ $# -lt 2 ] && fail 255 "Invalid usage of function $FUNCNAME (Message was \"$FUNCNAME $@\")";
	ERR_CODE=$1; shift
	log "${@} (ErrorCode: $ERR_CODE)"
}

# Warn function, prepends WARN to the message but rest is normal logging
function warn() {
	[ ${LOGLEVEL} -lt 2 ] && return
	log "${@}"
}

# Info function, prepends INFO to the message but rest is normal logging
function info() {
	[ ${LOGLEVEL} -lt 3 ] && return
	log "${@}"
}

# Debugging function. Checks if a debug flag is set and routes to logging if so.
function debug() {
	[ ${LOGLEVEL} -lt 4 ] && return
	log "$@";
}

# Tracing function. Checks if a trace flag is set and routes to logging if so.
function trace() {
	[ ${LOGLEVEL} -lt 5 ] && return
	log "$@"
}

## Check is Bash version is new enough
if [ -z "${BASH_VERSION}" ] || [ ${BASH_VERSION%%.*} -lt 4 ]; then
	echo "Bash 4.* or later is required to run this functions."
	exit 1
fi

