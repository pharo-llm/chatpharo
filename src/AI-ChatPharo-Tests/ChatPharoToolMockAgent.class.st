Class {
	#name : 'ChatPharoToolMockAgent',
	#superclass : 'ChatPharoMockAgent',
	#instVars : [
		'toolExecution'
	],
	#category : 'AI-ChatPharo-Tests-Mock',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Mock'
}

{ #category : 'private - uffi' }
ChatPharoToolMockAgent >> getResponseForPrompt: prompt [

	toolExecution ifNotNil: [ :blk | blk cull: 'mock-tool' ].
	^ super getResponseForPrompt: prompt
]

{ #category : 'private - ffi' }
ChatPharoToolMockAgent >> onToolExecution [
    ^ toolExecution
]

{ #category : 'private - ffi' }
ChatPharoToolMockAgent >> onToolExecution: aBlock [
    toolExecution := aBlock
]
