CodeComments := [Uncommented, Comments(Str)]

DefinitionId := Str

PrimitiveKind(customPrimitive) := [String, Int, Float, Bool, Decimal, Bytes, Time, CustomPrimitive(customPrimitive)]

CollectionKind(customCollection) := [List, Set, Stream, CustomCollection(customCollection)]

TypeDefinition(customPrimitive, customCollection) := [
	Primitive(
		{
			primitiveType : PrimitiveKind(customPrimitive),
		},
	),
	Collection(
		{
			collectionType : CollectionKind(customCollection),
			typeDefinition : TypeDefinition(customPrimitive, customCollection),
		},
	),
	Struct(
		{
			id : DefinitionId,
			typeName : Str,
			codeComments : CodeComments,
			fields : List(StructTypeField(customPrimitive, customCollection)),
		},
	),
]

StructTypeField(customPrimitive, customCollection) := {
	name : Str,
	codeComments : CodeComments,
	typeDefinition : TypeDefinition(customPrimitive, customCollection),
}

VariableDefinition(customPrimitive, customCollection) := {
	name : Str,
	typeDefinition : TypeDefinition(customPrimitive, customCollection),
}

FunctionRef := {
	id : DefinitionId,
	functionName : Str,
}

FunctionOutput(customPrimitive, customCollection) := [NoOutput, Output(TypeDefinition(customPrimitive, customCollection))]

FilterLogic(customLogic) := [FilterDescription(Str), CustomFilterLogic(customLogic)]

SortLogic(customLogic) := [SortDescription(Str), CustomSortLogic(customLogic)]

DistributionLogic(customLogic) := [ConditionDescription(Str), CustomDistributionLogic(customLogic)]

ValidationLogic(customLogic) := [ValidationDescription(Str), CustomValidationLogic(customLogic)]

AuthenticationLogic(customLogic) := [AuthenticationDescription(Str), CustomAuthenticationLogic(customLogic)]

AuthorizationLogic(customLogic) := [AuthorizationDescription(Str), CustomAuthorizationLogic(customLogic)]

InputOutputLogic(customLogic) := [InputOutputDescription(Str), CustomInputOutputLogic(customLogic)]

DistributionCondition(customPrimitive, customCollection, customLogic) := {
	logic : DistributionLogic(customLogic),
	output : VariableDefinition(customPrimitive, customCollection),
	codeComments : CodeComments,
	functionCalls : List(FunctionRef),
}

UnitOperation(customPrimitive, customCollection, customLogic) := [
	# A Map unit operation converts one value or type into another.
	Map(
		{
			input : VariableDefinition(customPrimitive, customCollection),
			output : VariableDefinition(customPrimitive, customCollection),
			functionCalls : List(FunctionRef),
			codeComments : CodeComments,
		},
	),
	# A Filter unit operation removes, rejects, or reroutes data.
	Filter(
		{
			input : VariableDefinition(customPrimitive, customCollection),
			output : VariableDefinition(customPrimitive, customCollection),
			filterLogic : FilterLogic(customLogic),
			functionCalls : List(FunctionRef),
			codeComments : CodeComments,
		},
	),
	Sort(
		{
			input : VariableDefinition(customPrimitive, customCollection),
			output : VariableDefinition(customPrimitive, customCollection),
			functionCalls : List(FunctionRef),
			sortLogic : SortLogic(customLogic),
			codeComments : CodeComments,
		},
	),
	# A Distribution unit operation chooses where data goes next, such as branching.
	Distribution(
		{
			input : VariableDefinition(customPrimitive, customCollection),
			codeComments : CodeComments,
			conditions : List(DistributionCondition(customPrimitive, customCollection, customLogic)),
		},
	),
	# A Validate unit operation checks data integrity.
	Validate(
		{
			input : VariableDefinition(customPrimitive, customCollection),
			validationLogic : ValidationLogic(customLogic),
			successOutput : VariableDefinition(customPrimitive, customCollection),
			failureOutput : VariableDefinition(customPrimitive, customCollection),
			codeComments : CodeComments,
			functionCalls : List(FunctionRef),
		},
	),
	# An Authenticate unit operation determines the identity initiating a flow.
	Authenticate(
		{
			input : VariableDefinition(customPrimitive, customCollection),
			authenticationLogic : AuthenticationLogic(customLogic),
			successOutput : VariableDefinition(customPrimitive, customCollection),
			failureOutput : VariableDefinition(customPrimitive, customCollection),
			codeComments : CodeComments,
			functionCalls : List(FunctionRef),
		},
	),
	# An Authorize unit operation determines whether an authenticated identity may perform an action.
	Authorize(
		{
			input : VariableDefinition(customPrimitive, customCollection),
			authorizationLogic : AuthorizationLogic(customLogic),
			successOutput : VariableDefinition(customPrimitive, customCollection),
			failureOutput : VariableDefinition(customPrimitive, customCollection),
			codeComments : CodeComments,
			functionCalls : List(FunctionRef),
		},
	),
	# A GlobalStateRead unit operation reads values whose lifetime extends beyond the current call stack.
	GlobalStateRead(
		{
			output : VariableDefinition(customPrimitive, customCollection),
			codeComments : CodeComments,
			functionCalls : List(FunctionRef),
		},
	),
	# A GlobalStateWrite unit operation writes values whose lifetime extends beyond the current call stack.
	GlobalStateWrite(
		{
			input : VariableDefinition(customPrimitive, customCollection),
			codeComments : CodeComments,
			functionCalls : List(FunctionRef),
		},
	),
	# An InputOutput unit operation communicates outside the program, including HTTP, databases, etc.
	InputOutput(
		{
			input : VariableDefinition(customPrimitive, customCollection),
			inputOutputLogic : InputOutputLogic(customLogic),
			successOutput : VariableDefinition(customPrimitive, customCollection),
			failureOutput : VariableDefinition(customPrimitive, customCollection),
			codeComments : CodeComments,
			functionCalls : List(FunctionRef),
		},
	),
	# A Panic unit operation terminates execution of the program.
	Panic(
		{
			description : Str,
			codeComments : CodeComments,
		},
	),
]

FunctionDefinition(customPrimitive, customCollection, customLogic) := {
	id : DefinitionId,
	functionName : Str,
	inputs : List(VariableDefinition(customPrimitive, customCollection)),
	output : FunctionOutput(customPrimitive, customCollection),
	codeComments : CodeComments,
	unitOperations : List(UnitOperation(customPrimitive, customCollection, customLogic)),
}

TestCase := {
	name : Str,
	description : Str,
}

TestSuite(customPrimitive, customCollection, customLogic) := {
	id : DefinitionId,
	name : Str,
	functionDefinition : FunctionDefinition(customPrimitive, customCollection, customLogic),
	testCases : List(TestCase),
}
