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
		'programCounter',
		'stackFrameDetails',
		'classHierarchy',
		'failingExpression'
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
	"Build a full snapshot from a live StDebugger presenter.
	 The session of an open debugger is reached with #session (Pharo 13+;
	 #debugSession was the accessor of older NewTools releases, which this
	 project does not target anymore)."

	| session |
	session := aStDebugger session.
	session ifNil: [ ^ self new ].
	^ self fromDebugSession: session
]

{ #category : 'building' }
ChatPharoDebuggerContext >> captureClassHierarchy: aContext [
	"Capture the class hierarchy of the receiver to help the LLM
	 understand inheritance context."

	classHierarchy := OrderedCollection new.
	[
		| cls |
		cls := aContext receiver class.
		[ cls notNil and: [ classHierarchy size < 10 ] ] whileTrue: [
			| entry |
			entry := Dictionary new.
			entry at: 'name' put: cls name asString.
			entry at: 'instanceVariables' put: (cls instVarNames collect: #asString) asArray.
			entry at: 'protocols' put: ([ cls protocolNames collect: #asString ]
				on: Error do: [ #() ]) asArray.
			classHierarchy add: entry.
			cls := cls superclass ] ]
		on: Error do: [ "ignore hierarchy capture errors" ]
]

{ #category : 'building' }
ChatPharoDebuggerContext >> captureContextInfo: aContext [
	"Extract method source, locals, and receiver state from a context."

	| method |
	method := aContext method.
	self captureMethodInfo: method.
	programCounter := aContext pc. "--- Local variables (temps + args) ---"
	localVariables := Dictionary new.
	[
		aContext tempNames doWithIndex: [ :name :idx |
				| val |
				val := [ (aContext tempAt: idx) printString ]
					       on: Error
					       do: [ :e | '<error: ' , e messageText , '>' ].
				localVariables at: name put: (val copyFrom: 1 to: (val size min: 500)) ] ]
		on: Error
		do: [ "ignore if we cannot read temps" ]. "--- Receiver instance variables ---"
	receiverState := Dictionary new.
	receiverClassName := [ aContext receiver class name asString ]
		                     on: Error
		                     do: [ 'Unknown' ].
	[
		| receiver |
		receiver := aContext receiver.
		receiver class allInstVarNames doWithIndex: [ :name :idx |
				| val |
				val := [ (receiver instVarAt: idx) printString ]
					       on: Error
					       do: [ :e | '<error>' ].
				receiverState at: name put: (val copyFrom: 1 to: (val size min: 500)) ] ]
		on: Error
		do: [ "ignore if we cannot read ivars" ].
		"--- Failing expression via AST ---"
	self captureFailingExpression: aContext.

	"--- Class hierarchy ---"
	self captureClassHierarchy: aContext.

	"--- Multi-frame details (top N frames with locals) ---"
	self captureStackFrameDetails: aContext
]

{ #category : 'building' }
ChatPharoDebuggerContext >> captureFailingExpression: aContext [
	"Use the AST to identify the specific expression at the program counter."

	failingExpression := [
		| method ast node |
		method := aContext method.
		ast := method ast.
		node := ast bestNodeFor: (aContext pc to: aContext pc).
		node
			ifNotNil: [ node source ]
			ifNil: [ nil ] ]
		on: Error do: [ nil ]
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
ChatPharoDebuggerContext >> captureStackFrameDetails: aContext [
	"Capture detailed info for the top N stack frames, including
	 local variables for each frame — not just the top one."

	| ctx maxDetailFrames frameLocals |
	maxDetailFrames := 5.
	stackFrameDetails := OrderedCollection new.
	ctx := aContext.
	[ ctx notNil and: [ stackFrameDetails size < maxDetailFrames ] ] whileTrue: [
		| frame |
		frame := Dictionary new.
		[
			frame at: 'method' put: (ctx method methodClass name , '>>' , ctx method selector asString).
			frame at: 'source' put: ([ ctx method sourceCode copyFrom: 1 to: (ctx method sourceCode size min: 1000) ]
				on: Error do: [ '' ]).
			frame at: 'pc' put: ctx pc.

			"Capture locals for this frame"
			frameLocals := Dictionary new.
			[ ctx tempNames doWithIndex: [ :name :idx |
				| val |
				val := [ (ctx tempAt: idx) printString ]
					on: Error do: [ :e | '<error>' ].
				frameLocals at: name put: (val copyFrom: 1 to: (val size min: 300)) ] ]
				on: Error do: [ "ignore" ].
			frame at: 'locals' put: frameLocals ]
			on: Error do: [ frame at: 'method' put: 'Unknown>>unknown' ].
		stackFrameDetails add: frame.
		ctx := ctx sender ]
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
ChatPharoDebuggerContext >> classHierarchy [

	^ classHierarchy
]

{ #category : 'building' }
ChatPharoDebuggerContext >> classHierarchy: anOrderedCollection [

	classHierarchy := anOrderedCollection
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
		stream nextPutAll: '**Message**: '; nextPutAll: (errorMessage ifNil: [ 'No message' ]); cr.
		failingExpression ifNotNil: [ :expr |
			stream nextPutAll: '**Failing expression**: `'; nextPutAll: expr; nextPutAll: '`'; cr ].
		stream cr.
		stream nextPutAll: '## Failing Method'; cr.
		failingClassName ifNotNil: [
			stream nextPutAll: '**Class**: '; nextPutAll: failingClassName; cr ].
		failingSelector ifNotNil: [
			stream nextPutAll: '**Selector**: '; nextPutAll: failingSelector; cr ].
		failingPackageName ifNotNil: [
			stream nextPutAll: '**Package**: '; nextPutAll: failingPackageName; cr ].
		stream cr.
				programCounter ifNotNil: [
			stream nextPutAll: '**Program counter**: '; nextPutAll: programCounter asString; cr ].
		failingMethodSource ifNotNil: [ :src |
			src isEmpty ifFalse: [
				stream nextPutAll: '```smalltalk'; cr.
				stream nextPutAll: src; cr.
				stream nextPutAll: '```'; cr; cr ] ].

		"--- Local variables ---"
		(localVariables notNil and: [ localVariables notEmpty ]) ifTrue: [
			stream nextPutAll: '## Local Variables (failing frame)'; cr.
			localVariables keysAndValuesDo: [ :name :value |
				stream nextPutAll: '- **'; nextPutAll: name; nextPutAll: '**: '; nextPutAll: value; cr ].
			stream cr ].
		
		"--- Class hierarchy ---"
		(classHierarchy notNil and: [ classHierarchy notEmpty ]) ifTrue: [
			stream nextPutAll: '## Class Hierarchy'; cr.
			classHierarchy do: [ :entry |
				| ivars |
				stream nextPutAll: '- **'; nextPutAll: (entry at: 'name'); nextPutAll: '**'.
				ivars := entry at: 'instanceVariables' ifAbsent: [ #() ].
				ivars ifNotEmpty: [
					stream nextPutAll: ' (ivars: '.
					ivars
						do: [ :iv | stream nextPutAll: iv ]
						separatedBy: [ stream nextPutAll: ', ' ].
					stream nextPutAll: ')' ].
				stream cr ].
			stream cr ].

		"--- Multi-frame details ---"
		(stackFrameDetails notNil and: [ stackFrameDetails size > 1 ]) ifTrue: [
			stream nextPutAll: '## Nearby Stack Frames (with locals)'; cr.
			stackFrameDetails doWithIndex: [ :frame :idx |
				| frameLocals |
				stream nextPutAll: '### Frame '; nextPutAll: idx asString;
					nextPutAll: ': '; nextPutAll: (frame at: 'method' ifAbsent: [ 'Unknown' ]); cr.
				frameLocals := frame at: 'locals' ifAbsent: [ Dictionary new ].
				frameLocals ifNotEmpty: [
					frameLocals keysAndValuesDo: [ :name :value |
						stream nextPutAll: '  - '; nextPutAll: name; nextPutAll: ' = '; nextPutAll: value; cr ] ].
				stream cr ] ].

		"--- Stack trace ---"

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
		stream nextPutAll: 'Please analyze this error, explain what likely caused it, and suggest a concrete fix with Smalltalk code. ';
			nextPutAll: 'Use the available tools to look up senders, implementors, class hierarchies, or method sources if you need more context.' ]
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
ChatPharoDebuggerContext >> failingExpression [

	^ failingExpression
]

{ #category : 'building' }
ChatPharoDebuggerContext >> failingExpression: aString [

	failingExpression := aString
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
ChatPharoDebuggerContext >> stackFrameDetails [

	^ stackFrameDetails
]

{ #category : 'building' }
ChatPharoDebuggerContext >> stackFrameDetails: anOrderedCollection [

	stackFrameDetails := anOrderedCollection
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

	^ String streamContents: [ :s |
		s nextPutAll: 'You are an expert Pharo Smalltalk debugger assistant running inside the user''s live Pharo image. '.
		s nextPutAll: 'The user has hit an error and the debugger is open on the failing context. '.
		s cr; cr.
		s nextPutAll: 'Your job is to:'; cr.
		s nextPutAll: '1) Analyze the error, stack trace, local variables, and receiver state to identify the root cause.'; cr.
		s nextPutAll: '2) Explain clearly what went wrong, why it happened, and what the expected behaviour should be.'; cr.
		s nextPutAll: '3) Suggest a concrete fix with Smalltalk source code that the user can apply directly.'; cr.
		s nextPutAll: '4) If you need more context, use the available tools: look up senders, implementors, class hierarchies, or browse method sources in the live image.'; cr.
		s nextPutAll: '5) When proposing a fix, use the suggest_fix_code tool so the user can review it.'; cr.
		s cr.
		s nextPutAll: 'Pharo-specific guidelines:'; cr.
		s nextPutAll: '- MessageNotUnderstood errors usually mean nil receiver, wrong type, or missing method. Check the receiver class and value.'; cr.
		s nextPutAll: '- SubscriptOutOfBounds means a collection index is invalid. Check collection size vs the index.'; cr.
		s nextPutAll: '- NonBooleanReceiver errors mean a non-boolean was used in ifTrue:/ifFalse:. Check what the condition evaluates to.'; cr.
		s nextPutAll: '- Look at the full class hierarchy — the bug may be in an inherited method or a missing override.'; cr.
		s nextPutAll: '- Consider Pharo idioms: ensure:/ifCurtailed: for cleanup, on:do: for exception handling, lazy initialization with ifNil:.'; cr.
		s nextPutAll: '- Be precise: reference specific classes, selectors, and line numbers. Provide actionable fixes.' ]
]
