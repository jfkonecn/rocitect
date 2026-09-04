import Host

## Utilities for executing system commands.
SystemCall := [].{

	## Execute a system command with the given arguments.
	##
	## Returns the command output on success or the host error if execution fails.
	line! : Str, Str => Try(Str, [StdoutErr(Str), ..])
	line! = |cmd, args|
		match Host.system_call!(cmd, args) {
			Ok(s) => Ok(s)
			Err(StdoutErr(err)) => Err(StdoutErr(err))
		}
}
