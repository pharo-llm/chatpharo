"
Thin convenience subclass used inside agents when they build synthetic history entries (e.g., the solitary user prompt passed to ChatPharoTool).
"
Class {
	#name : 'ChatPharoHistorySaver',
	#superclass : 'Object',
	#instVars : [
		'role',
		'content',
		'toolCalls',
		'toolCallId',
		'thinking',
		'inputTokens',
		'outputTokens',
		'totalTokens'
	],
	#category : 'AI-ChatPharo-History',
	#package : 'AI-ChatPharo-History'
}

{ #category : 'contents' }
ChatPharoHistorySaver class >> role: r content: c [
	^ self role: r content: c toolCalls: nil
]

{ #category : 'instance creation' }
ChatPharoHistorySaver class >> role: aRole content: aContent toolCallId: anId [

	^ self new
		  role: aRole;
		  content: aContent;
		  toolCallId: anId;
		  yourself
]

{ #category : 'contents' }
ChatPharoHistorySaver class >> role: r content: c toolCalls: t [ 

	^ self new
		role: r; content: c; toolCalls: t;
		yourself
]

{ #category : 'accessing' }
ChatPharoHistorySaver >> content [

	^ content
]

{ #category : 'accessing' }
ChatPharoHistorySaver >> content: anObject [

	content := anObject
]

{ #category : 'testing' }
ChatPharoHistorySaver >> hasToolCalls [

	^ toolCalls isEmptyOrNil not
]

{ #category : 'history' }
ChatPharoHistorySaver >> historyStringOn: strm [

	        strm
                nextPutAll: role;
                nextPutAll: ': ';
                nextPutAll: (content ifNil: [ '' ]);
                cr
]

{ #category : 'accessing' }
ChatPharoHistorySaver >> inputTokens [

	^ inputTokens
]

{ #category : 'accessing' }
ChatPharoHistorySaver >> inputTokens: anInteger [

	inputTokens := anInteger
]

{ #category : 'accessing' }
ChatPharoHistorySaver >> outputTokens [

	^ outputTokens
]

{ #category : 'accessing' }
ChatPharoHistorySaver >> outputTokens: anInteger [

	outputTokens := anInteger
]

{ #category : 'history' }
ChatPharoHistorySaver >> putOpenAIChatMessagesOn: stream [
		| msg |
		msg := Dictionary with: 'role' -> role.
		msg add: 'content' -> (content ifNil: [ '[No assistant response]' ]).
		toolCalls ifNotNil: [
				msg add: 'tool_calls'
					-> (toolCalls collect: [ :tc | tc openAIChatToolCall ] as: Array) ].
		stream nextPut: msg.
		toolCalls ifNotNil: [
			toolCalls do: [ :tc | stream nextPut: tc openAIChatToolMessage ] ] 
]

{ #category : 'accessing' }
ChatPharoHistorySaver >> role [

	^ role
]

{ #category : 'accessing' }
ChatPharoHistorySaver >> role: anObject [

	role := anObject
]

{ #category : 'accessing' }
ChatPharoHistorySaver >> thinking [
	"Return the thinking content from Claude API"

	^ thinking
]

{ #category : 'accessing' }
ChatPharoHistorySaver >> thinking: aString [
	"Set the thinking content from the agent response"

	thinking := aString
]

{ #category : 'accessing' }
ChatPharoHistorySaver >> toolCallId [ 
	^ toolCallId 
]

{ #category : 'accessing' }
ChatPharoHistorySaver >> toolCallId: anObject [

	toolCallId := anObject
]

{ #category : 'accessing' }
ChatPharoHistorySaver >> toolCalls [

	^ toolCalls
]

{ #category : 'accessing' }
ChatPharoHistorySaver >> toolCalls: anObject [

	toolCalls := anObject
]

{ #category : 'accessing' }
ChatPharoHistorySaver >> totalTokens [

	^ totalTokens
]

{ #category : 'accessing' }
ChatPharoHistorySaver >> totalTokens: anInteger [

	totalTokens := anInteger
]
