app [plan_page!] { pf: platform "../platform/main.roc" }

plan_page! : {} => Str
plan_page! = |_| "<html><body><h1>Roc page</h1></body></html>"
