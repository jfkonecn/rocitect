app [plan_page!] { pf: platform "../platform/main.roc" }

plan_page! : {} => Str
plan_page! = |_| "<html><body><h1>Hello from Roc</h1></body></html>"
