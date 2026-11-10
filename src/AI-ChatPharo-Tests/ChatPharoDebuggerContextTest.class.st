Class {
	#name : 'ChatPharoDebuggerContextTest',
	#superclass : 'TestCase',
	#category : 'AI-ChatPharo-Tests-Debugger',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Debugger'
}

{ #category : 'tests' }
ChatPharoDebuggerContextTest >> testBasicCreation [

	| ctx |
	ctx := ChatPharoDebuggerContext new.
	self assert: ctx errorClassName isNil.
	self assert: ctx errorMessage isNil.
	self assert: ctx stackTrace isNil.
	self assert: ctx failingMethodSource isNil.
	self assert: ctx localVariables isNil.
	self assert: ctx receiverState isNil
]

{ #category : 'tests' }
ChatPharoDebuggerContextTest >> testCaptureMethodInfo [

	| ctx method |
	method := OrderedCollection >> #add:.
	ctx := ChatPharoDebuggerContext new.
	ctx captureMethodInfo: method.
	self assert: ctx failingClassName equals: 'OrderedCollection'.
	self assert: ctx failingSelector equals: 'add:'.
	self assert: ctx failingMethodSource notNil.
	self deny: ctx failingMethodSource isEmpty
]

{ #category : 'tests' }
ChatPharoDebuggerContextTest >> testCaptureStackFromContext [

	| ctx |
	"Trigger an error and capture context from the handler"
	[ 1 / 0 ]
		on: ZeroDivide
		do: [ :ex |
			ctx := ChatPharoDebuggerContext new.
			ctx captureStackFrom: thisContext.
			self assert: ctx stackTrace notNil.
			self assert: ctx stackTrace notEmpty.
			self assert: (ctx stackTrace first includesSubstring: 'ChatPharoDebuggerContextTest') ]
]

{ #category : 'tests' }
ChatPharoDebuggerContextTest >> testClassHierarchyAccessors [

	| ctx hierarchy |
	ctx := ChatPharoDebuggerContext new.
	self assert: ctx classHierarchy isNil.
	hierarchy := OrderedCollection with: (Dictionary with: 'name' -> 'Object').
	ctx classHierarchy: hierarchy.
	self assert: ctx classHierarchy equals: hierarchy
]

{ #category : 'tests' }
ChatPharoDebuggerContextTest >> testDiagnosticPromptContainsClassHierarchy [

	| ctx prompt |
	ctx := ChatPharoDebuggerContext new.
	ctx classHierarchy: (OrderedCollection
		with: (Dictionary with: 'name' -> 'MyClass' with: 'instanceVariables' -> #( 'x' 'y' ))
		with: (Dictionary with: 'name' -> 'Object' with: 'instanceVariables' -> #())).
	prompt := ctx diagnosticPrompt.
	self assert: (prompt includesSubstring: 'Class Hierarchy').
	self assert: (prompt includesSubstring: 'MyClass').
	self assert: (prompt includesSubstring: 'x')
]

{ #category : 'tests' }
ChatPharoDebuggerContextTest >> testDiagnosticPromptContainsErrorInfo [

	| ctx prompt |
	ctx := ChatPharoDebuggerContext new.
	ctx errorClassName: 'MessageNotUnderstood'.
	ctx errorMessage: 'UndefinedObject>>foo'.
	ctx failingClassName: 'MyClass'.
	ctx failingSelector: 'doSomething'.
	ctx failingMethodSource: 'doSomething
	^ self foo'.
	ctx stackTrace: #( 'MyClass>>doSomething' 'UndefinedObject(Object)>>doesNotUnderstand:' ).
	ctx localVariables: (Dictionary with: 'temp' -> '42').
	ctx receiverClassName: 'MyClass'.
	ctx receiverState: (Dictionary with: 'name' -> '''hello''').

	prompt := ctx diagnosticPrompt.

	self assert: (prompt includesSubstring: 'MessageNotUnderstood').
	self assert: (prompt includesSubstring: 'UndefinedObject>>foo').
	self assert: (prompt includesSubstring: 'MyClass').
	self assert: (prompt includesSubstring: 'doSomething').
	self assert: (prompt includesSubstring: 'self foo').
	self assert: (prompt includesSubstring: 'MyClass>>doSomething').
	self assert: (prompt includesSubstring: 'temp').
	self assert: (prompt includesSubstring: '42').
	self assert: (prompt includesSubstring: 'hello')
]

{ #category : 'tests' }
ChatPharoDebuggerContextTest >> testDiagnosticPromptContainsFailingExpression [
	| ctx prompt |
	ctx := ChatPharoDebuggerContext new.
	ctx errorClassName: 'MessageNotUnderstood'.
	ctx errorMessage: 'receiver was nil'.
	ctx failingExpression: 'self foo bar'.
	prompt := ctx diagnosticPrompt.
	self assert: (prompt includesSubstring: 'Failing expression').
	self assert: (prompt includesSubstring: 'self foo bar')
]

{ #category : 'tests' }
ChatPharoDebuggerContextTest >> testDiagnosticPromptContainsStackFrameDetails [

	| ctx prompt |
	ctx := ChatPharoDebuggerContext new.
	ctx stackFrameDetails: (OrderedCollection
		with: (Dictionary
			with: 'method' -> 'MyClass>>foo'
			with: 'locals' -> (Dictionary with: 'x' -> '10')
			with: 'pc' -> 5
			with: 'source' -> 'foo ^ x')
		with: (Dictionary
			with: 'method' -> 'MyClass>>bar'
			with: 'locals' -> (Dictionary with: 'y' -> '20')
			with: 'pc' -> 8
			with: 'source' -> 'bar ^ self foo')).
	prompt := ctx diagnosticPrompt.
	self assert: (prompt includesSubstring: 'Nearby Stack Frames').
	self assert: (prompt includesSubstring: 'MyClass>>foo').
	self assert: (prompt includesSubstring: 'MyClass>>bar')
]

{ #category : 'tests' }
ChatPharoDebuggerContextTest >> testDiagnosticPromptWithMinimalInfo [

	| ctx prompt |
	ctx := ChatPharoDebuggerContext new.
	prompt := ctx diagnosticPrompt.
	self assert: (prompt includesSubstring: 'debugging an error').
	self assert: (prompt includesSubstring: 'Unknown')
]

{ #category : 'tests' }
ChatPharoDebuggerContextTest >> testFailingExpressionAccessors [

	| ctx |
	ctx := ChatPharoDebuggerContext new.
	self assert: ctx failingExpression isNil.
	ctx failingExpression: 'self foo'.
	self assert: ctx failingExpression equals: 'self foo'
]

{ #category : 'tests' }
ChatPharoDebuggerContextTest >> testForErrorMethod [

	| ctx method |
	method := Object >> #yourself.
	ctx := ChatPharoDebuggerContext forError: 'Something went wrong' method: method.
	self assert: ctx errorClassName equals: 'Error'.
	self assert: ctx errorMessage equals: 'Something went wrong'.
	self assert: ctx failingClassName equals: 'Object'.
	self assert: ctx failingSelector equals: 'yourself'
]

{ #category : 'tests' }
ChatPharoDebuggerContextTest >> testFromDebuggerBuildsContextFromDebuggerSession [
	"Regression for the empty-snapshot bug: fromDebugger: asked for the
	 old #debugSession accessor, which StDebugger does not understand in
	 Pharo 13 (the accessor is #session), so every real debugger answered
	 an empty context and the prompt said 'Unknown'/'No message'."

	| context process session stub ctx |
	context := [ ^ 1 + 1 ] asContext.
	process := Process
		           forContext: context
		           priority: Processor userInterruptPriority.
	session := DebugSession
		           named: 'test fromDebugger'
		           on: process
		           startedAt: context.
	session exception: (Error new messageText: 'stub failure').
	stub := ChatPharoDebuggerStub new session: session.
	ctx := ChatPharoDebuggerContext fromDebugger: stub.
	self assert: ctx errorClassName equals: 'Error'.
	self assert: ctx errorMessage equals: 'stub failure'.
	self assert: ctx stackTrace isNotEmpty
]

{ #category : 'tests' }
ChatPharoDebuggerContextTest >> testFromDebuggerWithoutSessionAnswersEmptyContext [

	| ctx |
	ctx := ChatPharoDebuggerContext fromDebugger:
		       ChatPharoDebuggerStub new.
	self assert: ctx errorClassName isNil.
	self assert: ctx errorMessage isNil.
	self assert: (ctx diagnosticPrompt includesSubstring: 'Unknown').
	self assert: (ctx diagnosticPrompt includesSubstring: 'No message')
]

{ #category : 'tests' }
ChatPharoDebuggerContextTest >> testStackFrameDetailsAccessors [

	| ctx frames |
	ctx := ChatPharoDebuggerContext new.
	self assert: ctx stackFrameDetails isNil.
	frames := OrderedCollection with: (Dictionary with: 'method' -> 'MyClass>>foo').
	ctx stackFrameDetails: frames.
	self assert: ctx stackFrameDetails equals: frames
]

{ #category : 'tests' }
ChatPharoDebuggerContextTest >> testSystemPromptForDebugging [

	| ctx prompt |
	ctx := ChatPharoDebuggerContext new.
	prompt := ctx systemPromptForDebugging.
	self assert: (prompt includesSubstring: 'expert').
	self assert: (prompt includesSubstring: 'Pharo').
	self assert: (prompt includesSubstring: 'debugger').
	self assert: (prompt includesSubstring: 'MessageNotUnderstood').
	self assert: (prompt includesSubstring: 'suggest_fix_code')
]
