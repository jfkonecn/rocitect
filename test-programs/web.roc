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
import pf.BlueprintGeneration
import pf.UnitOperations

plan_page! : Str, Str => Str
plan_page! = |kind, id| BlueprintGeneration.generateBlueprintPage(kind, id, [functionToImplement], [testSuiteToImplement])

referenceItems : List(ReferenceInformation.ReferenceItem({}, {}))
referenceItems = [
	{
		id: "reference:go-language-manual",
		title: "Go programming language manual",
		kind: Documentation,
		source: Url("https://go.dev/ref/spec"),
		content: Markdown("Use the Go language specification and standard library conventions when implementing the command-line weather tool."),
		tags: ["go", "language", "implementation"],
	},
	{
		id: "reference:weather-gov-api-docs",
		title: "weather.gov API documentation",
		kind: Documentation,
		source: Url("https://api.weather.gov/"),
		content: Markdown("Use the weather.gov API documentation for endpoint selection, request headers, response shape, and forecast data fields."),
		tags: ["weather.gov", "api", "implementation"],
	},
]

stringType : UnitOperations.TypeDefinition({}, {})
stringType = Primitive({ primitiveType: String })

inputVariable : UnitOperations.VariableDefinition({}, {})
inputVariable = { name: "locationInput", typeDefinition: stringType }

validatedLocationVariable : UnitOperations.VariableDefinition({}, {})
validatedLocationVariable = { name: "validatedLocation", typeDefinition: stringType }

apiResponseVariable : UnitOperations.VariableDefinition({}, {})
apiResponseVariable = { name: "weatherGovResponse", typeDefinition: stringType }

parsedWeatherVariable : UnitOperations.VariableDefinition({}, {})
parsedWeatherVariable = { name: "parsedWeatherJson", typeDefinition: stringType }

forecastTextVariable : UnitOperations.VariableDefinition({}, {})
forecastTextVariable = { name: "forecastText", typeDefinition: stringType }

errorVariable : UnitOperations.VariableDefinition({}, {})
errorVariable = { name: "weatherError", typeDefinition: stringType }

functionToImplement : UnitOperations.FunctionDefinition({}, {}, {}, U64, Str)
functionToImplement = {
	id: "function:get-weather-forecast",
	functionName: "GetWeatherForecast",
	inputs: [],
	output: NoOutput,
	codeComments: Comments("Write this as a Go command-line tool. It should ask for a location, fetch forecast data from weather.gov, and print a readable forecast."),
	unitOperations: [
		InputOutput({
			input: inputVariable,
			inputOutputLogic: InputOutputDescription("Ask the user what location they want weather data for."),
			successOutput: inputVariable,
			failureOutput: errorVariable,
			functionCalls: [],
			codeComments: Comments("Prompt on stdin/stdout for a location such as city/state or latitude/longitude."),
			performanceEstimate: [{ value: 1, unit: "interaction" }],
		}),
		Validate({
			input: inputVariable,
			validationLogic: ValidationDescription("Ensure the location input is present and specific enough to resolve for weather.gov."),
			successOutput: validatedLocationVariable,
			failureOutput: errorVariable,
			functionCalls: [],
			codeComments: Comments("Reject empty or ambiguous input before making a network request."),
			performanceEstimate: [{ value: 1, unit: "millisecond" }],
		}),
		InputOutput({
			input: validatedLocationVariable,
			inputOutputLogic: InputOutputDescription("Make a GET request to the weather.gov API endpoint for the requested location."),
			successOutput: apiResponseVariable,
			failureOutput: errorVariable,
			functionCalls: [{ id: "function:http-get", functionName: "HttpGet" }],
			codeComments: Comments("Use weather.gov endpoints and include a User-Agent header as required by the API."),
			performanceEstimate: [{ value: 500, unit: "millisecond" }],
		}),
		Validate({
			input: apiResponseVariable,
			validationLogic: ValidationDescription("Parse and validate the JSON response from weather.gov."),
			successOutput: parsedWeatherVariable,
			failureOutput: errorVariable,
			functionCalls: [{ id: "function:parse-json", functionName: "ParseJson" }],
			codeComments: Comments("Confirm the response contains forecast periods before formatting output."),
			performanceEstimate: [{ value: 2, unit: "millisecond" }],
		}),
		Map({
			input: parsedWeatherVariable,
			output: forecastTextVariable,
			functionCalls: [{ id: "function:format-forecast", functionName: "FormatForecast" }],
			codeComments: Comments("Convert the parsed JSON data into a concise human-readable forecast string."),
			performanceEstimate: [{ value: 1, unit: "millisecond" }],
		}),
		InputOutput({
			input: forecastTextVariable,
			inputOutputLogic: InputOutputDescription("Print the forecast string to the console."),
			successOutput: forecastTextVariable,
			failureOutput: errorVariable,
			functionCalls: [],
			codeComments: Comments("Write the formatted forecast to stdout."),
			performanceEstimate: [{ value: 1, unit: "millisecond" }],
		}),
	],
}

testSuiteToImplement : UnitOperations.TestSuite({}, {}, {}, U64, Str)
testSuiteToImplement = {
	id: "test:get-weather-forecast",
	name: "GetWeatherForecast Tests",
	functionDefinition: functionToImplement,
	testCases: [
		{ name: "rejects empty location", description: "Shows a validation error when the user does not enter a usable location." },
		{ name: "formats forecast response", description: "Converts a successful weather.gov JSON response into readable console text." },
	],
}

mcp_resources! : {} => Str
mcp_resources! = |_|
	"[{\"uri\":\"rocitect://references/go-language-manual\",\"name\":\"Go programming language manual\",\"description\":\"Language reference for implementing the weather.gov CLI in Go.\",\"mimeType\":\"text/markdown\"},{\"uri\":\"rocitect://references/weather-gov-api-docs\",\"name\":\"weather.gov API documentation\",\"description\":\"API reference for weather.gov forecast endpoints and required request headers.\",\"mimeType\":\"text/markdown\"}]"

mcp_read_resource! : Str => Str
mcp_read_resource! = |uri|
	if uri == "go-language-manual" {
		"Go programming language manual: https://go.dev/ref/spec\nImplement the weather.gov command-line tool in Go using idiomatic standard-library packages such as bufio, net/http, encoding/json, and fmt."
	} else if uri == "weather-gov-api-docs" {
		"weather.gov API documentation: https://api.weather.gov/\nUse weather.gov forecast endpoints and include a descriptive User-Agent header as required by the API."
	} else {
		"Unknown resource URI. Available code-specific references are go-language-manual and weather-gov-api-docs."
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
	"Available functions to implement:\n- function:get-weather-forecast GetWeatherForecast\n\nAvailable test suites to implement:\n- test:get-weather-forecast GetWeatherForecast Tests"
