platform ""
	requires {
		plan_page! : Str, Str => Str,
		mcp_resources! : {} => Str,
		mcp_read_resource! : Str => Str,
		mcp_prompts! : {} => Str,
		mcp_prompt! : Str => Str,
		mcp_implementation_targets! : {} => Str
	}
	exposes [BlueprintGeneration, ReferenceInformation, PromptGeneration, UnitOperations]
	packages {}
	provides {
		"roc_plan_page": plan_page_for_host!,
		"roc_mcp_resources": mcp_resources_for_host!,
		"roc_mcp_read_resource": mcp_read_resource_for_host!,
		"roc_mcp_prompts": mcp_prompts_for_host!,
		"roc_mcp_prompt": mcp_prompt_for_host!,
		"roc_mcp_implementation_targets": mcp_implementation_targets_for_host!,
	}
	targets: {
		inputs_dir: "targets/",
		x64mac: { inputs: ["libhost.a", app] },
		arm64mac: { inputs: ["libhost.a", app] },
		x64musl: { inputs: ["crt1.o", "libhost.a", app, "libc.a"] },
		arm64musl: { inputs: ["crt1.o", "libhost.a", app, "libc.a"] },
		x64win: { inputs: ["host.lib", app] },
		arm64win: { inputs: ["host.lib", app] },
	}

import ReferenceInformation exposing [ReferenceInformation]
import BlueprintGeneration exposing [BlueprintGeneration]
import PromptGeneration exposing [PromptGeneration]
import UnitOperations exposing [UnitOperations]

plan_page_for_host! : Str, Str => Str
plan_page_for_host! = |kind, id| plan_page!(kind, id)

mcp_resources_for_host! : {} => Str
mcp_resources_for_host! = |_| mcp_resources!({})

mcp_read_resource_for_host! : Str => Str
mcp_read_resource_for_host! = |uri| mcp_read_resource!(uri)

mcp_prompts_for_host! : {} => Str
mcp_prompts_for_host! = |_| mcp_prompts!({})

mcp_prompt_for_host! : Str => Str
mcp_prompt_for_host! = |name| mcp_prompt!(name)

mcp_implementation_targets_for_host! : {} => Str
mcp_implementation_targets_for_host! = |_| mcp_implementation_targets!({})
