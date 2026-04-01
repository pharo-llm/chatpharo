Class {
	#name : 'ChatPharoCommandExecutionStub',
	#superclass : 'Object',
	#instVars : [
		'LastAskedMethod',
		'LastCodedMethod'
	],
	#classVars : [
		'LastAskedMethod',
		'LastCodedMethod'
	],
	#category : 'AI-ChatPharo-Tests-Mock',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Mock'
}

{ #category : 'tests' }
ChatPharoCommandExecutionStub class >> askAboutMethod: aMethod [ 

	LastAskedMethod := aMethod
]

{ #category : 'tests' }
ChatPharoCommandExecutionStub class >> codeAndFixFromDebugger: aDebugger [

	"Stub for intelligent debug command tests"
	LastAskedMethod := aDebugger
]

{ #category : 'tests' }
ChatPharoCommandExecutionStub class >> codeForMethod: aMethod [

	LastCodedMethod := aMethod
]

{ #category : 'tests' }
ChatPharoCommandExecutionStub class >> lastAskedMethod [

	^ LastAskedMethod
]

{ #category : 'tests' }
ChatPharoCommandExecutionStub class >> lastCodedMethod [

	^ LastCodedMethod
]

{ #category : 'tests' }
ChatPharoCommandExecutionStub class >> reset [

	LastAskedMethod := nil.
	LastCodedMethod := nil
]
