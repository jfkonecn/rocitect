platform ""
	requires {
		plan_page! : {} => Str
	}
	exposes []
	packages {}
	provides { "roc_plan_page": plan_page_for_host! }
	targets: {
		inputs_dir: "targets/",
		x64mac: { inputs: ["libhost.a", app] },
		arm64mac: { inputs: ["libhost.a", app] },
		x64musl: { inputs: ["crt1.o", "libhost.a", app, "libc.a"] },
		arm64musl: { inputs: ["crt1.o", "libhost.a", app, "libc.a"] },
		x64win: { inputs: ["host.lib", app] },
		arm64win: { inputs: ["host.lib", app] },
	}
plan_page_for_host! : {} => Str
plan_page_for_host! = |_| plan_page!({})
