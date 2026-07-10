Class {
	#name : 'ChatPharoPharoInferAgentTest',
	#superclass : 'TestCase',
	#instVars : [
		'agent'
	],
	#category : 'AI-ChatPharo-Tests-Agent',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Agent'
}

{ #category : 'running' }
ChatPharoPharoInferAgentTest >> setUp [

	super setUp.
	agent := ChatPharoPharoInferAgent new
]

{ #category : 'running' }
ChatPharoPharoInferAgentTest >> tearDown [

	agent := nil.
	super tearDown
]

{ #category : 'tests' }
ChatPharoPharoInferAgentTest >> testDisplayName [

	self assert: ChatPharoPharoInferAgent displayName equals: 'PharoInfer'
]

{ #category : 'tests' }
ChatPharoPharoInferAgentTest >> testIsLocalApi [

	self deny: ChatPharoPharoInferAgent isExternalApi
]

{ #category : 'tests' }
ChatPharoPharoInferAgentTest >> testModelNamesAnswersCollection [

	self assert: ChatPharoPharoInferAgent modelNames isCollection
]

{ #category : 'tests' }
ChatPharoPharoInferAgentTest >> testPromptIncludesAssistantCue [

	| prompt |
	agent promptPrefix: 'user: hello'.
	prompt := agent promptFor: 'hello'.
	self assert: (prompt includesSubstring: 'system: ').
	self assert: (prompt includesSubstring: 'user: hello').
	self assert: (prompt includesSubstring: 'assistant: ')
]

{ #category : 'tests' }
ChatPharoPharoInferAgentTest >> testSupportsToolCallingFalse [

	self deny: agent supportsToolCalling
]
