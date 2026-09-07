import Host

CodeComments := [Uncommented, Comments(Str)]

TypeDefinition := [
	Primitive(
		{
			primitiveType : Str,
		},
	),
	Collection(
		{
			collectionType : Str,
			typeDefinition : TypeDefinition,
		},
	),
	Struct(
		{
			id : [Str, None],
			typeName : Str,
			codeComments : CodeComments,
			fields : List(StructTypeField),
		},
	),
]

StructTypeField := {
	name : Str,
	codeComments : CodeComments,
	typeDefinition : [NoType, Type(TypeDefinition)],
}

VariableDefinition := {
	name : Str,
	typeDefinition : [NoType, Type(TypeDefinition)],
}

DistributionCondition := {
	condition : Str,
	output : [NoVariable, Variable(VariableDefinition)],
	codeComments : CodeComments,
	functionCalls : List([NoFunction, Function(FunctionDefinition)]),
}

UnitOperation := [
	# A Map unit operation converts one value or type into another.
	Map(
		{
			input : [NoVariable, Variable(VariableDefinition)],
			output : [NoVariable, Variable(VariableDefinition)],
			functionCalls : List([NoFunction, Function(FunctionDefinition)]),
			codeComments : CodeComments,
		},
	),
	# A Filter unit operation removes, rejects, or reroutes data.
	Filter(
		{
			input : [NoVariable, Variable(VariableDefinition)],
			output : [NoVariable, Variable(VariableDefinition)],
			filterLogic : Str,
			functionCalls : List([NoFunction, Function(FunctionDefinition)]),
			codeComments : Str,
		},
	),
	Sort(
		{
			input : [NoVariable, Variable(VariableDefinition)],
			functionCalls : List([NoFunction, Function(FunctionDefinition)]),
			sortLogic : Str,
			codeComments : CodeComments,
		},
	),
	# A Distribution unit operation chooses where data goes next, such as branching.
	Distribution(
		{
			input : [NoVariable, Variable(VariableDefinition)],
			codeComments : CodeComments,
			conditions : List(DistributionCondition),
		},
	),
	# A Validate unit operation checks data integrity.
	Validate(
		{
			input : [NoVariable, Variable(VariableDefinition)],
			successOutput : [NoVariable, Variable(VariableDefinition)],
			failureOutput : [NoVariable, Variable(VariableDefinition)],
			codeComments : CodeComments,
			functionCalls : List([NoFunction, Function(FunctionDefinition)]),
		},
	),
	# An Authenticate unit operation determines the identity initiating a flow.
	Authenticate(
		{
			input : [NoVariable, Variable(VariableDefinition)],
			successOutput : [NoVariable, Variable(VariableDefinition)],
			failureOutput : [NoVariable, Variable(VariableDefinition)],
			codeComments : CodeComments,
			functionCalls : List([NoFunction, Function(FunctionDefinition)]),
		},
	),
	# An Authorize unit operation determines whether an authenticated identity may perform an action.
	Authorize(
		{
			input : [NoVariable, Variable(VariableDefinition)],
			authorizeConditions : Str,
			successOutput : [NoVariable, Variable(VariableDefinition)],
			failureOutput : [NoVariable, Variable(VariableDefinition)],
			codeComments : CodeComments,
			functionCalls : List([NoFunction, Function(FunctionDefinition)]),
		},
	),
	# A GlobalStateRead unit operation reads values whose lifetime extends beyond the current call stack.
	GlobalStateRead(
		{
			output : [NoVariable, Variable(VariableDefinition)],
			codeComments : CodeComments,
			functionCalls : List([NoFunction, Function(FunctionDefinition)]),
		},
	),
	# A GlobalStateWrite unit operation writes values whose lifetime extends beyond the current call stack.
	GlobalStateWrite(
		{
			input : [NoVariable, Variable(VariableDefinition)],
			codeComments : CodeComments,
			functionCalls : List([NoFunction, Function(FunctionDefinition)]),
		},
	),
	# An InputOutput unit operation communicates outside the program, including HTTP, databases, etc.
	InputOutput(
		{
			input : [NoVariable, Variable(VariableDefinition)],
			successOutput : [NoVariable, Variable(VariableDefinition)],
			failureOutput : [NoVariable, Variable(VariableDefinition)],
			codeComments : CodeComments,
			functionCalls : List([NoFunction, Function(FunctionDefinition)]),
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

FunctionDefinition := {
	id : [Unspecified, Specified(Str)],
	functionName : Str,
	codeComments : CodeComments,
	unitOperations : List([NoOperation, Operation(UnitOperation)]),
}

TestCase := {
	name : Str,
	description : Str,
}

TestSuite := {
	id : [Unspecified, Specified(Str)],
	name : Str,
	functionDefinition : [NoFunction, Function(FunctionDefinition)],
	testCases : List([NoTestCase, TestCase(TestCase)]),
}
