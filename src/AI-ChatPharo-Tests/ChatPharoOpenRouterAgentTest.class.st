Class {
	#name : 'ChatPharoOpenRouterAgentTest',
	#superclass : 'TestCase',
	#instVars : [
		'agent'
	],
	#category : 'AI-ChatPharo-Tests-Agent',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Agent'
}

{ #category : 'running' }
ChatPharoOpenRouterAgentTest >> setUp [

	super setUp.
	agent := ChatPharoOpenRouterAgent new
]

{ #category : 'running' }
ChatPharoOpenRouterAgentTest >> tearDown [

	agent := nil.
	ChatPharoSettings resetDefault.
	super tearDown
]

{ #category : 'running' }
ChatPharoOpenRouterAgentTest >> testApiBaseURLString [

	self assert: agent apiBaseURLString equals: 'https://openrouter.ai/api/v1'
]

{ #category : 'running' }
ChatPharoOpenRouterAgentTest >> testApiKeySetAndGet [

	agent apiKey: 'test-openrouter-key'.
	self assert: agent apiKey equals: 'test-openrouter-key'
]

{ #category : 'running' }
ChatPharoOpenRouterAgentTest >> testCopyForChat [

	| copy |
	copy := agent copyForChat.
	self assert: copy isNotNil.
	self assert: copy class equals: ChatPharoOpenRouterAgent.
	self deny: copy == agent
]

{ #category : 'running' }
ChatPharoOpenRouterAgentTest >> testDisplayName [

	self assert: ChatPharoOpenRouterAgent displayName equals: 'OpenRouter'
]

{ #category : 'running' }
ChatPharoOpenRouterAgentTest >> testInitialization [

	self assert: agent isNotNil.
	self assert: (agent isKindOf: ChatPharoOpenAIAgent).
	self assert: agent host equals: 'https://openrouter.ai/api/v1'
]

{ #category : 'running' }
ChatPharoOpenRouterAgentTest >> testModelNamesIsNotEmpty [

	self assert: ChatPharoOpenRouterAgent modelNames isNotEmpty
]

{ #category : 'running' }
ChatPharoOpenRouterAgentTest >> testModelSetAndGet [

	agent model: 'openai/gpt-4o-mini'.
	self assert: agent model equals: 'openai/gpt-4o-mini'
]
