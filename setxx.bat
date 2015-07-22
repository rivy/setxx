@(echo '> nul ) &::' ) | out-null; @'
@:: ## emacs -*- tab-width: 4; coding: dos; mode: batch; indent-tabs-mode: nil; basic-offset: 2; -*- ## (jedit) :tabsize=4:mode=perl: ## (notepad++) vim: syntax=powershell : tabstop=4 : shiftwidth=2 : expandtab : smarttab : softtabstop=2 ## modeline ( see http://archive.is/djTUD @@ http://webcitation.org/66W3EhCAP )
@:: Copyright (c) 2015 Roy Ivy III (MIT license)
@setlocal
@echo off

set "__ME=%~n0"
set "__DEBUG_KEY=%__ME%"
::set "__DEBUG_KEY=%__DEBUG%"

set "__DEBUGGING="
if DEFINED __DEBUG (if /I "%__DEBUG%" == "%__DEBUG_KEY%" ( set "__DEBUGGING=1" ))

if DEFINED __DEBUGGING (
    echo %__ME%: DEBUG: [ %~nx0 ]
    )

:: require PowerShell (to self-execute)
call :$path_in_pathlist _POWERSHELL_exe powershell.exe "%PATH%;%SystemRoot%\System32\WindowsPowerShell\v1.0"
if NOT DEFINED _POWERSHELL_exe (
    echo %__ME%: ERROR: script requires PowerShell [see http://support.microsoft.com/kb/968929 {to download Windows Management Framework Core [includes PowerShell 2.0]}] 1>&2
    exit /b 1
    )

:: require temporary files (for sourcing in-process environment variables)
call :$tempfile __source "%__ME%.source" ".bat"
if DEFINED __source ( goto :TEMPFILE_FOUND )
echo %__ME%: ERROR: unable to open needed temporary file [make sure to set TEMP or TMP to an available writable temporary directory {try 'set TEMP=%%LOCALAPPDATA%%\Temp'}] 1>&2
exit /b -1
:TEMPFILE_FOUND
echo @:: TEMPORARY source/exec file [owner: "%~nx0"] > "%__source%"

:: execute self as PowerShell script [using an endlocal block to pass a clean environment]
( endlocal
setlocal
:: send the least interpreted/cleanest possible ARGS to PowerShell via the environment
set __ARGS=%*
if NOT "%__DEBUGGING%"=="" (
    echo %__ME%: DEBUG: __ARGS=%__ARGS%
    )
::call "%_POWERSHELL_exe%" -NoProfile -ExecutionPolicy unrestricted -Command "${__0}='%~f0'; ${__ME}='%__ME%'; ${__DEBUGGING}=[bool]('%__DEBUGGING%'); ${__SOURCE}='%__source%'; ${__INPUT} = @($input); ${__ARGS}=$env:__ARGS; Invoke-Expression $( '$input=${__INPUT};if (${__ARGS}){$args=@(Invoke-Expression $(\"echo -- \"+$(${__ARGS} -replace \"\$\",\"``$\" -replace \"``\",\"````\")))};'+[String]::Join([environment]::newline,$(Get-Content ${__0} | foreach { $_ })) )"
call "%_POWERSHELL_exe%" -NoProfile -ExecutionPolicy unrestricted -Command "${__0}='%~f0'; ${__ME}='%__ME%'; ${__DEBUGGING}=[bool]('%__DEBUGGING%'); ${__SOURCE}='%__source%'; ${__INPUT} = @($input); ${__ARGS}=$env:__ARGS -replace \"``\", \"````\" -replace \"\$\",\"``$\"; Invoke-Expression $( '$input=${__INPUT};if (${__ARGS}){$args=@(Invoke-Expression $(\"echo -- \"+${__ARGS}))};'+[String]::Join([environment]::newline,$(Get-Content ${__0} | foreach { $_ })) )"
:: restore needed ENV vars
set "__ME=%__ME%"
set "__DEBUGGING=%__DEBUGGING%"
set "__source=%__source%"
)
set "__exit_code=%ERRORLEVEL%"

( endlocal
    call "%__source%"
    (if NOT "%__DEBUGGING%"=="" (
        call echo %__ME%: DEBUG: "%__source%" exec [::START]
        call type "%__source%"
        call echo %__ME%: DEBUG: "%__source%" [::END]
        call echo %__ME%: DEBUG: [ %~nx0 ] :: end
        )
    )
    ( if "%__DEBUGGING%"=="" (
        call erase /q "%__source%" >NUL 2>NUL
        )
    )
    exit /b %__exit_code%
)
goto :EOF

::####

::
:$path_in_pathlist ( ref_RETURN FILENAME PATHLIST )
:: NOTE: FILENAME should be a simple filename, not a directory or filename with leading diretory prefix. CMD will match these more complex paths, but TCC will not
setlocal
set "pathlist=%~3"
set "PATH=%pathlist%"
set "_RETval=%~$PATH:2"
:$path_in_pathlist_RETURN
endlocal & set %~1^=%_RETval%
goto :EOF
::

::
:$tempfile ( ref_RETURN [PREFIX [EXTENSION]])
:: open a unique temporary file
:: RETURN == full pathname of temporary file (with given PREFIX and EXTENSION) [NOTE: has NO surrounding quotes]
:: PREFIX == optional filename prefix for temporary file
:: EXTENSION == optional extension (including leading '.') for temporary file [default == '.bat']
setlocal
set "_RETval="
set "_RETvar=%~1"
set "prefix=%~2"
set "extension=%~3"
if NOT DEFINED extension ( set "extension=.bat")
:: attempt to find a temp directory
if NOT EXIST "%temp%" ( set "temp=%tmp%" )
if NOT EXIST "%temp%" ( set "temp=%LocalAppData%\Temp" )
if NOT EXIST "%temp%" ( set "temp=NOT_FOUND" )
if NOT EXIST "%temp%" ( goto :$tempfile_RETURN )    &:: undefined TEMP, RETURN (with NULL result)
:$tempfile_find_unique_temp
set "_RETval=%temp%\%prefix%.%RANDOM%.%RANDOM%%extension%"
if EXIST "%_RETval%" ( goto :$tempfile_find_unique_temp )
:: instantiate tempfile [NOTE: this is an unavoidable race condition]
set /p OUTPUT=<nul >"%_RETval%"
:$tempfile_find_unique_temp_DONE
:$tempfile_RETURN
endlocal & set %_RETvar%^=%_RETval%
goto :EOF
::
goto :EOF
'@ | Out-Null

####

#"__0 = ${__0}" ## script full path
#"__ME = ${__ME}" ## name
#"__SOURCE = ${__SOURCE}" ## source filename
#"input = '"+($input -join ';')+"'" ## STDIN
#"args = '"+($args -join ';')+"'" ## ARGS
#"env:PATH = '"+$env:PATH+"'"

####

## set Environment variables

## NOTE: Review security issues @ [Running with Special Privileges] http://msdn.microsoft.com/en-us/library/windows/desktop/ms717802(v=vs.85).aspx @@ https://archive.is/FgTCX

## URLref: [Using PowerShell to determine your elevation status] http://theessentialexchange.com/blogs/michael/archive/2010/08/17/using-powershell-to-determine-your-elevation-status-uac.aspx @@ http://www.webcitation.org/66Slwinby @@ http://theessentialexchange.com/blogs/michael/archive/2010/08/17/using-powershell-to-determine-your-elevation-status-uac.aspx

#$__DEBUGGING=1

#### SUBs

Function dosify {
	# dosify( @ )
	# 'dosify' special characters ## double %'s for TCC
	if ($args -ne $null) {
		$args | ForEach-Object {
			$val = $_
			$val = $($val -replace '\(','^(')
			$val = $($val -replace '\)','^)')
			$val = $($val -replace '<','^<')
			$val = $($val -replace '>','^>')
			$val = $($val -replace '\|','^|')
			$val = $($val -replace '&','^&')
			$val = $($val -replace '"','^"')
			$val = $($val -replace '%','%%')
			$val
			}
		}
	}

#### SUBs.end

##"stdin = '"+($stdin -join ';')+"'";
##"input = '"+($input -join ';')+"'";

if (${__DEBUGGING}) {
	${__ME}+": DEBUG: "+[Environment]::CommandLine
	}

# some minimal command line parsing for options
## -- :: remove and no following options
## -m | --machine :: the persistent Machine environment (for all users, @ HKLM\System\CurrentControlSet\Control\Session Manager\Environment)
## -u | --user    :: the persistent User environment (@ HKCU\Environment)
## -p | --process :: the CMD shell environment

## -i | --invoke  :: execute/invoke VALUE, use the result as new VALUE
## -x | --exec    :: execute/invoke VALUE, use the result as new VALUE

if (${__DEBUGGING}) {
	${__ME}+": DEBUG: [ Initial ARGS ]"
    ${__ME}+": DEBUG: env:__ARGS=""${env:__ARGS}"" "
    ${__ME}+": DEBUG: __ARGS_=""${__ARGS_}"" "
    $x = ${env:__ARGS} -replace "\$","``$"
    ${__ME}+": DEBUG: env:__ARGS =>""${x}"" "
    ${__ME}+": DEBUG: iex( env:__ARGS =>""${x}"" ) => "
	$args | foreach { ${__ME}+": DEBUG: args_N=""$_""" }
	}

$out = ${__SOURCE}
#if ($out -eq $null) { $out = $stdout }

$optAndArgs = $args
$args_only = @()
for ( $i=0; $i -lt $args.Count; $i++ ) {
	if ($args[$i] -eq '--') {
		"args.Count=$($args.Count)"
		if ($i -eq 0) { $optAndArgs = @() }
		if ($i -gt 0) { $optAndArgs = $args[0..($i-1)] }
		$args_only = $args[($i+1)..($args.Count)];
		break
		}
	if (${__DEBUGGING}) {
		${__ME}+": DEBUG: args[$i]`:"+$args[$i]+":is(--)="+$($args[$i] -eq '--')
		}
	}

if (${__DEBUGGING}) {
	${__ME}+": DEBUG: [ Prelim ARGS Parse ]"
	$optAndArgs | foreach { ${__ME}+": DEBUG: optAndArgs_N=""$_""" }
	$args_only | foreach { ${__ME}+": DEBUG: args_only_N=""$_""" }
	}

$optAndArgs_orig = $optAndArgs;

$setInMachine = ( $optAndArgs -contains "-m" ) -or ( $optAndArgs -contains "--machine" ); $optAndArgs = $optAndArgs -ne "-m"; $optAndArgs = $optAndArgs -ne "--machine";
$setInProcess = ( $optAndArgs -contains "-p" ) -or ( $optAndArgs -contains "--process" ); $optAndArgs = $optAndArgs -ne "-p"; $optAndArgs = $optAndArgs -ne "--process";
$setInUser    = ( $optAndArgs -contains "-u" ) -or ( $optAndArgs -contains "--user" );    $optAndArgs = $optAndArgs -ne "-u"; $optAndArgs = $optAndArgs -ne "--user";

$displayENV = (( $optAndArgs.Count -eq 0 ) -and ( $args_only.Count -eq 0 ));

$evalVALUE = ( $optAndArgs -contains "-i" ) -or ( $optAndArgs -contains "--invoke" ) -or ( $optAndArgs -contains "-x" ) -or ( $optAndArgs -contains "--exec" );
$optAndArgs = $optAndArgs -ne "-i"; $optAndArgs = $optAndArgs -ne "--invoke";
$optAndArgs = $optAndArgs -ne "-x"; $optAndArgs = $optAndArgs -ne "--exec";

if ((-not $setInMachine) -and (-not $setInUser)) { $setInProcess = $true }

if (${__DEBUGGING}) {
	${__ME}+": DEBUG: setInMachine= $setInMachine";
	${__ME}+": DEBUG:    setInUser= $setInUser";
	${__ME}+": DEBUG: setInProcess= $setInProcess";
	${__ME}+": DEBUG:   displayENV= $displayENV";
	${__ME}+": DEBUG:    evalVALUE= $evalVALUE";
	}

$args = $optAndArgs + $args_only;

if (${__DEBUGGING}) {
	${__ME}+": DEBUG: [ Resultant ARGS ]";
	$args | foreach { ${__ME}+": DEBUG: arg_N=""$_""" }
	}

if ( $displayENV ) {
	## Display ENVs (print to output file, in the order of flags defined on the command line, seperated by empty lines; each ENV is only displayed once)

	if (${__DEBUGGING}) {
		${__ME}+": DEBUG: [ Display ENV ]";
		${__ME}+": DEBUG: optAndArgs_orig = $optAndArgs_orig"
		}

	## URLref: [Reading Registry Values] http://powershell.com/cs/blogs/tips/archive/2009/11/25/reading-registry-values.aspx @@ http://www.webcitation.org/66T2HB5ca
	## URLref: [Mastering PowerShell - The Registry] http://powershell.com/cs/blogs/ebook/archive/2009/03/30/chapter-16-the-registry.aspx @@ http://www.webcitation.org/66T2eNwjW
	## URLref: [Powershell - Working  with Registry Keys] http://technet.microsoft.com/en-us/library/dd315270.aspx @@ http://www.webcitation.org/66T15A6jC
	## URLref: [Powershell - Working Registry Entries] http://technet.microsoft.com/en-us/library/dd315394.aspx @@ http://www.webcitation.org/66T1EFWRT
	##
	## URLref: [PowerShell - Wide Tables] http://poshoholic.com/2010/11/11/powershell-quick-tip-creating-wide-tables-with-powershell
	##
	## URLref: [PowerShell.com - The PowerShell Pipeline] http://powershell.com/cs/blogs/ebook/archive/2008/11/23/chapter-5-the-powershell-pipeline.aspx

	## %ENV: has been changed with the addition of PowerShell changes ... need to do this in the calling BAT
	## - likely two alternate solutions: (1) stash the environment and send it to the script (?via temporary file), (2) send instructions back to the script to print it ("set" in the source file, plus echo's for the rest [to keep them in order])
	## 1) seems heavy-handed and inefficient for the occasional use to just display the usual environment
	##  * but might be needed to preserve the environment for EVALs (or need to inform the user that PowerShell make "dirty" the environment; they can avoid this by putting variables within the EVAL directly, using %VAR%)
	## 2) tricky, need to echo any displayed environments to the source_bat return file with adequate protection from shell interpretation of special characters (especially quotes, redirection/piping, command seperators, etc)

	$haveDisplayedPrior = $false;
	foreach ($token in $optAndArgs_orig) {
		if (${__DEBUGGING}) {
			${__ME}+": DEBUG: token = $token"
			}
		$output = @();
		if ( $setInProcess -and (( $token -eq "-p" ) -or ( $token -eq "--process" )) ) {
			# Process Environment
			if ( $haveDisplayedPrior ) {
				$output += "echo."
				}
			$output += "set"
			$setInProcess = $false;
			$haveDisplayedPrior = $true;
			}
		elseif ( $setInUser -and (( $token -eq "-u" ) -or ( $token -eq "--user" )) ) {
			# User Environment
			if ( $haveDisplayedPrior ) {
				$output += "echo."
				}
			# User level VARs in "hkcu:\Environment"
			foreach ($var in ( get-item "hkcu:\Environment").GetValueNames() | sort-object ) {
				$val = (get-item "hkcu:\Environment").GetValue($var)
				$val = dosify( $val )
				$output  += (
					"@setlocal",
					"@echo off",
					"( endlocal",
					$("echo {0}={1}`n" -f $var, $val),
					")"
					)
				}
			$setInUser = $false;
			$haveDisplayedPrior = $true;
			}
		elseif ( $setInMachine -and (( $token -eq "-m" ) -or ( $token -eq "--machine" )) ) {
			# Machine Environment
			if ( $haveDisplayedPrior ) {
				$output += "echo."
				}
			# Machine level VARs in "hklm:\System\CurrentControlSet\Control\Session Manager\Environment"
			foreach ($var in ( get-item "hklm:\System\CurrentControlSet\Control\Session Manager\Environment").GetValueNames() | sort-object ) {
				$val = (get-item "hklm:\System\CurrentControlSet\Control\Session Manager\Environment").GetValue($var)
				$val = dosify( $val )
				$output  += (
					"@setlocal",
					"@echo off",
					"( endlocal",
					$("echo {0}={1}`n" -f $var, $val),
					")"
					)
				}
			$setInMachine = $false;
			$haveDisplayedPrior = $true;
			}
        if ($out -ne $null) { $output -join "`n" | out-file -filepath $out -encoding Default -append }
        else { $output -join "`n" }
		}

	# if ( $setInProcess ) {
		# $output = ( "set" )
		# $output -join "`n" | out-file -filepath $out -encoding Default -append
		# }
	# ## user & machine level seem to have some pollution as well => extra properties seems like standard properties; probably a way around it to get just "regular" properties
	# # EXAMPLE (at the top of both...)
	# ##	PSPath                    : Microsoft.PowerShell.Core\Registry::HKEY_CURRENT_USER\Environme
	# ##	                            nt
	# ##	PSParentPath              : Microsoft.PowerShell.Core\Registry::HKEY_CURRENT_USER
	# ##	PSChildName               : Environment
	# ##	PSDrive                   : HKCU
	# ##	PSProvider                : Microsoft.PowerShell.Core\Registry
	# if ( $setInUser ) {
		# ##get-itemproperty hkcu:\Environment
		# foreach ($var in ( get-item "hkcu:\Environment").GetValueNames() | sort-object ) {
			# $val = (get-item "hkcu:\Environment").GetValue($var)
			# $val = dosify( $val )
			# $output  = (
				# "@setlocal",
				# "@echo off",
				# "( endlocal",
				# $("echo {0}={1}`n" -f $var, $val),
				# ")"
				# )
			# $output -join "`n" | out-file -filepath $out -encoding Default -append
			# }
		# }
	# if ( $setInMachine ) {
		# ##get-itemproperty "hklm:\System\CurrentControlSet\Control\Session Manager\Environment"
		# foreach ($var in (get-item "hklm:\System\CurrentControlSet\Control\Session Manager\Environment").GetValueNames() | sort-object ) {
			# $val = (get-item "hklm:\System\CurrentControlSet\Control\Session Manager\Environment").GetValue($var)
			# $val = dosify( $val )
			# $output  = (
				# "@setlocal",
				# "@echo off",
				# "( endlocal",
				# $("echo {0}={1}`n" -f $var, $val),
				# ")"
				# )
			# $output -join "`n" | out-file -filepath $out -encoding Default -append
			# }
		# }
	exit 0
	}

if (($args.Count -lt 1) -or ($args.Count -gt 2)) {
	"USAGE: "+${__ME}+" [-p|--process|-u|--user|-m|--machine|-i|--invoke|-x|--exec] VAR [VALUE]"
	exit 1
	}

$var = $args[0]
$val = $args[1]
if ($args.Count -eq 1) { $val = iex $('$'+"env:$var") }

if ($evalVALUE) {
	$val = @(iex $val)[-1];
	}

if (${__DEBUGGING}) {
	${__ME}+": DEBUG: val=""$val""";
	}

$identity  = [System.Security.Principal.WindowsIdentity]::GetCurrent();
$principal = New-Object System.Security.Principal.WindowsPrincipal( $identity );
$is_elevated = $principal.IsInRole( [System.Security.Principal.WindowsBuiltInRole]::Administrator );

if ($setInMachine) {
	if (-not $is_elevated) {
		${__ME}+": ERROR: Inadequate privileges to set (or read) Machine level environment variables (run as Administrator)"
		exit 1
		}
	[Environment]::SetEnvironmentVariable($var, $val, [EnvironmentVariableTarget]::Machine)
	}

if ($setInUser) {
	[Environment]::SetEnvironmentVariable($var, $val, [EnvironmentVariableTarget]::User)
	}

if ($setInProcess) {
	$val = dosify( $val )

	if (${__DEBUGGING}) {
		${__ME}+": DEBUG: [ PROCESS ] val=""$val""";
		}

	$output  = (
		"setlocal",
		"( endlocal",
		$("set {0}={1}`n" -f $var, $val),
		")"
		)

	$output -join "`n" | out-file -filepath $out -encoding Default -append
	}
