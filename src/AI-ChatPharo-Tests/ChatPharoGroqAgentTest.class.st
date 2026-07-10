Class {
	#name : 'ChatPharoGroqAgentTest',
	#superclass : 'TestCase',
	#instVars : [
		'agent'
	],
	#category : 'AI-ChatPharo-Tests-Agent',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Agent'
}

{ #category : 'running' }
ChatPharoGroqAgentTest >> setUp [

	super setUp.
	agent := ChatPharoGroqAgent new
]

{ #category : 'running' }
ChatPharoGroqAgentTest >> tearDown [

	agent := nil.
	ChatPharoSettings resetDefault.
	super tearDown
]

{ #category : 'running' }
ChatPharoGroqAgentTest >> testApiBaseURLString [

	self assert: agent apiBaseURLString equals: 'https://api.groq.com/openai/v1'
]

{ #category : 'running' }
ChatPharoGroqAgentTest >> testApiKeySetAndGet [

	agent apiKey: 'test-groq-key'.
	self assert: agent apiKey equals: 'test-groq-key'
]

{ #category : 'running' }
ChatPharoGroqAgentTest >> testCopyForChat [

	| copy |
	copy := agent copyForChat.
	self assert: copy isNotNil.
	self assert: copy class equals: ChatPharoGroqAgent.
	self deny: copy == agent
]

{ #category : 'running' }
ChatPharoGroqAgentTest >> testDisplayName [

	self assert: ChatPharoGroqAgent displayName equals: 'Groq Cloud'
]

{ #category : 'running' }
ChatPharoGroqAgentTest >> testInitialization [

	self assert: agent isNotNil.
	self assert: (agent isKindOf: ChatPharoOpenAIAgent).
	self assert: agent host equals: 'https://api.groq.com/openai/v1'
]

{ #category : 'running' }
ChatPharoGroqAgentTest >> testModelNamesIsNotEmpty [

	self assert: ChatPharoGroqAgent modelNames isNotEmpty
]

{ #category : 'running' }
ChatPharoGroqAgentTest >> testModelSetAndGet [

	agent model: 'llama-3.3-70b-versatile'.
	self assert: agent model equals: 'llama-3.3-70b-versatile'
]
