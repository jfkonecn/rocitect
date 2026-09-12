import PromptGeneration
import UnitOperations

BlueprintGeneration := [].{
	FindFunctionResult(customPrimitive, customCollection, customLogic, customPerformanceValue, customPerformanceUnit) := [
		Found(UnitOperations.FunctionDefinition(customPrimitive, customCollection, customLogic, customPerformanceValue, customPerformanceUnit)),
		NotFound,
	]

	appendLine : Str, Str -> Str
	appendLine = |text, line| Str.concat(text, "${line}\n")

	replaceAll : Str, Str, Str -> Str
	replaceAll = |text, from, to| Str.join_with(Str.split_on(text, from), to)

	attributeValue : Str -> Str
	attributeValue = |value| {
		var $escaped = replaceAll(value, "&", "&amp;")
		$escaped = replaceAll($escaped, "\"", "&quot;")
		$escaped = replaceAll($escaped, "<", "&lt;")
		replaceAll($escaped, ">", "&gt;")
	}

	attribute : Str, Str -> Str
	attribute = |name, value| " ${name}=\"${attributeValue(value)}\""

	codeCommentsToText : UnitOperations.CodeComments -> Str
	codeCommentsToText = |codeComments|
		match codeComments {
			Uncommented => "No code comments specified."
			Comments(comments) => comments
		}

	functionOutputToText : UnitOperations.FunctionOutput(customPrimitive, customCollection) -> Str
	functionOutputToText = |output| PromptGeneration.functionOutputToPrompt(output)

	variablesToText : List(UnitOperations.VariableDefinition(customPrimitive, customCollection)) -> Str
	variablesToText = |variables| PromptGeneration.variablesToPrompt(variables)

	operationKind : UnitOperations.UnitOperation(customPrimitive, customCollection, customLogic, customPerformanceValue, customPerformanceUnit) -> Str
	operationKind = |operation|
		match operation {
			Map(_) => "Map"
			Filter(_) => "Filter"
			Sort(_) => "Sort"
			Distribution(_) => "Distribution"
			Validate(_) => "Validate"
			Authenticate(_) => "Authenticate"
			Authorize(_) => "Authorize"
			GlobalStateRead(_) => "Global State Read"
			GlobalStateWrite(_) => "Global State Write"
			InputOutput(_) => "Input/Output"
			Panic(_) => "Panic"
		}

	operationTone : UnitOperations.UnitOperation(customPrimitive, customCollection, customLogic, customPerformanceValue, customPerformanceUnit) -> Str
	operationTone = |operation|
		match operation {
			GlobalStateRead(_) => "source"
			Panic(_) => "sink"
			_ => "transform"
		}

	operationDescription : UnitOperations.UnitOperation(customPrimitive, customCollection, customLogic, customPerformanceValue, customPerformanceUnit) -> Str
	operationDescription = |operation|
		match operation {
			Map({ input, output, .. }) => "Maps ${input.name} into ${output.name}."
			Filter({ input, output, .. }) => "Filters ${input.name} into ${output.name}."
			Sort({ input, output, .. }) => "Sorts ${input.name} into ${output.name}."
			Distribution({ input, conditions, .. }) => "Distributes ${input.name} across ${conditions.len().to_str()} paths."
			Validate({ input, .. }) => "Validates ${input.name}."
			Authenticate({ input, .. }) => "Authenticates from ${input.name}."
			Authorize({ input, .. }) => "Authorizes from ${input.name}."
			GlobalStateRead({ output, .. }) => "Reads global state into ${output.name}."
			GlobalStateWrite({ input, .. }) => "Writes ${input.name} to global state."
			InputOutput({ input, .. }) => "Performs external input/output with ${input.name}."
			Panic({ description, .. }) => description
		}

	functionDetails : UnitOperations.FunctionDefinition(customPrimitive, customCollection, customLogic, customPerformanceValue, customPerformanceUnit) -> Str
	functionDetails = |functionDefinition| {
		var $details = "Function ID: ${functionDefinition.id}"
		$details = appendLine($details, "Inputs:\n${variablesToText(functionDefinition.inputs)}")
		$details = appendLine($details, "Output: ${functionOutputToText(functionDefinition.output)}")
		$details = appendLine($details, "Code comments: ${codeCommentsToText(functionDefinition.codeComments)}")
		appendLine($details, "Unit operations: ${functionDefinition.unitOperations.len().to_str()}")
	}

	operationDetails : UnitOperations.UnitOperation(customPrimitive, customCollection, customLogic, customPerformanceValue, customPerformanceUnit) -> Str
	operationDetails = |operation| PromptGeneration.unitOperationToPrompt(operation)

	testSuiteDetails : UnitOperations.TestSuite(customPrimitive, customCollection, customLogic, customPerformanceValue, customPerformanceUnit) -> Str
	testSuiteDetails = |testSuite| {
		var $details = "Test suite ID: ${testSuite.id}"
		$details = appendLine($details, "Function under test: ${testSuite.functionDefinition.functionName} (${testSuite.functionDefinition.id})")
		appendLine($details, "Test cases: ${testSuite.testCases.len().to_str()}")
	}

	testCaseDetails : UnitOperations.TestSuite(customPrimitive, customCollection, customLogic, customPerformanceValue, customPerformanceUnit), UnitOperations.TestCase -> Str
	testCaseDetails = |testSuite, testCase| {
		var $details = "Test suite: ${testSuite.name} (${testSuite.id})"
		$details = appendLine($details, "Function under test: ${testSuite.functionDefinition.functionName}")
		appendLine($details, "Description: ${testCase.description}")
	}

	functionX : U64 -> Str
	functionX = |index|
		if index == 1 {
			"7"
		} else if index == 2 {
			"38"
		} else if index == 3 {
			"67"
		} else if index == 4 {
			"38"
		} else {
			"7"
		}

	functionY : U64 -> Str
	functionY = |index|
		if index == 1 {
			"28"
		} else if index == 2 {
			"18"
		} else if index == 3 {
			"32"
		} else if index == 4 {
			"66"
		} else {
			"66"
		}

	operationX : U64 -> Str
	operationX = |index|
		if index == 1 {
			"8"
		} else if index == 2 {
			"38"
		} else if index == 3 {
			"68"
		} else if index == 4 {
			"38"
		} else {
			"8"
		}

	operationY : U64 -> Str
	operationY = |index|
		if index == 1 {
			"30"
		} else if index == 2 {
			"18"
		} else if index == 3 {
			"30"
		} else if index == 4 {
			"62"
		} else {
			"62"
		}

	centerX : Str -> Str
	centerX = |x| x

	centerY : Str -> Str
	centerY = |y| y

	connectionMarkup : Str, Str, Str, Str, Str -> Str
	connectionMarkup = |x1, y1, x2, y2, label|
		"<rocitect-data-connection${attribute("x1", centerX(x1))}${attribute("y1", centerY(y1))}${attribute("x2", centerX(x2))}${attribute("y2", centerY(y2))}${attribute("label", label)}></rocitect-data-connection>"

	functionNodeMarkup : U64, UnitOperations.FunctionDefinition(customPrimitive, customCollection, customLogic, customPerformanceValue, customPerformanceUnit) -> Str
	functionNodeMarkup = |index, functionDefinition|
		"<rocitect-function-node${attribute("style", "left: ${functionX(index)}%; top: ${functionY(index)}%;")}${attribute("name", functionDefinition.functionName)}${attribute("description", "${functionDefinition.inputs.len().to_str()} inputs, ${functionDefinition.unitOperations.len().to_str()} unit operations")}${attribute("tone", "transform")}${attribute("detail-title", functionDefinition.functionName)}${attribute("detail-kind", "Function")}${attribute("detail-id", functionDefinition.id)}${attribute("detail-body", functionDetails(functionDefinition))}${attribute("detail-href", "/?kind=function&id=${functionDefinition.id}")}${attribute("detail-label", "View unit operations")}${attribute("detail-secondary-href", "/?kind=test&id=${functionDefinition.id}")}${attribute("detail-secondary-label", "View tests")}></rocitect-function-node>"

	operationNodeMarkup : Str, U64, UnitOperations.UnitOperation(customPrimitive, customCollection, customLogic, customPerformanceValue, customPerformanceUnit) -> Str
	operationNodeMarkup = |functionId, index, operation|
		"<rocitect-function-node${attribute("style", "left: ${operationX(index)}%; top: ${operationY(index)}%;")}${attribute("name", operationKind(operation))}${attribute("description", operationDescription(operation))}${attribute("tone", operationTone(operation))}${attribute("detail-title", operationKind(operation))}${attribute("detail-kind", "Unit operation")}${attribute("detail-id", "unit-operation:${functionId}:${index.to_str()}")}${attribute("detail-body", operationDetails(operation))}></rocitect-function-node>"

	testSuiteNodeMarkup : U64, UnitOperations.TestSuite(customPrimitive, customCollection, customLogic, customPerformanceValue, customPerformanceUnit) -> Str
	testSuiteNodeMarkup = |index, testSuite|
		"<rocitect-function-node${attribute("style", "left: ${operationX(index)}%; top: ${operationY(index)}%;")}${attribute("name", testSuite.name)}${attribute("description", "${testSuite.testCases.len().to_str()} test cases")}${attribute("tone", "source")}${attribute("detail-title", testSuite.name)}${attribute("detail-kind", "Test suite")}${attribute("detail-id", testSuite.id)}${attribute("detail-body", testSuiteDetails(testSuite))}></rocitect-function-node>"

	testCaseNodeMarkup : U64, UnitOperations.TestSuite(customPrimitive, customCollection, customLogic, customPerformanceValue, customPerformanceUnit), UnitOperations.TestCase -> Str
	testCaseNodeMarkup = |index, testSuite, testCase|
		"<rocitect-function-node${attribute("style", "left: ${operationX(index)}%; top: ${operationY(index)}%;")}${attribute("name", testCase.name)}${attribute("description", testCase.description)}${attribute("tone", "transform")}${attribute("detail-title", testCase.name)}${attribute("detail-kind", "Test case")}${attribute("detail-id", "test-case:${testSuite.id}:${index.to_str()}")}${attribute("detail-body", testCaseDetails(testSuite, testCase))}></rocitect-function-node>"

	functionFlowMarkup : List(UnitOperations.FunctionDefinition(customPrimitive, customCollection, customLogic, customPerformanceValue, customPerformanceUnit)) -> Str
	functionFlowMarkup = |functionDefinitions| {
		var $markup = "<rocitect-blueprint>"
		var $index = 1
		var $previousX = ""
		var $previousY = ""

		for functionDefinition in functionDefinitions {
			x = functionX($index)
			y = functionY($index)

			if $index > 1 {
				$markup = Str.concat($markup, connectionMarkup($previousX, $previousY, x, y, "data"))
			}

			$markup = Str.concat($markup, functionNodeMarkup($index, functionDefinition))
			$previousX = x
			$previousY = y
			$index = $index + 1
		}

		Str.concat($markup, "</rocitect-blueprint>")
	}

	unitOperationFlowMarkup : UnitOperations.FunctionDefinition(customPrimitive, customCollection, customLogic, customPerformanceValue, customPerformanceUnit) -> Str
	unitOperationFlowMarkup = |functionDefinition| {
		var $markup = "<rocitect-blueprint>"
		var $index = 1
		var $previousX = ""
		var $previousY = ""

		for operation in functionDefinition.unitOperations {
			x = operationX($index)
			y = operationY($index)

			if $index > 1 {
				$markup = Str.concat($markup, connectionMarkup($previousX, $previousY, x, y, "data"))
			}

			$markup = Str.concat($markup, operationNodeMarkup(functionDefinition.id, $index, operation))
			$previousX = x
			$previousY = y
			$index = $index + 1
		}

		Str.concat($markup, "</rocitect-blueprint>")
	}

	testFlowMarkup : Str, List(UnitOperations.TestSuite(customPrimitive, customCollection, customLogic, customPerformanceValue, customPerformanceUnit)) -> Str
	testFlowMarkup = |functionId, testSuites| {
		var $markup = "<rocitect-blueprint>"
		var $index = 1
		var $previousX = ""
		var $previousY = ""

		for testSuite in testSuites {
			if testSuite.functionDefinition.id == functionId {
				x = operationX($index)
				y = operationY($index)

				if $index > 1 {
					$markup = Str.concat($markup, connectionMarkup($previousX, $previousY, x, y, "tests"))
				}

				$markup = Str.concat($markup, testSuiteNodeMarkup($index, testSuite))
				$previousX = x
				$previousY = y
				$index = $index + 1

				for testCase in testSuite.testCases {
					testX = operationX($index)
					testY = operationY($index)
					$markup = Str.concat($markup, connectionMarkup($previousX, $previousY, testX, testY, "case"))
					$markup = Str.concat($markup, testCaseNodeMarkup($index, testSuite, testCase))
					$previousX = testX
					$previousY = testY
					$index = $index + 1
				}
			}
		}

		Str.concat($markup, "</rocitect-blueprint>")
	}

	findFunction : Str, List(UnitOperations.FunctionDefinition(customPrimitive, customCollection, customLogic, customPerformanceValue, customPerformanceUnit)) -> FindFunctionResult(customPrimitive, customCollection, customLogic, customPerformanceValue, customPerformanceUnit)
	findFunction = |id, functionDefinitions| {
		for functionDefinition in functionDefinitions {
			if functionDefinition.id == id {
				return Found(functionDefinition)
			}
		}

		NotFound
	}

	generateBlueprintPage : Str, Str, List(UnitOperations.FunctionDefinition(customPrimitive, customCollection, customLogic, customPerformanceValue, customPerformanceUnit)), List(UnitOperations.TestSuite(customPrimitive, customCollection, customLogic, customPerformanceValue, customPerformanceUnit)) -> Str
	generateBlueprintPage = |kind, id, functionDefinitions, testSuites|
		if kind == "function" {
			match findFunction(id, functionDefinitions) {
				Found(functionDefinition) => unitOperationFlowMarkup(functionDefinition)
				NotFound => functionFlowMarkup(functionDefinitions)
			}
		} else if kind == "test" {
			testFlowMarkup(id, testSuites)
		} else {
			functionFlowMarkup(functionDefinitions)
		}
}

stringType : UnitOperations.TypeDefinition({}, {})
stringType = Primitive({ primitiveType: String })

inputVariable : UnitOperations.VariableDefinition({}, {})
inputVariable = { name: "rawName", typeDefinition: stringType }

outputVariable : UnitOperations.VariableDefinition({}, {})
outputVariable = { name: "normalizedName", typeDefinition: stringType }

sampleFunction : UnitOperations.FunctionDefinition({}, {}, {}, U64, Str)
sampleFunction = {
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

sampleTestSuite : UnitOperations.TestSuite({}, {}, {}, U64, Str)
sampleTestSuite = {
	id: "test:normalize-name",
	name: "NormalizeName Tests",
	functionDefinition: sampleFunction,
	testCases: [{ name: "trims spaces", description: "Returns the input without surrounding whitespace." }],
}

expect BlueprintGeneration.generateBlueprintPage("", "", [sampleFunction], [sampleTestSuite]).contains("rocitect-function-node")

expect BlueprintGeneration.generateBlueprintPage("", "", [sampleFunction], [sampleTestSuite]).contains("View tests")

expect BlueprintGeneration.generateBlueprintPage("function", "function:normalize-name", [sampleFunction], [sampleTestSuite]).contains("Unit operation")

expect BlueprintGeneration.generateBlueprintPage("test", "function:normalize-name", [sampleFunction], [sampleTestSuite]).contains("Test case")
