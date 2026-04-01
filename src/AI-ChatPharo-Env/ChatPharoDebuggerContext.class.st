"
Captures a **snapshot of a live debugger session** for the LLM.

Extracts the error/exception, the full stack trace, the method source at
the failing frame, local variable names and values, and the receiver's
instance-variable state.  Everything is turned into plain strings so it
can safely travel through JSON without holding live object references.

The snapshot is built once (via the class-side `fromDebugger:` factory)
and then consumed by `ChatPharoDebuggerEnvironment` to build both:
  1. a rich diagnostic prompt, and
  2. tool-call results when the LLM asks for more detail.

**Why** – the old `StAskChatPharoFromDebuggerCommand` only sent the
method source code to the LLM with zero error context.  This class
gives the LLM everything it needs to actually *diagnose* the bug.
"
Class {
	#name : 'ChatPharoDebuggerContext',
	#superclass : 'Object',
	#instVars : [
		'errorClassName',
		'errorMessage',
		'errorSignalerContext',
		'stackTrace',
		'failingMethodSource',
		'failingClassName',
		'failingSelector',
		'failingPackageName',
		'localVariables',
		'receiverState',
		'receiverClassName',
		'programCounter'
	],
	#category : 'AI-ChatPharo-Env-Debugger',
	#package : 'AI-ChatPharo-Env',
	#tag : 'Debugger'
}

{ #category : 'instance creation' }
ChatPharoDebuggerContext class >> forError: errorDescription method: aMethod [
	"Lightweight factory used when only a method + error string are
	 available (e.g. from tests or headless tooling)."

	^ self new
		  errorClassName: 'Error';
		  errorMessage: errorDescription;
		  captureMethodInfo: aMethod;
		  yourself
]

{ #category : 'instance creation' }
ChatPharoDebuggerContext class >> fromDebugSession: aDebugSession [
	"Build a full snapshot from a live StDebugger debug session."

	| instance interruptedCtx |
	instance := self new.
	interruptedCtx := aDebugSession interruptedContext.
	interruptedCtx ifNil: [ ^ instance ].
	
	(aDebugSession respondsTo: #exception)
		ifTrue: [
			| exc |
			exc := aDebugSession exception.
			exc ifNotNil: [
				instance errorClassName: exc class name asString.
				instance errorMessage: ([ exc messageText ] on: Error do: [ :e | exc printString ]) ] ]
		ifFalse: [
			instance errorClassName: 'Unknown'.
			instance errorMessage: (aDebugSession name ifNil: [ 'Unknown error' ]) ].

	instance captureStackFrom: interruptedCtx.

	instance captureContextInfo: interruptedCtx.

	^ instance
]

{ #category : 'instance creation' }
ChatPharoDebuggerContext class >> fromDebugger: aStDebugger [
	"Build a full snapshot from a live StDebugger presenter."

	| session |
	session := (aStDebugger respondsTo: #debugSession)
		           ifTrue: [ aStDebugger debugSession ]
		           ifFalse: [ nil ].
	session ifNil: [ ^ self new ].
	^ self fromDebugSession: session
]

{ #category : 'building' }
ChatPharoDebuggerContext >> captureContextInfo: aContext [
	"Extract method source, locals, and receiver state from a context."

	| method |
	method := aContext method.
	self captureMethodInfo: method.
	programCounter := aContext pc.

	"--- Local variables (temps + args) ---"
	localVariables := Dictionary new.
	[ aContext tempNames doWithIndex: [ :name :idx |
		| val |
		val := [ (aContext tempAt: idx) printString ]
			       on: Error do: [ :e | '<error: ' , e messageText , '>' ].
		localVariables at: name put: (val copyFrom: 1 to: (val size min: 500)) ] ]
		on: Error do: [ "ignore if we cannot read temps" ].

	"--- Receiver instance variables ---"
	receiverState := Dictionary new.
	receiverClassName := [ aContext receiver class name asString ]
		                     on: Error do: [ 'Unknown' ].
	[ | receiver |
	  receiver := aContext receiver.
	  receiver class allInstVarNames doWithIndex: [ :name :idx |
		  | val |
		  val := [ (receiver instVarAt: idx) printString ]
			         on: Error do: [ :e | '<error>' ].
		  receiverState at: name put: (val copyFrom: 1 to: (val size min: 500)) ] ]
		on: Error do: [ "ignore if we cannot read ivars" ]
]

{ #category : 'building' }
ChatPharoDebuggerContext >> captureMethodInfo: aMethod [
	"Extract basic method metadata."

	failingMethodSource := [ aMethod sourceCode ] on: Error do: [ '' ].
	failingClassName := [ aMethod methodClass name asString ] on: Error do: [ 'Unknown' ].
	failingSelector := [ aMethod selector asString ] on: Error do: [ 'unknown' ].
	failingPackageName := [
		| pkg |
		pkg := aMethod methodClass package.
		pkg ifNotNil: [ pkg name asString ] ifNil: [ nil ] ]
		on: Error do: [ nil ]
]

{ #category : 'building' }
ChatPharoDebuggerContext >> captureStackFrom: aContext [
	"Walk the context chain and capture a human-readable stack trace."

	| ctx frames maxFrames |
	maxFrames := 30.
	frames := OrderedCollection new.
	ctx := aContext.
	[ ctx notNil and: [ frames size < maxFrames ] ] whileTrue: [
		| frame |
		frame := [ ctx method methodClass name , '>>' , ctx method selector asString ]
			         on: Error do: [ 'Unknown>>unknown' ].
		frames add: frame.
		ctx := ctx sender ].
	stackTrace := frames asArray
]

{ #category : 'building' }
ChatPharoDebuggerContext >> diagnosticPrompt [
	"Build the full diagnostic prompt for the LLM."

	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'I am debugging an error in Pharo Smalltalk and I need your help to understand and fix it.';
			cr; cr.

		stream nextPutAll: '## Error'; cr.
		stream nextPutAll: '**Exception**: '; nextPutAll: (errorClassName ifNil: [ 'Unknown' ]); cr.
		stream nextPutAll: '**Message**: '; nextPutAll: (errorMessage ifNil: [ 'No message' ]); cr; cr.

		stream nextPutAll: '## Failing Method'; cr.
		failingClassName ifNotNil: [
			stream nextPutAll: '**Class**: '; nextPutAll: failingClassName; cr ].
		failingSelector ifNotNil: [
			stream nextPutAll: '**Selector**: '; nextPutAll: failingSelector; cr ].
		failingPackageName ifNotNil: [
			stream nextPutAll: '**Package**: '; nextPutAll: failingPackageName; cr ].
		stream cr.
		failingMethodSource ifNotNil: [ :src |
			src isEmpty ifFalse: [
				stream nextPutAll: '```smalltalk'; cr.
				stream nextPutAll: src; cr.
				stream nextPutAll: '```'; cr; cr ] ].

		"--- Local variables ---"
		(localVariables notNil and: [ localVariables notEmpty ]) ifTrue: [
			stream nextPutAll: '## Local Variables'; cr.
			localVariables keysAndValuesDo: [ :name :value |
				stream nextPutAll: '- **'; nextPutAll: name; nextPutAll: '**: '; nextPutAll: value; cr ].
			stream cr ].

		(receiverState notNil and: [ receiverState notEmpty ]) ifTrue: [
			stream nextPutAll: '## Receiver ('; nextPutAll: (receiverClassName ifNil: [ 'Unknown' ]); nextPutAll: ')'; cr.
			receiverState keysAndValuesDo: [ :name :value |
				stream nextPutAll: '- **'; nextPutAll: name; nextPutAll: '**: '; nextPutAll: value; cr ].
			stream cr ].

		(stackTrace notNil and: [ stackTrace notEmpty ]) ifTrue: [
			stream nextPutAll: '## Stack Trace (top '; nextPutAll: stackTrace size asString; nextPutAll: ' frames)'; cr.
			stackTrace doWithIndex: [ :frame :idx |
				stream nextPutAll: idx asString; nextPutAll: '. '; nextPutAll: frame; cr ] ].

		stream cr.
		stream nextPutAll: 'Please analyze this error, explain what likely caused it, and suggest a fix. ';
		nextPutAll: 'You have access to tools to inspect the Pharo image — use them if you need more context about any classes or methods in the stack.' ]
]

{ #category : 'building' }
ChatPharoDebuggerContext >> errorClassName [

	^ errorClassName
]

{ #category : 'building' }
ChatPharoDebuggerContext >> errorClassName: aString [

	errorClassName := aString
]

{ #category : 'building' }
ChatPharoDebuggerContext >> errorMessage [

	^ errorMessage
]

{ #category : 'building' }
ChatPharoDebuggerContext >> errorMessage: aString [

	errorMessage := aString
]

{ #category : 'building' }
ChatPharoDebuggerContext >> errorSignalerContext [

	^ errorSignalerContext
]

{ #category : 'building' }
ChatPharoDebuggerContext >> errorSignalerContext: aString [

	errorSignalerContext := aString
]

{ #category : 'building' }
ChatPharoDebuggerContext >> failingClassName [

	^ failingClassName
]

{ #category : 'building' }
ChatPharoDebuggerContext >> failingClassName: aString [

	failingClassName := aString
]

{ #category : 'building' }
ChatPharoDebuggerContext >> failingMethodSource [

	^ failingMethodSource
]

{ #category : 'building' }
ChatPharoDebuggerContext >> failingMethodSource: aString [

	failingMethodSource := aString
]

{ #category : 'building' }
ChatPharoDebuggerContext >> failingPackageName [

	^ failingPackageName
]

{ #category : 'building' }
ChatPharoDebuggerContext >> failingPackageName: aString [

	failingPackageName := aString
]

{ #category : 'building' }
ChatPharoDebuggerContext >> failingSelector [

	^ failingSelector
]

{ #category : 'building' }
ChatPharoDebuggerContext >> failingSelector: aString [

	failingSelector := aString
]

{ #category : 'building' }
ChatPharoDebuggerContext >> localVariables [

	^ localVariables
]

{ #category : 'building' }
ChatPharoDebuggerContext >> localVariables: aDictionary [

	localVariables := aDictionary
]

{ #category : 'building' }
ChatPharoDebuggerContext >> programCounter [

	^ programCounter
]

{ #category : 'building' }
ChatPharoDebuggerContext >> programCounter: anInteger [

	programCounter := anInteger
]

{ #category : 'building' }
ChatPharoDebuggerContext >> receiverClassName [

	^ receiverClassName
]

{ #category : 'building' }
ChatPharoDebuggerContext >> receiverClassName: aString [

	receiverClassName := aString
]

{ #category : 'building' }
ChatPharoDebuggerContext >> receiverState [

	^ receiverState
]

{ #category : 'building' }
ChatPharoDebuggerContext >> receiverState: aDictionary [

	receiverState := aDictionary
]

{ #category : 'building' }
ChatPharoDebuggerContext >> stackTrace [

	^ stackTrace
]

{ #category : 'building' }
ChatPharoDebuggerContext >> stackTrace: anArray [

	stackTrace := anArray
]

{ #category : 'building' }
ChatPharoDebuggerContext >> systemPromptForDebugging [
	"Return a system prompt that makes the LLM act as a Pharo debugger expert."

	^ 'You are an expert Pharo Smalltalk debugger assistant inside the user''s Pharo image. ',
	  'The user has hit an error and the debugger is open. Your job is to: ',
	  '1) Analyze the error, stack trace, and variable state to identify the root cause. ',
	  '2) Explain clearly what went wrong and why. ',
	  '3) Suggest a concrete fix with Smalltalk code. ',
	  '4) If you need more context about classes or methods, use the available tools to look them up. ',
	  'Be precise, reference specific classes and methods, and provide actionable fixes.'
]
