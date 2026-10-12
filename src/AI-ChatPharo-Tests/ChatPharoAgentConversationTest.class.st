Class {
	#name : 'ChatPharoAgentConversationTest',
	#superclass : 'TestCase',
	#category : 'AI-ChatPharo-Tests-Agent',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Agent'
}

{ #category : 'private' }
ChatPharoAgentConversationTest >> usageLimit [

	^ [ (ChatPharoBackendError status: 429 message: 'Rate limit exceeded.') signal ]
]

{ #category : 'running' }
ChatPharoAgentConversationTest >> tearDown [

	ChatPharoSettings resetDefault.
	super tearDown
]

{ #category : 'tests' }
ChatPharoAgentConversationTest >> testAnswerIsTheWrittenTextForEveryBackend [
	"Some backends used to answer the reply object, which printed as 'a ChatPharoHistorySaver' in chat titles."

	| agent |
	agent := ChatPharoScriptedAgent answering: { (ChatPharoScriptedCompletionClient reply: 'hello') }.
	self assert: (agent getResponseForPrompt: 'hi') equals: 'hello'.
	self assert: agent response totalTokens equals: 15
]

{ #category : 'tests' }
ChatPharoAgentConversationTest >> testAuthenticationFailureDoesNotTryFallbackModels [

	| agent |
	agent := ChatPharoScriptedAgent answering: {
			         [ (ChatPharoBackendError status: 401 message: 'Invalid or expired API key.') signal ].
			         (ChatPharoScriptedCompletionClient reply: 'never') }.
	agent fallbackModels: #( 'backup' ).
	self should: [ agent getResponseForPrompt: 'hi' ] raise: ChatPharoBackendError.
	self assert: agent client requestCount equals: 1
]

{ #category : 'tests' }
ChatPharoAgentConversationTest >> testFailedTurnLeavesOnlyTheUserPromptInHistory [

	| agent |
	agent := ChatPharoScriptedAgent answering: {
			         (ChatPharoScriptedCompletionClient toolReplyThinking: nil).
			         [ Error signal: 'connection lost' ] }.
	self should: [ agent getResponseForPrompt: 'hi' ] raise: Error.
	self assert: agent history size equals: 1.
	self assert: agent history messages last role equals: 'user'
]

{ #category : 'tests' }
ChatPharoAgentConversationTest >> testPromptIsRecordedOnceWhenTheChatAlreadyRecordedIt [

	| agent |
	agent := ChatPharoScriptedAgent answering: { (ChatPharoScriptedCompletionClient reply: 'hello') }.
	agent history addUser: 'hi'.
	agent getResponseForPrompt: 'hi'.
	self assert: (agent history messages collect: [ :each | each role ]) asArray equals: #( 'user' 'assistant' )
]

{ #category : 'tests' }
ChatPharoAgentConversationTest >> testUsageLimitFallsBackToTheNextModel [

	| agent |
	agent := ChatPharoScriptedAgent answering: {
			         self usageLimit.
			         (ChatPharoScriptedCompletionClient reply: 'from backup') }.
	agent fallbackModels: #( 'backup' ).
	self assert: (agent getResponseForPrompt: 'hi') equals: 'from backup'.
	self assert: agent client requestedModels asArray equals: #( 'primary' 'backup' ).
	self assert: agent model equals: 'backup'.
	self assert: (agent response thinking includesSubstring: 'primary')
]

{ #category : 'tests' }
ChatPharoAgentConversationTest >> testUsageLimitWithoutFallbackIsReported [

	| agent |
	agent := ChatPharoScriptedAgent answering: { self usageLimit }.
	self should: [ agent getResponseForPrompt: 'hi' ] raise: ChatPharoBackendError
]
