#!/bin/bash

#UPDATE Version HERE:
Version=“0.1”


#######################################################################
# STANDARD HEADER
#######################################################################

# Filename:      Rabo2Ynab.sh
# Version:
# Author:        Jeroen van der Wal
#-----------------------------------------------------------------
# To Do
#
#-----------------------------------------------------------------

# Variables
Home="/Users/jeroen"
LogDir="${Home}/log"
ScriptSelf=$(basename "$0")
FilePathCurrent="${Home}/Downloads"
FilePathNew="${Home}/tmp"
CurrentFile="CSV_A_$(date +%Y%m%d)*"
NewFile="YNAB_Lopend$(date +"%Y%m%d%H%M")_rabo.csv"
UBSMAI="jjjvdw@outlook.com"


# Mail variables
SendGlobalMail="no"                               # Send mail to functional support etc?
SendBeheerMail="yes"                              # Send mail to ops support?
SENDMAILATTACHEMENT="no"                          # Are there attachments to be send?

# Logging variables
LogLevel="DEBUG"                                  # LogLevel for the _LogWrite function. Determines when to log
ScriptLogFile="${LogDir}/$(basename "$0" .sh)$(date +%Y%m%d).log"       # where to write logging from _LogWrite
AuditLogFile="${LogDir}/$(basename "$0" .sh)$(date +%Y%m%d)_Audit.log"  # Where to write audit logging

# Load the environment variables
ApplProfile="${Home}/.bash_profile"
. ${ApplProfile} > /dev/null 2>&1

###############################################################################
# Standard functions
###############################################################################

# Get desired loglevel from config file
case ${LogLevel} in
   CRITICAL) LLNumeric=2 ;;
       CRIT) LLNumeric=2 ;;
      ERROR) LLNumeric=3 ;;
       WARN) LLNumeric=4 ;;
    WARNING) LLNumeric=4 ;;
       INFO) LLNumeric=5 ;;
      DEBUG) LLNumeric=6 ;;
          *) LLNumeric=4
       _LogWrite W "Unknown LogLevel setting: ${LogLevel} . Setting LogLevel WARN."
       ;;
esac

#-----------------------------------------------------------------
# Procedure:     _LogWrite
# Prerequisites: N.A.
#
# Purpose:       Write logging to logfile, if MsgLogLevel is ERROR or CRITICAL, exit the script
# Parameters:    $1 = MsgLogLevel (Audit, Error, Warn, etc)
#                $2 = Log message
#------------------------------------------------------------------

# log write function
_LogWrite (){
FunctionName=${FUNCNAME[1]}
LogMessage="$2"
MsgLogLevel=$1

  case ${MsgLogLevel} in
    A | AUDIT) ValLogLevel=1; echo "$(date '+%Y%m%d:%H:%M:%S')" "${ScriptSelf}" "${MsgLoglevel}" "${FUNCNAME[1]}"  "$@" >> ${AuditLogFile} ;;
    C | CRITICAL) ValLogLevel=2 ;;
    E | ERROR) ValLogLevel=3 ;;
    W | WARN) ValLogLevel=4 ;;
    I | INFO) ValLogLevel=5 ;;
    D | DEBUG) ValLogLevel=6 ;;
    *) ValLogLevel=1 ;;  #All other options - always write to log.
  esac

  #_Vprint "${FUNCNAME[1]}" "$@" # If verbose is true print the _LogWrite statement

  if [ ${ValLogLevel} -le ${LLNumeric} ]; then # Audit goes to both the audit and the standard log
    echo "$(date '+%Y%m%d:%H:%M:%S')" "${ScriptSelf}" "${MsgLoglevel}" "${FunctionName}" "${LogMessage}" >> ${ScriptLogFile}
  fi

  #Prog end if script has a critical or error value message.
  if [ ${ValLogLevel} -eq 2 -o ${ValLogLevel} -eq 3 ]; then
    echo "$(date '+%Y%m%d:%H:%M:%S')" "${ScriptSelf}" "${MsgLoglevel}" "Exiting script" >> ${ScriptLogFile}
    _Cleanup 1
    exit 1
  fi

}

#-----------------------------------------------------------------
# Procedure:     _PreChecks
#
# Purpose:       Do some checks before running the script
# Parameters:    -
# Return Values: -
# PreReq:        _ComposeMail
#                _SendMail
#                _LogWrite
#------------------------------------------------------------------

_PreChecks(){
  # Check if the logdir exists
  if [[ ! -f "${HOME}/appl.conf" ]]; then
    _LogWrite ERROR "${HOME}/appl.conf doesn't exist, can't use this for the variables"
  fi

  # Check if the CurrentFile exists and is not empty
  if [[ ! -s "${FilePathCurrent}"/"${CurrentFile}" ]]; then
    _LogWrite ERROR "${FilePathCurrent}/${CurrentFile} doesn't exist or is empty, can't use this"
  fi

  # The checks of the newfile are different than normal because of the wildcard in the file name. You can't use -s in that case
  # Check if the NewFile exists
  if ! ls "${FilePathNew}"/${NewFile} 1> /dev/null 2>&1; then
      _LogWrite ERROR "${FilePathNew}/${NewFile} doesn't exist, can't use this"
  fi

  # Check if the NewFile is empty
  if [ $(ls -ltr "${FilePathNew}"/${NewFile} | tail -1 | awk '{print $5}') -eq 0 ]; then
      _LogWrite ERROR "${FilePathNew}/${NewFile} is empty, can't use this"
  fi
}

#-----------------------------------------------------------------
# Procedure:     _ComposeMail
#
# Purpose:       Compose the email after processing or if processing didn't finish in time
# Parameters:
# Return Values: -
#------------------------------------------------------------------

_ComposeMail(){

MailTopic=$1
MailBody=$2
  _LogWrite INFO "Composing the email boddy"
  _SendMail
}

#-----------------------------------------------------------------
# Procedure:     _SendMail
#
# Purpose:       Send the email with or without attachments, to beheer and if needed the business
# Parameters:
# Return Values: -
#------------------------------------------------------------------

_SendMail(){
    _LogWrite INFO "Sending the email"
  # If you only want to send a mail to beheer
  ToMail="${UBSMAI}"
  _MailExclAttach "${ToMail}"


}

#-----------------------------------------------------------------
#
# Procedure:     _MailExclAttach
#
# Purpose:       Send an email without attachments
# Parameters:    -
# Return Values: -
#------------------------------------------------------------------

_MailExclAttach(){
    _LogWrite INFO "Sending eamil"

MailTo=$1

  echo  "${MailBody}" | mailx -s "${MailTopic}" "${MailTo}"
    [[ $? -ne 0 ]] && _LogWrite ERROR "Mailing went wrong. Please check"
}

#-----------------------------------------------------------------
# Procedure:     _Cleanup
#
# Purpose:       Get all the information regarding this processing, from troughput time till processed records
# Parameters:    -
# Return Values: -
#------------------------------------------------------------------
_Cleanup(){
ExitCode=$1

  if [ ${ExitCode} -eq 0 ]; then
    rm -f "${NewFile}"
      [[ $? -ne 0 ]] && _LogWrite WARN "Couldn't cleanup ${NewFile}"
      _LogWrite INFO "Removed ${NewFile}"
  fi
}


# usage function
_PrtUsage()
{
cat<< EOT
    $ScriptSelf
    --currentfilename -c                     OPTIONAL, change the name of the current file Default: "${CurrentFile}"
    --newfile -n                             OPTIONAL, change the name of the current file Default: "${NewFile}"
    --currentdir -u                          OPTIONAL, change the directory where the current file is in Default: "${FilePathCurrent}"
    --newdir -e                              OPTIONAL, change the directory where the new file is in Default: "${FilePathNew}"
    --help -h                                this overview
EOT
exit 0
}

# Add a first row into the file as expected
_FirstRow(){
  File="$1"

  _LogWrite INFO "Adding the header that is expected by YNAB"
	sed -i '1i\Date,Payee,Category,Memo,Outflow,Inflow' "${File}"
  [[ $? -ne 0 ]] && _LogWrite ERROR "Couldn't add the header to ${File}"

  _EndMessage
}

_EndMessage(){
	echo "je bestand staat in de Temp directory"
	ls -ltr "${FilePathNew}/${NewFile}"*
}

# met onderstaande komt het gedownloade document (transactions.txt in het formaat dat YNAB verwacht (Date,Payee,Category,Memo,Outflow,Inflow)
# Het eerste gedeelte (-F etc) geeft aan dat het comma seperated is
# Vervolgens gaat hij kijken of het vierde veld een D is, als in Debet, outflow. Als dat zo is moet hij het bedrag in het op een na laatste veld zetten
# Anders in het laatste veld. Zie ook het formaat van YNAB ,Outflow,Inflow. Dit moet zo omdat het bestand van de bank per regel is, en niet outflow in een kolom en inflow in een kolom
# de print substr zorgt ervoor dat de dateformat staat zoals YNAB het verwacht, namelijk DD/MM/YYYY
_Rabobank(){
  _LogWrite INFO "Getting the right columns for the new YNAB file" #TODO dese awk levert nog niet de juiste payee op.
  awk -F'"' -v OFS='' '{ for (i=2; i<=NF; i+=2) gsub(",", ".", $i) } 1' "${FilePathCurrent}"/"${CurrentFile}" |\
  awk -F "\"*,\"*" '{
	if ($7 ~ /-/)
		print substr($5,6,2)"/"substr($5,9,2)"/"substr($5,0,4)","$10 " - " $11 " - " $20",,"$20","$7",";
	else
		print substr($5,6,2)"/"substr($5,9,2)"/"substr($5,0,4)","$10 " - " $11 " - " $20",,"$20",,"$7;}' | \
    tail -n +2 | sed 's/\+//g' | sed 's/\-//g' | sed 's/@@/\,/g' > "${FilePathNew}"/"${NewFile}" #TODO deze sed is nog niet helemaal goed.
  [[ $? -ne 0 ]] && _LogWrite ERROR "Couldn't awk the ${CurrentFile} and write it to ${NewFile}"
	_FirstRow "${FilePathNew}/${NewFile}"
}

#######################################################################
# PROCESS COMMANDLINE
#######################################################################
# Transform long options to short ones
for arg in "$@"; do
  shift
  case "$arg" in
    "--help")            set -- "$@" "-h" ;;
    "--currentfilename") set -- "$@" "-c" ;;
    "--newfile")         set -- "$@" "-n" ;;
    "--currentdir")      set -- "$@" "-u" ;;
    "--newdir")          set -- "$@" "-e" ;;
    "--idcolumn")        set -- "$@" "-i" ;;
    "--datecolumn")      set -- "$@" "-d" ;;
    "--excludecolumn")   set -- "$@" "-x" ;;
    *)                   set -- "$@" "$arg"
  esac
done

OPTIND=1
while getopts "c:n:u:e:h" opt
do
  case "$opt" in
    "h") _PrtUsage; exit 0 ;;                        # long and short option plus call a function
    "c") CurrentFile="${OPTARG}";;
    "n") NewFile="${OPTARG}";;
    "u") FilePathCurrent="${OPTARG}";;
    "e") FilePathNew="${OPTARG}";;
    "?") _PrtUsage >&2; exit 1 ;;
    ":") _PrtUsage >&2; exit 1 ;;
  esac
done
shift $(expr $OPTIND - 1)

#----------------------------------------------------------------
#
# Procedure:     MAIN
#
# Purpose:       Main program
# Parameters:    -
# Return Values: -
#----------------------------------------------------------------

_Rabobank
#_Cleanup 0
