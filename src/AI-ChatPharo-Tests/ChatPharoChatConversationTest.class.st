Class {
	#name : 'ChatPharoChatConversationTest',
	#superclass : 'TestCase',
	#category : 'AI-ChatPharo-Tests-Chat',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Chat'
}

{ #category : 'private' }
ChatPharoChatConversationTest >> chatAnswering: replies [

	^ ChatPharoChat new
		  agent: (ChatPharoScriptedAgent answering: replies);
		  yourself
]

{ #category : 'running' }
ChatPharoChatConversationTest >> setUp [

	super setUp.
	ChatPharoSettings default welcomeMessageEnabled: false
]

{ #category : 'running' }
ChatPharoChatConversationTest >> tearDown [

	ChatPharoSettings resetDefault.
	super tearDown
]

{ #category : 'tests' }
ChatPharoChatConversationTest >> testContextLayersReachTheSystemPromptDuringTheRequest [

	| chat agent seenPrompt |
	agent := ChatPharoScriptedAgent answering:
		         { [ seenPrompt := agent systemPrompt. ChatPharoScriptedCompletionClient reply: 'ok' ] }.
	chat := ChatPharoChat new
		        agent: agent;
		        yourself.
	chat sendMessage: 'hello'.
	chat waitForPromptProcessDone.
	self assert: (seenPrompt includesSubstring: 'Project context (automatic)').
	self assert: (seenPrompt includesSubstring: 'ChatPharo Environment').
	self deny: (agent systemPrompt includesSubstring: 'Project context (automatic)')
]

{ #category : 'tests' }
ChatPharoChatConversationTest >> testExportedConversationWithToolCallsCanBeImportedAndContinued [

	| chat copy exported |
	chat := self chatAnswering: {
			        (ChatPharoScriptedCompletionClient toolReplyThinking: nil).
			        (ChatPharoScriptedCompletionClient reply: 'There are no packages.') }.
	chat sendMessage: 'list packages'.
	chat waitForPromptProcessDone.

	copy := ChatPharoChat new.
	copy importFromJson: chat exportAsJson.
	exported := Array streamContents: [ :stream | (copy instVarNamed: #history) putOpenAIChatMessagesOn: stream ].

	self assert: copy messages size equals: 1.
	self assert: copy messages first content equals: 'list packages'.
	self assert: copy messages first answer equals: 'There are no packages.'.
	self assert: (exported collect: [ :each | each at: 'role' ]) equals: #( 'user' 'assistant' 'tool' 'assistant' ).
	self assert: ((exported at: 3) at: 'tool_call_id') equals: 'call-1'.
	self assert: ((exported at: 3) at: 'content') equals: '{"packages":[]}'
]

{ #category : 'tests' }
ChatPharoChatConversationTest >> testHistoryHoldsEachMessageOnce [
	"Both the chat and the agent used to record the prompt and the answer: the model saw everything twice."

	| chat |
	chat := self chatAnswering: {
			        (ChatPharoScriptedCompletionClient reply: 'first').
			        (ChatPharoScriptedCompletionClient reply: 'second') }.
	chat sendMessage: 'one'.
	chat waitForPromptProcessDone.
	chat sendMessage: 'two'.
	chat waitForPromptProcessDone.
	self
		assert: (chat historyMessages collect: [ :each | each role -> each content ]) asArray
		equals: {
				('user' -> 'one').
				('assistant' -> 'first').
				('user' -> 'two').
				('assistant' -> 'second') }
]

{ #category : 'tests' }
ChatPharoChatConversationTest >> testReasoningAndTokenUsageReachTheMessage [

	| chat |
	chat := self chatAnswering: {
			        (ChatPharoScriptedCompletionClient toolReplyThinking: 'Let me look at the packages.').
			        (ChatPharoScriptedCompletionClient reply: 'done') }.
	chat sendMessage: 'go'.
	chat waitForPromptProcessDone.
	self assert: (chat messages last thinking includesSubstring: 'Let me look at the packages.').
	self assert: chat messages last inputTokens equals: 20.
	self assert: chat messages last outputTokens equals: 10.
	self assert: chat messages last totalTokens equals: 30
]

{ #category : 'tests' }
ChatPharoChatConversationTest >> testWelcomeMessageIsShownButNotSentToTheModel [

	| chat |
	ChatPharoSettings default welcomeMessageEnabled: true.
	chat := ChatPharoChat new.
	self assert: chat messages size equals: 1.
	self assert: chat historyMessages isEmpty
]
