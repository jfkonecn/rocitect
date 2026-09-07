import UnitOperations

PromptGeneration := [].{
	llmExistingCodeInstruction : Str
	llmExistingCodeInstruction = "Before writing code, inspect the existing file content and any existing function list included with this prompt. If the requested function, helper, or test suite already exists, do not create a duplicate. Reuse, update, or extend the existing implementation instead, and preserve unrelated existing code."

	appendLine : Str, Str -> Str
	appendLine = |text, line| Str.concat(text, "${line}\n")

	codeCommentsToPrompt : UnitOperations.CodeComments -> Str
	codeCommentsToPrompt = |codeComments|
		match codeComments {
			Uncommented => "No code comments specified."
			Comments(comments) => comments
		}

	primitiveKindToPrompt : UnitOperations.PrimitiveKind(customPrimitive) -> Str
	primitiveKindToPrompt = |primitiveKind|
		match primitiveKind {
			String => "String"
			Int => "Int"
			Float => "Float"
			Bool => "Bool"
			Decimal => "Decimal"
			Bytes => "Bytes"
			Time => "Time"
			CustomPrimitive(_) => "Custom primitive type"
		}

	collectionKindToPrompt : UnitOperations.CollectionKind(customCollection) -> Str
	collectionKindToPrompt = |collectionKind|
		match collectionKind {
			List => "List"
			Set => "Set"
			Stream => "Stream"
			CustomCollection(_) => "Custom collection type"
		}

	typeDefinitionToPrompt : UnitOperations.TypeDefinition(customPrimitive, customCollection) -> Str
	typeDefinitionToPrompt = |typeDefinition|
		match typeDefinition {
			Primitive({ primitiveType }) => primitiveKindToPrompt(primitiveType)
			Collection({ collectionType, typeDefinition: itemType }) => "${collectionKindToPrompt(collectionType)} of ${typeDefinitionToPrompt(itemType)}"
			Struct({ typeName, .. }) => typeName
		}

	variableDefinitionToPrompt : UnitOperations.VariableDefinition(customPrimitive, customCollection) -> Str
	variableDefinitionToPrompt = |variable| "${variable.name}: ${typeDefinitionToPrompt(variable.typeDefinition)}"

	functionOutputToPrompt : UnitOperations.FunctionOutput(customPrimitive, customCollection) -> Str
	functionOutputToPrompt = |output|
		match output {
			NoOutput => "No output"
			Output(typeDefinition) => typeDefinitionToPrompt(typeDefinition)
		}

	functionRefsToPrompt : List(UnitOperations.FunctionRef) -> Str
	functionRefsToPrompt = |functionRefs| {
		if functionRefs.is_empty() {
			"None"
		} else {
			var $text = ""

			for functionRef in functionRefs {
				$text = appendLine($text, "- ${functionRef.functionName} (${functionRef.id})")
			}

			$text
		}
	}

	variablesToPrompt : List(UnitOperations.VariableDefinition(customPrimitive, customCollection)) -> Str
	variablesToPrompt = |variables| {
		if variables.is_empty() {
			"None\n"
		} else {
			var $text = ""

			for variable in variables {
				$text = appendLine($text, "- ${variableDefinitionToPrompt(variable)}")
			}

			$text
		}
	}

	filterLogicToPrompt : UnitOperations.FilterLogic(customLogic) -> Str
	filterLogicToPrompt = |filterLogic|
		match filterLogic {
			FilterDescription(description) => description
			CustomFilterLogic(_) => "Custom filter logic"
		}

	sortLogicToPrompt : UnitOperations.SortLogic(customLogic) -> Str
	sortLogicToPrompt = |sortLogic|
		match sortLogic {
			SortDescription(description) => description
			CustomSortLogic(_) => "Custom sort logic"
		}

	distributionLogicToPrompt : UnitOperations.DistributionLogic(customLogic) -> Str
	distributionLogicToPrompt = |distributionLogic|
		match distributionLogic {
			ConditionDescription(description) => description
			CustomDistributionLogic(_) => "Custom distribution logic"
		}

	validationLogicToPrompt : UnitOperations.ValidationLogic(customLogic) -> Str
	validationLogicToPrompt = |validationLogic|
		match validationLogic {
			ValidationDescription(description) => description
			CustomValidationLogic(_) => "Custom validation logic"
		}

	authenticationLogicToPrompt : UnitOperations.AuthenticationLogic(customLogic) -> Str
	authenticationLogicToPrompt = |authenticationLogic|
		match authenticationLogic {
			AuthenticationDescription(description) => description
			CustomAuthenticationLogic(_) => "Custom authentication logic"
		}

	authorizationLogicToPrompt : UnitOperations.AuthorizationLogic(customLogic) -> Str
	authorizationLogicToPrompt = |authorizationLogic|
		match authorizationLogic {
			AuthorizationDescription(description) => description
			CustomAuthorizationLogic(_) => "Custom authorization logic"
		}

	inputOutputLogicToPrompt : UnitOperations.InputOutputLogic(customLogic) -> Str
	inputOutputLogicToPrompt = |inputOutputLogic|
		match inputOutputLogic {
			InputOutputDescription(description) => description
			CustomInputOutputLogic(_) => "Custom input/output logic"
		}

	unitOperationToPrompt : UnitOperations.UnitOperation(customPrimitive, customCollection, customLogic, customPerformanceValue, customPerformanceUnit) -> Str
	unitOperationToPrompt = |operation|
		match operation {
			Map({ input, output, functionCalls, codeComments, performanceEstimate }) => "Map ${variableDefinitionToPrompt(input)} to ${variableDefinitionToPrompt(output)}. Comments: ${codeCommentsToPrompt(codeComments)}. Function calls:\n${functionRefsToPrompt(functionCalls)}Performance estimates: ${performanceEstimate.len().to_str()}\n"
			Filter({ input, output, filterLogic, functionCalls, codeComments, performanceEstimate }) => "Filter ${variableDefinitionToPrompt(input)} to ${variableDefinitionToPrompt(output)}. Logic: ${filterLogicToPrompt(filterLogic)}. Comments: ${codeCommentsToPrompt(codeComments)}. Function calls:\n${functionRefsToPrompt(functionCalls)}Performance estimates: ${performanceEstimate.len().to_str()}\n"
			Sort({ input, output, sortLogic, functionCalls, codeComments, performanceEstimate }) => "Sort ${variableDefinitionToPrompt(input)} into ${variableDefinitionToPrompt(output)}. Logic: ${sortLogicToPrompt(sortLogic)}. Comments: ${codeCommentsToPrompt(codeComments)}. Function calls:\n${functionRefsToPrompt(functionCalls)}Performance estimates: ${performanceEstimate.len().to_str()}\n"
			Distribution({ input, conditions, codeComments, performanceEstimate }) => {
				var $text = "Distribute ${variableDefinitionToPrompt(input)}. Comments: ${codeCommentsToPrompt(codeComments)}. Performance estimates: ${performanceEstimate.len().to_str()}\n"
				var $index = 1

				for condition in conditions {
					$text = appendLine($text, "Condition ${$index.to_str()}: ${distributionLogicToPrompt(condition.logic)} -> ${variableDefinitionToPrompt(condition.output)}")
					$index = $index + 1
				}

				$text
			}
			Validate({ input, validationLogic, successOutput, failureOutput, functionCalls, codeComments, performanceEstimate }) => "Validate ${variableDefinitionToPrompt(input)}. Logic: ${validationLogicToPrompt(validationLogic)}. Success: ${variableDefinitionToPrompt(successOutput)}. Failure: ${variableDefinitionToPrompt(failureOutput)}. Comments: ${codeCommentsToPrompt(codeComments)}. Function calls:\n${functionRefsToPrompt(functionCalls)}Performance estimates: ${performanceEstimate.len().to_str()}\n"
			Authenticate({ input, authenticationLogic, successOutput, failureOutput, functionCalls, codeComments, performanceEstimate }) => "Authenticate ${variableDefinitionToPrompt(input)}. Logic: ${authenticationLogicToPrompt(authenticationLogic)}. Success: ${variableDefinitionToPrompt(successOutput)}. Failure: ${variableDefinitionToPrompt(failureOutput)}. Comments: ${codeCommentsToPrompt(codeComments)}. Function calls:\n${functionRefsToPrompt(functionCalls)}Performance estimates: ${performanceEstimate.len().to_str()}\n"
			Authorize({ input, authorizationLogic, successOutput, failureOutput, functionCalls, codeComments, performanceEstimate }) => "Authorize ${variableDefinitionToPrompt(input)}. Logic: ${authorizationLogicToPrompt(authorizationLogic)}. Success: ${variableDefinitionToPrompt(successOutput)}. Failure: ${variableDefinitionToPrompt(failureOutput)}. Comments: ${codeCommentsToPrompt(codeComments)}. Function calls:\n${functionRefsToPrompt(functionCalls)}Performance estimates: ${performanceEstimate.len().to_str()}\n"
			GlobalStateRead({ output, functionCalls, codeComments, performanceEstimate }) => "Read global state into ${variableDefinitionToPrompt(output)}. Comments: ${codeCommentsToPrompt(codeComments)}. Function calls:\n${functionRefsToPrompt(functionCalls)}Performance estimates: ${performanceEstimate.len().to_str()}\n"
			GlobalStateWrite({ input, functionCalls, codeComments, performanceEstimate }) => "Write ${variableDefinitionToPrompt(input)} to global state. Comments: ${codeCommentsToPrompt(codeComments)}. Function calls:\n${functionRefsToPrompt(functionCalls)}Performance estimates: ${performanceEstimate.len().to_str()}\n"
			InputOutput({ input, inputOutputLogic, successOutput, failureOutput, functionCalls, codeComments, performanceEstimate }) => "Perform input/output with ${variableDefinitionToPrompt(input)}. Logic: ${inputOutputLogicToPrompt(inputOutputLogic)}. Success: ${variableDefinitionToPrompt(successOutput)}. Failure: ${variableDefinitionToPrompt(failureOutput)}. Comments: ${codeCommentsToPrompt(codeComments)}. Function calls:\n${functionRefsToPrompt(functionCalls)}Performance estimates: ${performanceEstimate.len().to_str()}\n"
			Panic({ description, codeComments, performanceEstimate }) => "Panic. Description: ${description}. Comments: ${codeCommentsToPrompt(codeComments)}. Performance estimates: ${performanceEstimate.len().to_str()}\n"
		}

	unitOperationsToPrompt : List(UnitOperations.UnitOperation(customPrimitive, customCollection, customLogic, customPerformanceValue, customPerformanceUnit)) -> Str
	unitOperationsToPrompt = |operations| {
		if operations.is_empty() {
			"None\n"
		} else {
			var $text = ""
			var $index = 1

			for operation in operations {
				$text = appendLine($text, "${$index.to_str()}. ${unitOperationToPrompt(operation)}")
				$index = $index + 1
			}

			$text
		}
	}

	testCasesToPrompt : List(UnitOperations.TestCase) -> Str
	testCasesToPrompt = |testCases| {
		if testCases.is_empty() {
			"None\n"
		} else {
			var $text = ""
			var $index = 1

			for testCase in testCases {
				$text = appendLine($text, "${$index.to_str()}. ${testCase.name}: ${testCase.description}")
				$index = $index + 1
			}

			$text
		}
	}

	generateFunctionPrompt : UnitOperations.FunctionDefinition(customPrimitive, customCollection, customLogic, customPerformanceValue, customPerformanceUnit) -> Str
	generateFunctionPrompt = |functionDefinition| {
		var $prompt = "# Implement Function: ${functionDefinition.functionName}\n\n"
		$prompt = appendLine($prompt, llmExistingCodeInstruction)
		$prompt = appendLine($prompt, "")
		$prompt = appendLine($prompt, "Function ID: ${functionDefinition.id}")
		$prompt = appendLine($prompt, "")
		$prompt = appendLine($prompt, "## Inputs")
		$prompt = Str.concat($prompt, variablesToPrompt(functionDefinition.inputs))
		$prompt = appendLine($prompt, "")
		$prompt = appendLine($prompt, "## Output")
		$prompt = appendLine($prompt, functionOutputToPrompt(functionDefinition.output))
		$prompt = appendLine($prompt, "")
		$prompt = appendLine($prompt, "## Code Comments")
		$prompt = appendLine($prompt, codeCommentsToPrompt(functionDefinition.codeComments))
		$prompt = appendLine($prompt, "")
		$prompt = appendLine($prompt, "## Unit Operations")
		$prompt = Str.concat($prompt, unitOperationsToPrompt(functionDefinition.unitOperations))
		$prompt = appendLine($prompt, "")
		appendLine($prompt, "Only reply with the complete file contents. Do not include markdown fences, explanations, summaries, or text outside the file contents.")
	}

	generateTestSuitePrompt : UnitOperations.TestSuite(customPrimitive, customCollection, customLogic, customPerformanceValue, customPerformanceUnit) -> Str
	generateTestSuitePrompt = |testSuite| {
		functionDefinition = testSuite.functionDefinition
		var $prompt = "# Implement Test Suite: ${testSuite.name}\n\n"
		$prompt = appendLine($prompt, llmExistingCodeInstruction)
		$prompt = appendLine($prompt, "Also check whether tests for ${functionDefinition.functionName} already exist before adding new tests. If they exist, update or extend them instead of duplicating coverage.")
		$prompt = appendLine($prompt, "")
		$prompt = appendLine($prompt, "Test Suite ID: ${testSuite.id}")
		$prompt = appendLine($prompt, "Function Under Test: ${functionDefinition.functionName} (${functionDefinition.id})")
		$prompt = appendLine($prompt, "")
		$prompt = appendLine($prompt, "## Function Prompt")
		$prompt = Str.concat($prompt, generateFunctionPrompt(functionDefinition))
		$prompt = appendLine($prompt, "")
		$prompt = appendLine($prompt, "## Test Cases")
		$prompt = Str.concat($prompt, testCasesToPrompt(testSuite.testCases))
		$prompt = appendLine($prompt, "")
		appendLine($prompt, "Only reply with the complete test file contents. Do not include markdown fences, explanations, summaries, or text outside the file contents.")
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

expect PromptGeneration.generateFunctionPrompt(sampleFunction).contains("# Implement Function: NormalizeName")

expect PromptGeneration.generateFunctionPrompt(sampleFunction).contains("If the requested function, helper, or test suite already exists, do not create a duplicate.")

expect PromptGeneration.generateFunctionPrompt(sampleFunction).contains("Map rawName: String to normalizedName: String")

sampleTestSuite : UnitOperations.TestSuite({}, {}, {}, U64, Str)
sampleTestSuite = {
	id: "test:normalize-name",
	name: "NormalizeName Tests",
	functionDefinition: sampleFunction,
	testCases: [{ name: "trims spaces", description: "Returns the input without surrounding whitespace." }],
}

expect PromptGeneration.generateTestSuitePrompt(sampleTestSuite).contains("# Implement Test Suite: NormalizeName Tests")

expect PromptGeneration.generateTestSuitePrompt(sampleTestSuite).contains("Also check whether tests for NormalizeName already exist before adding new tests.")
