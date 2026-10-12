"
Metadata wrapper for **one tool/function**.

* Stores `name`, human `description`, JSON `parameters` schema, and the executable Smalltalk block.
* Can be serialised into the format expected by OpenAI’s `tool` array.
* **Why** – clean separation between *declaring* a tool (what it is) and *executing* it (done later by `ChatPharoTool` when the assistant calls it).
"
Class {
	#name : 'ChatPharoClient',
	#superclass : 'Object',
	#instVars : [
		'name',
		'description',
		'parameters',
		'block',
		'cachedOpenAIChatTool',
		'mutating'
	],
	#category : 'AI-ChatPharo-Tools-Core',
	#package : 'AI-ChatPharo-Tools',
	#tag : 'Core'
}

{ #category : 'instance creation' }
ChatPharoClient class >> name: n description: d parameters: p block: b [ 

	^ self basicNew
		initializeWithName: n description: d parameters: p block: b;
		yourself
]

{ #category : 'examples' }
ChatPharoClient class >> toolCheckSyntax [ 

        <sampleInstance>
        ^ self
                  name: 'check_syntax'
                  description: 'Checks if the given Smalltalk code has valid syntax.'
                  parameters: (Dictionary
                                   with: 'type' -> 'object'
                                   with: 'properties' -> (Dictionary with: 'code' -> (Dictionary
                                                             with: 'type' -> 'string'
                                                             with:
                                                             'description' -> 'The Smalltalk code to validate'))
                                   with: 'required' -> #( 'code' ))
                  block: [ :arguments |
                                  | code result |
                                  code := arguments at: 'code'.
                                  [ :exitBlock |
                                          [ OCParser parseExpression: code ]
                                                  on: OCCodeError
                                                  do: [ :error |
                                                                  result := Dictionary with: 'syntax_error'
                                                                          -> ('Syntax error in given code at position {1}: {2}'
                                                                                  format: { error position. error messageText }).
                                                                  exitBlock value ].
                                          result := Dictionary with: 'syntax_ok' -> true ]
                                          valueWithExit.
                                  result ]
]

{ #category : 'examples' }
ChatPharoClient class >> toolEvaluateExpression [

	<sampleInstance>
	| settings |
	^ self
		  name: 'evaluate_expression'
		  description: 'Evaluates a Smalltalk expression in the user''s Pharo image. Execution may be sandboxed for security.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> (Dictionary with:
						    'expression' -> (Dictionary with: 'type' -> 'string' with: 'description' -> 'The Smalltalk expression to evaluate'))
				   with: 'required' -> #( 'expression' ))
		  block: [ :arguments |
				  | expression result settings |
				  expression := arguments at: 'expression'.
				  settings := ChatPharoSettings default. "Use sandbox if enabled"
				  settings sandboxEnabled ifTrue: [
						  | sandbox sandboxResult |
						  sandbox := settings newConfiguredSandbox.
						  sandboxResult := sandbox evaluate: expression.
						  sandboxResult isSuccess
							  ifTrue: [ result := Dictionary with: 'value' -> sandboxResult value asString ]
							  ifFalse: [
									  result := sandboxResult hasViolations
										            ifTrue: [
										            Dictionary
											            with: 'sandbox_blocked' -> sandboxResult errorMessage
											            with: 'violations' -> sandboxResult violations ]
										            ifFalse: [ Dictionary with: 'evaluation_error' -> sandboxResult errorMessage ] ].
						  ^ result ]. "Direct evaluation when sandbox is disabled"
				  [ :exitBlock |
					  [ OCParser parseExpression: expression ]
						  on: OCCodeError
						  do: [ :error |
								  result := Dictionary with: 'syntax_error' -> ('Syntax error in given expression at position {1}: {2}' format: {
											             error position.
											             error messageText }).
								  exitBlock value ].
					  [ result := Smalltalk compiler evaluate: expression ]
						  on: Error
						  do: [ :error |
								  result := Dictionary with: 'evaluation_error' -> error asString.
								  exitBlock value ].
					  result := Dictionary with: 'value' -> result asString ] valueWithExit.
				  result ]
]

{ #category : 'examples' }
ChatPharoClient class >> toolGetCurrentWeather [

	<sampleInstance>
	| weatherDataPerCity |
	weatherDataPerCity := Dictionary with: 'Paris' -> (Dictionary
			                       with: 'degrees_centigrade' -> 10
			                       with: 'precipitation' -> 'rain').
	^ self
		  name: 'get_current_weather'
		  description: 'Get the current weather for a city.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> (Dictionary with: 'city' -> (Dictionary
							     with: 'type' -> 'string'
							     with: 'description' -> 'The name of the city'))
				   with: 'required' -> #( 'city' ))
		  block: [ :arguments |
				  (arguments at: 'city') in: [ :city |
						  weatherDataPerCity at: city ifAbsent: [
							  Dictionary with:
								  'error' -> ('No weather data available for ' , city) ] ] ]
]

{ #category : 'examples' }
ChatPharoClient class >> toolOpenPlayground [

	<sampleInstance>
	| settings |
	^ self
		  name: 'open_playground'
		  description: (' ' join: #( 'Opens a Pharo Playground with the given Smalltalk code in the user''s image so that the user'
				      'can edit and execute the code. As this opens another window, use only when sure it''s what the user intended,'
				      'or ask first. Use this to give code examples. If the code has a syntax error, the error is reported to you and'
				      'no Playground is opened. Note: Code opened in playground is NOT sandboxed - user executes manually.' ))
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> (Dictionary with:
						    'code' -> (Dictionary with: 'type' -> 'string' with: 'description' -> 'The Pharo Smalltalk code for the Playground'))
				   with: 'required' -> #( 'code' ))
		  block: [ :arguments |
				  | code result |
				  code := arguments at: 'code'.
				 settings := ChatPharoSettings default.

				  "If sandbox is enabled, validate code before opening playground"
				  settings sandboxEnabled ifTrue: [
					  | sandbox validation |
					  sandbox := settings newConfiguredSandbox.
					  validation := sandbox validateCode: code.
					  validation isInvalid ifTrue: [
						  ^ Dictionary
							  with: 'warning' -> 'Code contains potentially dangerous operations'
							  with: 'violations' -> validation violations
							  with: 'playground_opened' -> false ] ].
				  [ :exitBlock |
					  [ OCParser parseExpression: code ]
						  on: OCCodeError
						  do: [ :error |
								  result := Dictionary with: 'syntax_error' -> ('Syntax error in given code at position {1}: {2}' format: {
											             error position.
											             error messageText }).
								  exitBlock value ].
					  StPlayground openContents: code.
					  result := Dictionary
						  with: 'playground_opened' -> true
						  with: 'sandbox_validated' -> settings sandboxEnabled ]valueWithExit.
				  result ]
]

{ #category : 'initialization' }
ChatPharoClient >> applyTo: json [ 

	^ block value: json
]

{ #category : 'accessing' }
ChatPharoClient >> beMutating [
	"Declare that running me changes the image, opens windows or runs arbitrary code,
	 so the user is asked before each call."

	mutating := true
]

{ #category : 'accessing' }
ChatPharoClient >> block [

	^ block
]

{ #category : 'accessing' }
ChatPharoClient >> block: anObject [

	block := anObject
]

{ #category : 'accessing' }
ChatPharoClient >> description [

	^ description
]

{ #category : 'accessing' }
ChatPharoClient >> description: anObject [

	description := anObject.
	cachedOpenAIChatTool := nil
]

{ #category : 'initialization' }
ChatPharoClient >> initializeWithName: n description: d parameters: p block: b [ 

	super initialize.
	name := n. description := d. parameters := p. block := b.
]

{ #category : 'accessing' }
ChatPharoClient >> inputSchema [

	^ self parameters
]

{ #category : 'accessing' }
ChatPharoClient >> inputSchema: anObject [

	self parameters: anObject
]

{ #category : 'testing' }
ChatPharoClient >> isMutating [

	^ mutating ifNil: [ false ]
]

{ #category : 'accessing' }
ChatPharoClient >> name [

	^ name
]

{ #category : 'accessing' }
ChatPharoClient >> name: anObject [

	name := anObject.
	cachedOpenAIChatTool := nil
]

{ #category : 'accessing' }
ChatPharoClient >> openAIChatTool [

   ^ cachedOpenAIChatTool ifNil: [
		cachedOpenAIChatTool := Dictionary
			with: 'type' -> 'function'
			with: 'function' -> (Dictionary
				with: 'name' -> self name
				with: 'description' -> self description
				with: 'parameters' -> self parameters) ]
]

{ #category : 'accessing' }
ChatPharoClient >> parameters [

	^ parameters
]

{ #category : 'accessing' }
ChatPharoClient >> parameters: anObject [

	parameters := anObject.
	cachedOpenAIChatTool := nil
]
