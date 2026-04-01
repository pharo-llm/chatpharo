"
A session-scoped registry for **temporal tools** that the AI model creates at runtime.
Temporal tools are tools that the model generates dynamically during a conversation to solve
specific tasks, then deletes when they are no longer needed. This enables the model to extend
its own capabilities on-the-fly without permanently modifying the system.
* `current` returns the singleton registry for the active session.
* `createToolNamed:description:parameters:code:` compiles and registers a new temporal tool.
* `deleteToolNamed:` removes a tool by name.
* `deleteAllTools` cleans up all temporal tools (called at session end).
* `tools` returns the current set of temporal tools as `ChatPharoClient` instances.
**Lifecycle:**
1. Model calls `create_temporal_tool` -> tool is compiled and registered here.
2. On the next API round-trip the tool appears in the `tools` array sent to the LLM.
3. Model can call the temporal tool like any other tool.
4. Model calls `delete_temporal_tool` -> tool is removed.
5. At session end, `deleteAllTools` is called for safety.
**Why** -- gives the AI model the ability to dynamically extend its own toolset during a
conversation, without polluting the persistent custom-tools list or the browser environment.
"
Class {
	#name : 'ChatPharoTemporalToolRegistry',
	#superclass : 'Object',
	#instVars : [
		'temporalTools',
		'creationTimestamps'
	],
	#classInstVars : [
		'current'
	],
	#category : 'AI-ChatPharo-Tools-System Browser',
	#package : 'AI-ChatPharo-Tools',
	#tag : 'System Browser'
}

{ #category : 'accessing' }
ChatPharoTemporalToolRegistry class >> current [
	"Return the singleton registry for the current session."

	^ current ifNil: [ current := self new ]
]

{ #category : 'accessing' }
ChatPharoTemporalToolRegistry class >> reset [
	"Reset the singleton, deleting all temporal tools."
<script>
	current ifNotNil: [ :reg | reg deleteAllTools ].
	current := nil
]

{ #category : 'as yet unclassified' }
ChatPharoTemporalToolRegistry >> createToolNamed: aName description: aDescription parameters: aParametersSchema code: aCodeString [
	"Create a temporal tool, compile its code, and register it.
	 Returns a Dictionary with success/error status."

	| nameError codeError client compiledBlock normalizedCode |
	"Validate name"
	aName isEmptyOrNil ifTrue: [ ^ Dictionary with: 'error' -> 'Tool name is required' ].
	(aName allSatisfy: [ :c | c isAlphaNumeric or: [ c = $_ ] ]) ifFalse: [
		^ Dictionary with: 'error' -> 'Tool name must contain only letters, numbers, and underscores' ]. "Check for name conflicts with existing temporal tools"
	(self hasToolNamed: aName) ifTrue: [
			^ Dictionary with:
				  'error' -> ('A temporal tool named "' , aName , '" already exists. Delete it first or choose a different name.') ]. "Validate code syntax"
			
			normalizedCode := self normalizeLineEndingsToCr: aCodeString.
	[ OCParser parseExpression: '[ :arguments | ' , normalizedCode , ' ]' ]
		on: OCCodeError
		do: [ :error |
				^ Dictionary with: 'error' -> ('Syntax error in tool code at position {1}: {2}' format: {
							   error position.
							   error messageText }) ]. "Compile and build the tool"
	[
		compiledBlock := Smalltalk compiler evaluate: '[ :arguments | ' , normalizedCode , ' ]'.
		client := ChatPharoClient
			          name: aName
			          description: aDescription
			          parameters:
			          (aParametersSchema ifNil: [
				           Dictionary with: 'type' -> 'object' with: 'properties' -> Dictionary new with: 'required' -> #(  ) ])
			          block: [ :arguments |
					          [ compiledBlock value: arguments ]
						          on: Error
						          do: [ :e | Dictionary with: 'error' -> e messageText ] ].

		temporalTools at: aName put: client.
		creationTimestamps at: aName put: DateAndTime now.

		Dictionary
			with: 'success' -> true
			with: 'tool_name' -> aName
			with:
			'message' -> ('Temporal tool "' , aName , '" created successfully. It is now available for use in subsequent tool calls.') ]
		on: Error
		do: [ :e | Dictionary with: 'error' -> ('Failed to compile tool: ' , e messageText) ]
]

{ #category : 'as yet unclassified' }
ChatPharoTemporalToolRegistry >> deleteAllTools [
	"Remove all temporal tools. Called at session cleanup."

	| names |
	names := temporalTools keys asArray.
	temporalTools removeAll.
	creationTimestamps removeAll.
	^ Dictionary
		with: 'success' -> true
		with: 'deleted_tools' -> names
		with: 'message' -> ('Deleted all ' , names size asString , ' temporal tool(s).')
]

{ #category : 'as yet unclassified' }
ChatPharoTemporalToolRegistry >> deleteToolNamed: aName [
	"Remove a temporal tool by name."

	(self hasToolNamed: aName) ifFalse: [
		^ Dictionary with: 'error' -> ('No temporal tool named "' , aName , '" found.') ].

	temporalTools removeKey: aName.
	creationTimestamps removeKey: aName ifAbsent: [].
	^ Dictionary
		with: 'success' -> true
		with: 'tool_name' -> aName
		with: 'message' -> ('Temporal tool "' , aName , '" has been deleted.')
]

{ #category : 'as yet unclassified' }
ChatPharoTemporalToolRegistry >> hasToolNamed: aName [
	"Check if a temporal tool with the given name exists."

	^ temporalTools includesKey: aName
]

{ #category : 'as yet unclassified' }
ChatPharoTemporalToolRegistry >> initialize [

	super initialize.
	temporalTools := OrderedDictionary new.
	creationTimestamps := Dictionary new
]

{ #category : 'as yet unclassified' }
ChatPharoTemporalToolRegistry >> listTools [
	"Return a description of all temporal tools."

	^ Dictionary
		with: 'temporal_tools' -> (temporalTools associations collect: [ :assoc |
			Dictionary
				with: 'name' -> assoc key
				with: 'description' -> assoc value description
				with: 'created_at' -> (creationTimestamps at: assoc key ifAbsent: [ 'unknown' ]) asString ])
		with: 'count' -> temporalTools size
]

{ #category : 'as yet unclassified' }
ChatPharoTemporalToolRegistry >> normalizeLineEndingsToCr: aString [
	"Normalize incoming code to Pharo-style CR line endings."

	| normalized |
	normalized := aString copyReplaceAll: String crlf with: String cr.
	^ normalized copyReplaceAll: String lf with: String cr
]

{ #category : 'registration' }
ChatPharoTemporalToolRegistry >> registerClient: aChatPharoClient [
	"Register a pre-built ChatPharoClient as a temporal tool.
	 Used by the debugger environment to inject debugger-specific tools."

	(self hasToolNamed: aChatPharoClient name) ifTrue: [ ^ self ].
	temporalTools at: aChatPharoClient name put: aChatPharoClient.
	creationTimestamps at: aChatPharoClient name put: DateAndTime now
]

{ #category : 'as yet unclassified' }
ChatPharoTemporalToolRegistry >> size [
	"Return the number of registered temporal tools."

	^ temporalTools size
]

{ #category : 'as yet unclassified' }
ChatPharoTemporalToolRegistry >> toolNamed: aName [
	"Return the ChatPharoClient for the given temporal tool name, or nil."

	^ temporalTools at: aName ifAbsent: [ nil ]
]

{ #category : 'as yet unclassified' }
ChatPharoTemporalToolRegistry >> tools [
	"Return all temporal tools as an OrderedCollection of ChatPharoClient."

	^ temporalTools values asOrderedCollection
]
