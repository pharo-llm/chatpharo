Class {
	#name : 'ChatPharoConversationTurnTest',
	#superclass : 'TestCase',
	#instVars : [
		'history'
	],
	#category : 'AI-ChatPharo-Tests-Agent',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Agent'
}

{ #category : 'running' }
ChatPharoConversationTurnTest >> setUp [

	super setUp.
	history := ChatPharoHistory new.
	history addUser: 'question'
]

{ #category : 'private' }
ChatPharoConversationTurnTest >> turnAnswering: replies [

	^ ChatPharoConversationTurn client: (ChatPharoScriptedCompletionClient answering: replies) history: history
]

{ #category : 'tests' }
ChatPharoConversationTurnTest >> testClosingAnswerIsRequestedWhenIterationLimitIsReached [

	| client turn reply |
	client := ChatPharoScriptedCompletionClient answering: {
			          (ChatPharoScriptedCompletionClient toolReplyThinking: nil).
			          (ChatPharoScriptedCompletionClient toolReplyThinking: nil) }.
	turn := (ChatPharoConversationTurn client: client history: history)
		        iterationLimit: 1;
		        yourself.
	reply := turn run.
	self assert: client requestCount equals: 2.
	self assert: client closingRequestCount equals: 1.
	self deny: reply content isEmptyOrNil.
	self assert: (reply content includesSubstring: 'Maximum iterations')
]

{ #category : 'tests' }
ChatPharoConversationTurnTest >> testEveryReplyIsRecordedInHistory [

	(self turnAnswering: {
			 (ChatPharoScriptedCompletionClient toolReplyThinking: nil).
			 (ChatPharoScriptedCompletionClient reply: 'done') }) run.
	self assert: history size equals: 3.
	self assert: history messages last content equals: 'done'
]

{ #category : 'tests' }
ChatPharoConversationTurnTest >> testPlainAnswerNeedsOneRequest [

	| turn reply |
	turn := self turnAnswering: { (ChatPharoScriptedCompletionClient reply: 'hello') }.
	reply := turn run.
	self assert: reply content equals: 'hello'.
	self assert: turn iterations equals: 0
]

{ #category : 'tests' }
ChatPharoConversationTurnTest >> testReasoningOfEveryRequestIsKept [
	"The reasoning used to be the one of the last request only, which is empty after a tool call."

	| reply |
	reply := (self turnAnswering: {
			          (ChatPharoScriptedCompletionClient toolReplyThinking: 'I should list the packages.').
			          (ChatPharoScriptedCompletionClient reply: 'done') }) run.
	self assert: (reply thinking includesSubstring: 'I should list the packages.')
]

{ #category : 'tests' }
ChatPharoConversationTurnTest >> testTokenUsageIsSummedOverTheWholeTurn [

	| reply |
	reply := (self turnAnswering: {
			          (ChatPharoScriptedCompletionClient toolReplyThinking: nil).
			          (ChatPharoScriptedCompletionClient toolReplyThinking: nil).
			          (ChatPharoScriptedCompletionClient reply: 'done') }) run.
	self assert: reply inputTokens equals: 30.
	self assert: reply outputTokens equals: 15.
	self assert: reply totalTokens equals: 45
]
