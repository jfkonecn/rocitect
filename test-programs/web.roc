app [plan_page!] { pf: platform "../platform/main.roc" }

plan_page! : {} => Str
plan_page! = |_| "<h1>Roc page</h1><rocitect-blueprint></rocitect-blueprint>"
