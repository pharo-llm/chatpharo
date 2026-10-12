"
I run **one user turn** against an LLM backend: the first completion, then the
tool-call round trips, until the model produces a written answer.

Every agent used to carry its own copy of this loop, each with different bugs
(no iteration bound, token counts of the first request only, reasoning lost
after the first tool call). I am the single implementation.

Responsibilities:

- append every model reply to the shared `ChatPharoHistory`;
- stop after `iterationLimit` tool rounds, then ask the model for a closing
  answer instead of returning an empty reply;
- sum token usage and collect reasoning across all the requests of the turn.

Collaborators: a completion client (`ChatPharoTool`) that answers
`getResponseForHistory:` and `getClosingResponseForHistory:`.

```smalltalk
(ChatPharoConversationTurn client: aChatPharoTool history: aHistory)
	iterationLimit: 10;
	run
```
"
Class {
	#name : 'ChatPharoConversationTurn',
	#superclass : 'Object',
	#instVars : [
		'client',
		'history',
		'iterationLimit',
		'iterations',
		'inputTokens',
		'outputTokens',
		'thinkingParts'
	],
	#category : 'AI-ChatPharo-Agent',
	#package : 'AI-ChatPharo-Agent'
}

{ #category : 'instance creation' }
ChatPharoConversationTurn class >> client: aCompletionClient history: aHistory [

	^ self new
		  setClient: aCompletionClient history: aHistory;
		  yourself
]

{ #category : 'accessing' }
ChatPharoConversationTurn class >> defaultIterationLimit [

	^ 25
]

{ #category : 'accessing' }
ChatPharoConversationTurn >> addNote: aString [
	"Record something the user should see next to the reasoning, e.g. a model switch."

	thinkingParts add: aString
]

{ #category : 'private' }
ChatPharoConversationTurn >> closingReply [

	| reply |
	reply := client getClosingResponseForHistory: history.
	reply content isEmptyOrNil ifTrue: [ reply content: self iterationLimitNotice ].
	self record: reply.
	^ reply
]

{ #category : 'initialization' }
ChatPharoConversationTurn >> initialize [

	super initialize.
	iterationLimit := self class defaultIterationLimit.
	iterations := 0.
	inputTokens := 0.
	outputTokens := 0.
	thinkingParts := OrderedCollection new
]

{ #category : 'accessing' }
ChatPharoConversationTurn >> iterationLimit: anInteger [

	iterationLimit := anInteger
]

{ #category : 'private' }
ChatPharoConversationTurn >> iterationLimitNotice [

	^ 'I stopped after {1} rounds of tool calls without reaching a final answer. Ask me to continue, or raise "Maximum iterations" in Settings.'
		  format: { iterationLimit }
]

{ #category : 'accessing' }
ChatPharoConversationTurn >> iterations [

	^ iterations
]

{ #category : 'private' }
ChatPharoConversationTurn >> nextReply [

	| reply |
	reply := client getResponseForHistory: history.
	self record: reply.
	^ reply
]

{ #category : 'private' }
ChatPharoConversationTurn >> record: aReply [

	history addMessage: aReply.
	inputTokens := inputTokens + (aReply inputTokens ifNil: [ 0 ]).
	outputTokens := outputTokens + (aReply outputTokens ifNil: [ 0 ]).
	aReply thinking ifNotNil: [ :text | thinkingParts add: text ]
]

{ #category : 'running' }
ChatPharoConversationTurn >> run [
	"Answer the final reply of the turn, carrying the usage and reasoning of the whole turn."

	| reply |
	reply := self nextReply.
	[ reply hasToolCalls and: [ iterations < iterationLimit ] ] whileTrue: [
		iterations := iterations + 1.
		reply := self nextReply ].
	reply hasToolCalls ifTrue: [ reply := self closingReply ].
	^ self summarizeInto: reply
]

{ #category : 'initialization' }
ChatPharoConversationTurn >> setClient: aCompletionClient history: aHistory [

	client := aCompletionClient.
	history := aHistory
]

{ #category : 'private' }
ChatPharoConversationTurn >> summarizeInto: aReply [

	^ aReply
		  thinking: ((String cr , String cr) join: thinkingParts);
		  inputTokens: inputTokens;
		  outputTokens: outputTokens;
		  totalTokens: inputTokens + outputTokens;
		  yourself
]
