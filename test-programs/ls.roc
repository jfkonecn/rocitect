app [main!] { pf: platform "../platform/main.roc" }

import pf.SystemCall
import pf.Stdout

main! : List(Str) => Try({}, [Exit(I32), StdinErr(Str), StdoutErr(Str), ..])
main! = |_args| {
	output = SystemCall.line!("ls", "-a")?
	Stdout.line!(output)?
	Ok({})
}
