app [main!] { pf: platform "../platform/main.roc" }

import pf.SystemCall

main! : List(Str) => Try({}, [Exit(I32), StdinErr(Str), StdoutErr(Str), ..])
main! = |_args| {
    s = SystemCall("ls", "-a")?
    Ok({})
}
