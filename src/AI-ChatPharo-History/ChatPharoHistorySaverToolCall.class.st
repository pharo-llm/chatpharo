"
Counterpart produced by ChatPharoTool when the assistant requests a function call; later replayed as JSON so the model sees the result.

"
Class {
	#name : 'ChatPharoHistorySaverToolCall',
	#superclass : 'Object',
	#instVars : [
		'id',
		'functionName',
		'arguments',
		'content'
	],
	#category : 'AI-ChatPharo-History',
	#package : 'AI-ChatPharo-History'
}

{ #category : 'contents' }
ChatPharoHistorySaverToolCall class >> id: anId functionName: aFn arguments: args content: c [ 

	^ self basicNew initializeWithID: anId functionName: aFn arguments: args content: c; yourself
]

{ #category : 'accessing' }
ChatPharoHistorySaverToolCall >> arguments [

	^ arguments
]

{ #category : 'accessing' }
ChatPharoHistorySaverToolCall >> arguments: anObject [

	arguments := anObject
]

{ #category : 'accessing' }
ChatPharoHistorySaverToolCall >> content [

	^ content
]

{ #category : 'accessing' }
ChatPharoHistorySaverToolCall >> content: anObject [

	content := anObject
]

{ #category : 'accessing' }
ChatPharoHistorySaverToolCall >> functionName [

	^ functionName
]

{ #category : 'accessing' }
ChatPharoHistorySaverToolCall >> functionName: anObject [

	functionName := anObject
]

{ #category : 'accessing' }
ChatPharoHistorySaverToolCall >> id [

	^ id
]

{ #category : 'accessing' }
ChatPharoHistorySaverToolCall >> id: anObject [

	id := anObject
]

{ #category : 'initialization' }
ChatPharoHistorySaverToolCall >> initializeWithID: anId functionName: aFn arguments: args content: c [

	id := anId.
	functionName := aFn.
	arguments := args.
	content := c
]

{ #category : 'initialization' }
ChatPharoHistorySaverToolCall >> openAIChatToolCall [

    ^ Dictionary
        with: 'type' -> 'function'
        with: 'id' -> id  asString copy
        with: 'function' -> (Dictionary
            with: 'name' -> functionName  asString copy
            with: 'arguments' ->
                (arguments isString
                    ifTrue: [ arguments asString copy  ]
                    ifFalse: [ STONJSON toString: (arguments ifNil: [ Dictionary new ]) ]))
]

{ #category : 'initialization' }
ChatPharoHistorySaverToolCall >> openAIChatToolMessage [ 

	^ Dictionary
	with: 'role' -> 'tool'
	with: 'tool_call_id' -> id asString copy
	with: 'content' -> (content ifNil: [ '[No tool result]' ])
]

{ #category : 'printing' }
ChatPharoHistorySaverToolCall >> printTraceOn: aStream [
	"A short human readable account of this call for the thinking panel."

	aStream
		nextPutAll: 'Function: ';
		nextPutAll: functionName;
		cr;
		nextPutAll: 'Arguments: ';
		nextPutAll: arguments asString;
		cr.
	content ifNotNil: [
		aStream
			nextPutAll: 'Result: ';
			nextPutAll: (content truncateWithElipsisTo: 400);
			cr ].
	aStream cr
]
