app [
	plan_page!,
	mcp_resources!,
	mcp_read_resource!,
	mcp_prompts!,
	mcp_prompt!,
	mcp_implementation_targets!,
] { pf: platform "../platform/main.roc" }

import pf.PromptGeneration
import pf.ReferenceInformation
import pf.UnitOperations

plan_page! : {} => Str
plan_page! = |_| "<h1>Roc page</h1><rocitect-blueprint></rocitect-blueprint>"

referenceItems : List(ReferenceInformation.ReferenceItem({}, {}))
referenceItems = [
	{
		id: "reference:implementation-guidance",
		title: "Implementation guidance",
		kind: Documentation,
		source: Inline,
		content: Markdown("Use the Roc-defined unit operation data as the source of truth for generated implementation prompts."),
		tags: ["mcp", "implementation", "roc"],
	},
	{
		id: "reference:progress-tracking",
		title: "Progress tracking",
		kind: BusinessLogic,
		source: Inline,
		content: Text("MCP tools should tell the LLM to record progress as it makes changes."),
		tags: ["todo", "progress", "tools"],
	},
]

stringType : UnitOperations.TypeDefinition({}, {})
stringType = Primitive({ primitiveType: String })

inputVariable : UnitOperations.VariableDefinition({}, {})
inputVariable = { name: "rawName", typeDefinition: stringType }

outputVariable : UnitOperations.VariableDefinition({}, {})
outputVariable = { name: "normalizedName", typeDefinition: stringType }

functionToImplement : UnitOperations.FunctionDefinition({}, {}, {}, U64, Str)
functionToImplement = {
	id: "function:normalize-name",
	functionName: "NormalizeName",
	inputs: [inputVariable],
	output: Output(stringType),
	codeComments: Comments("Return a display-safe name."),
	unitOperations: [
		Map({
			input: inputVariable,
			output: outputVariable,
			functionCalls: [{ id: "function:trim", functionName: "TrimWhitespace" }],
			codeComments: Comments("Trim whitespace before returning."),
			performanceEstimate: [{ value: 1, unit: "millisecond" }],
		}),
	],
}

testSuiteToImplement : UnitOperations.TestSuite({}, {}, {}, U64, Str)
testSuiteToImplement = {
	id: "test:normalize-name",
	name: "NormalizeName Tests",
	functionDefinition: functionToImplement,
	testCases: [{ name: "trims spaces", description: "Returns the input without surrounding whitespace." }],
}

mcp_resources! : {} => Str
mcp_resources! = |_|
	"[{\"uri\":\"rocitect://references/implementation-guidance\",\"name\":\"Implementation guidance\",\"description\":\"Reference data from platform/ReferenceInformation.roc.\",\"mimeType\":\"text/markdown\"},{\"uri\":\"rocitect://references/progress-tracking\",\"name\":\"Progress tracking\",\"description\":\"Reference data from platform/ReferenceInformation.roc.\",\"mimeType\":\"text/plain\"}]"

mcp_read_resource! : Str => Str
mcp_read_resource! = |uri|
	if uri == "implementation-guidance" {
		"Use the Roc-defined unit operation data as the source of truth for generated implementation prompts."
	} else if uri == "progress-tracking" {
		"MCP tools should tell the LLM to record progress as it makes changes."
	} else {
		"Unknown resource URI. Available data is defined in platform/ReferenceInformation.roc."
	}

mcp_prompts! : {} => Str
mcp_prompts! = |_|
	"[{\"name\":\"implement-function\",\"description\":\"Create or update a function using platform/PromptGeneration.roc.\",\"arguments\":[{\"name\":\"id\",\"description\":\"Function id from list_implementation_targets.\",\"required\":true}]},{\"name\":\"implement-test-suite\",\"description\":\"Create or update a test suite using platform/PromptGeneration.roc.\",\"arguments\":[{\"name\":\"id\",\"description\":\"Test suite id from list_implementation_targets.\",\"required\":true}]}]"

mcp_prompt! : Str => Str
mcp_prompt! = |name|
	if name == "implement-test-suite" {
		PromptGeneration.generateTestSuitePrompt(testSuiteToImplement)
	} else {
		PromptGeneration.generateFunctionPrompt(functionToImplement)
	}

mcp_implementation_targets! : {} => Str
mcp_implementation_targets! = |_|
	"Available functions to implement:\n- function:normalize-name NormalizeName\n\nAvailable test suites to implement:\n- test:normalize-name NormalizeName Tests"
