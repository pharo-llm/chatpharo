"
Minimal stand-in for an StDebugger: it only knows its session, so ChatPharoDebuggerContext class>>fromDebugger: can be tested without opening a debugger UI.
"
Class {
	#name : 'ChatPharoDebuggerStub',
	#superclass : 'Object',
	#instVars : [
		'session'
	],
	#category : 'AI-ChatPharo-Tests-Mock',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Mock'
}

{ #category : 'accessing' }
ChatPharoDebuggerStub >> session [

	^ session
]

{ #category : 'accessing' }
ChatPharoDebuggerStub >> session: aDebugSession [

	session := aDebugSession
]
