"
Provides **debugger-aware tools** to the LLM during an intelligent
debugging session.

Wraps a `ChatPharoDebuggerContext` snapshot and exposes tool functions
such as:
  * `get_error_details`     – the exception class, message, and signaler
  * `get_stack_trace`       – the call chain leading to the error
  * `get_local_variables`   – temps and args in the failing frame
  * `get_receiver_state`    – instance variables of the receiver
  * `get_method_source_in_stack` – source of any method visible in the stack

Combined with the regular `ChatPharoBrowserEnvironment` tools (which
let the LLM browse packages, classes, methods in the live image), this
gives the assistant everything it needs to diagnose bugs autonomously.

**Why** – the old debugger integration sent only a method's source and
asked 'explain this'.  This class turns ChatPharo into an actual
debugging partner that can reason over error context.
"
Class {
	#name : 'ChatPharoDebuggerEnvironment',
	#superclass : 'Object',
	#instVars : [
		'debuggerContext',
		'tools'
	],
	#category : 'AI-ChatPharo-Env-Debugger',
	#package : 'AI-ChatPharo-Env',
	#tag : 'Debugger'
}

{ #category : 'instance creation' }
ChatPharoDebuggerEnvironment class >> forContext: aChatPharoDebuggerContext [

	^ self basicNew
		  initializeWithContext: aChatPharoDebuggerContext;
		  yourself
]

{ #category : 'as yet unclassified' }
ChatPharoDebuggerEnvironment >> debuggerContext [ 

	^ debuggerContext
]

{ #category : 'as yet unclassified' }
ChatPharoDebuggerEnvironment >> functionGetErrorDetails [

	^ ChatPharoClient
		  name: 'get_error_details'
		  description: 'Returns the exception class name, error message, and failing method information from the current debugger session.'
		  parameters: (Dictionary
			   with: 'type' -> 'object'
			   with: 'properties' -> Dictionary new
			   with: 'required' -> #())
		  block: [ :arguments |
			  Dictionary new
				  at: 'exception_class' put: (debuggerContext errorClassName ifNil: [ 'Unknown' ]);
				  at: 'error_message' put: (debuggerContext errorMessage ifNil: [ 'No message' ]);
				  at: 'failing_class' put: (debuggerContext failingClassName ifNil: [ 'Unknown' ]);
				  at: 'failing_selector' put: (debuggerContext failingSelector ifNil: [ 'unknown' ]);
				  at: 'failing_package' put: (debuggerContext failingPackageName ifNil: [ 'Unknown' ]);
				  yourself ]
]

{ #category : 'as yet unclassified' }
ChatPharoDebuggerEnvironment >> functionGetLocalVariables [

	^ ChatPharoClient
		  name: 'get_local_variables'
		  description: 'Returns all local variable names and their current values from the failing stack frame (arguments and temporaries).'
		  parameters: (Dictionary
			   with: 'type' -> 'object'
			   with: 'properties' -> Dictionary new
			   with: 'required' -> #())
		  block: [ :arguments |
			  | vars |
			  vars := debuggerContext localVariables.
			  (vars isNil or: [ vars isEmpty ])
				  ifTrue: [ Dictionary with: 'info' -> 'No local variables captured' ]
				  ifFalse: [
					  Dictionary
						  with: 'variables' -> vars
						  with: 'count' -> vars size ] ]
]

{ #category : 'as yet unclassified' }
ChatPharoDebuggerEnvironment >> functionGetMethodSourceInStack [

	^ ChatPharoClient
		  name: 'get_method_source_in_stack'
		  description: 'Returns the source code of any method visible in the stack trace. Provide the class name and selector.'
		  parameters: (Dictionary
			   with: 'type' -> 'object'
			   with: 'properties' -> (Dictionary
					    with: 'class_name' -> (Dictionary
							 with: 'type' -> 'string'
							 with: 'description' -> 'The class name (e.g. OrderedCollection)')
					    with: 'selector' -> (Dictionary
							 with: 'type' -> 'string'
							 with: 'description' -> 'The method selector (e.g. add:)'))
			   with: 'required' -> #( 'class_name' 'selector' ))
		  block: [ :arguments |
			  | className selector theClass method |
			  className := arguments at: 'class_name'.
			  selector := arguments at: 'selector'.
			  theClass := Smalltalk classNamed: className.
			  theClass ifNil: [
				  ^ Dictionary with: 'error' -> ('Class not found: ' , className) ].
			  method := theClass lookupSelector: selector asSymbol.
			  method ifNil: [
				  ^ Dictionary with: 'error' -> ('Method not found: ' , className , '>>' , selector) ].
			  Dictionary
				  with: 'class' -> className
				  with: 'selector' -> selector
				  with: 'source' -> method sourceCode
				  with: 'protocol' -> method protocolName ]
]

{ #category : 'as yet unclassified' }
ChatPharoDebuggerEnvironment >> functionGetReceiverState [

	^ ChatPharoClient
		  name: 'get_receiver_state'
		  description: 'Returns the instance variable names and values of the receiver (self) in the failing stack frame.'
		  parameters: (Dictionary
			   with: 'type' -> 'object'
			   with: 'properties' -> Dictionary new
			   with: 'required' -> #())
		  block: [ :arguments |
			  | state |
			  state := debuggerContext receiverState.
			  (state isNil or: [ state isEmpty ])
				  ifTrue: [ Dictionary with: 'info' -> 'No receiver state captured' ]
				  ifFalse: [
					  Dictionary
						  with: 'receiver_class' -> (debuggerContext receiverClassName ifNil: [ 'Unknown' ])
						  with: 'instance_variables' -> state
						  with: 'count' -> state size ] ]
]

{ #category : 'as yet unclassified' }
ChatPharoDebuggerEnvironment >> functionGetStackTrace [

	^ ChatPharoClient
		  name: 'get_stack_trace'
		  description: 'Returns the full stack trace from the debugger session, showing the call chain that led to the error.'
		  parameters: (Dictionary
			   with: 'type' -> 'object'
			   with: 'properties' -> Dictionary new
			   with: 'required' -> #())
		  block: [ :arguments |
			  | trace |
			  trace := debuggerContext stackTrace.
			  (trace isNil or: [ trace isEmpty ])
				  ifTrue: [ Dictionary with: 'info' -> 'No stack trace captured' ]
				  ifFalse: [
					  Dictionary
						  with: 'frames' -> trace
						  with: 'depth' -> trace size ] ]
]

{ #category : 'as yet unclassified' }
ChatPharoDebuggerEnvironment >> functionSuggestFix [

	^ ChatPharoClient
		  name: 'suggest_fix_code'
		  description: 'After analyzing the error, use this tool to propose a concrete code fix. Provide the class, selector, and corrected Smalltalk source.'
		  parameters: (Dictionary
			   with: 'type' -> 'object'
			   with: 'properties' -> (Dictionary
					    with: 'class_name' -> (Dictionary
							 with: 'type' -> 'string'
							 with: 'description' -> 'The class containing the method to fix')
					    with: 'selector' -> (Dictionary
							 with: 'type' -> 'string'
							 with: 'description' -> 'The selector of the method to fix')
					    with: 'fixed_source' -> (Dictionary
							 with: 'type' -> 'string'
							 with: 'description' -> 'The corrected Smalltalk source code for the method'))
			   with: 'required' -> #( 'class_name' 'selector' 'fixed_source' ))
		  block: [ :arguments |
			  "We do NOT auto-apply the fix. We return it for the user to review."
			  Dictionary
				  with: 'status' -> 'fix_proposed'
				  with: 'class' -> (arguments at: 'class_name')
				  with: 'selector' -> (arguments at: 'selector')
				  with: 'proposed_source' -> (arguments at: 'fixed_source')
				  with: 'note' -> 'The fix has been proposed to the user for review. It will NOT be applied automatically.' ]
]

{ #category : 'as yet unclassified' }
ChatPharoDebuggerEnvironment >> initializeWithContext: aChatPharoDebuggerContext [

	super initialize.
	debuggerContext := aChatPharoDebuggerContext.
	tools := {
		self functionGetErrorDetails.
		self functionGetStackTrace.
		self functionGetLocalVariables.
		self functionGetReceiverState.
		self functionGetMethodSourceInStack.
		self functionSuggestFix.
	} asOrderedCollection
]

{ #category : 'as yet unclassified' }
ChatPharoDebuggerEnvironment >> tools [

	^ tools
]
