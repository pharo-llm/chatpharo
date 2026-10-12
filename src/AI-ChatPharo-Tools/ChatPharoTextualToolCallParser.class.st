"
I recover tool calls that a model wrote as **text** instead of using the
structured `tool_calls` field.

Small local models (Qwen 2.5 Coder, Hermes, Llama variants served by Ollama or
LM Studio) often answer a function call as plain JSON in the message content:

	{""name"": ""find_senders"", ""arguments"": {""selector"": ""foo""}}

sometimes inside a ```json fence or `<tool_call>` tags. Shown to the user that
is a useless answer; executed, it is what the model meant.

I only recognise a call when the whole answer is such a call and it names a tool
that is really offered, so JSON the user asked for is never executed by mistake.

```smalltalk
(ChatPharoTextualToolCallParser knownToolNames: #( 'find_senders' ))
	callsIn: '{""name"": ""find_senders"", ""arguments"": {""selector"": ""foo""}}'
```
"
Class {
	#name : 'ChatPharoTextualToolCallParser',
	#superclass : 'Object',
	#instVars : [
		'knownToolNames'
	],
	#category : 'AI-ChatPharo-Tools-Core',
	#package : 'AI-ChatPharo-Tools',
	#tag : 'Core'
}

{ #category : 'instance creation' }
ChatPharoTextualToolCallParser class >> knownToolNames: aCollection [

	^ self new
		  setKnownToolNames: aCollection;
		  yourself
]

{ #category : 'private' }
ChatPharoTextualToolCallParser >> argumentsOf: aDictionary [

	^ aDictionary at: 'arguments' ifAbsent: [ aDictionary at: 'parameters' ifAbsent: [ Dictionary new ] ]
]

{ #category : 'private' }
ChatPharoTextualToolCallParser >> callFrom: aJsonString index: anIndex [
	"Answer the OpenAI-style tool call written in aJsonString, or nil when it is not one."

	| parsed |
	parsed := [ STONJSON fromString: aJsonString ]
		          on: STONReaderError
		          do: [ ^ nil ].
	(self isCall: parsed) ifFalse: [ ^ nil ].
	^ Dictionary
		  with: 'id' -> ('text-call-' , anIndex printString)
		  with: 'type' -> 'function'
		  with: 'function' -> (Dictionary
				   with: 'name' -> (parsed at: 'name')
				   with: 'arguments' -> (STONJSON toString: (self argumentsOf: parsed)))
]

{ #category : 'parsing' }
ChatPharoTextualToolCallParser >> callsIn: aString [
	"Answer the tool calls aString consists of, or an empty collection when it is an ordinary answer."

	| candidates calls |
	aString isEmptyOrNil ifTrue: [ ^ #(  ) ].
	candidates := self candidateJsonTextsIn: aString trimBoth.
	calls := candidates withIndexCollect: [ :each :index | self callFrom: each index: index ].
	^ (calls includes: nil)
		  ifTrue: [ #(  ) ]
		  ifFalse: [ calls ]
]

{ #category : 'private' }
ChatPharoTextualToolCallParser >> candidateJsonTextsIn: aString [

	(aString includesSubstring: '<tool_call>') ifTrue: [ ^ self taggedTextsIn: aString ].
	^ { (self withoutCodeFence: aString) }
]

{ #category : 'private' }
ChatPharoTextualToolCallParser >> isCall: anObject [

	^ anObject isDictionary and: [ knownToolNames includes: (anObject at: 'name' ifAbsent: [ nil ]) ]
]

{ #category : 'initialization' }
ChatPharoTextualToolCallParser >> setKnownToolNames: aCollection [

	knownToolNames := aCollection asSet
]

{ #category : 'private' }
ChatPharoTextualToolCallParser >> taggedTextsIn: aString [
	"The texts between <tool_call> and </tool_call>. Anything outside the tags makes it an ordinary answer."

	| texts rest |
	texts := OrderedCollection new.
	rest := aString.
	[ rest beginsWith: '<tool_call>' ] whileTrue: [
		| stop |
		stop := rest findString: '</tool_call>'.
		stop = 0 ifTrue: [ ^ #( '' ) ].
		texts add: (rest copyFrom: '<tool_call>' size + 1 to: stop - 1) trimBoth.
		rest := (rest copyFrom: stop + '</tool_call>' size to: rest size) trimBoth ].
	^ rest
		  ifEmpty: [ texts ]
		  ifNotEmpty: [ #( '' ) ]
]

{ #category : 'private' }
ChatPharoTextualToolCallParser >> withoutCodeFence: aString [

	| lines |
	(aString beginsWith: '```') ifFalse: [ ^ aString ].
	lines := aString lines.
	(lines size > 2 and: [ lines last trimBoth = '```' ]) ifFalse: [ ^ aString ].
	^ String cr join: (lines copyFrom: 2 to: lines size - 1)
]
