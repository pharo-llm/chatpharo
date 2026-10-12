"
I separate what a model *answered* from what it *thought*.

Backends expose reasoning in different shapes:

- a dedicated field on the assistant message: `reasoning_content` (DeepSeek,
  LM Studio), `reasoning` (Ollama, OpenRouter, Groq) or `thinking`;
- inline tags inside the content: `<think>…</think>` (Qwen, DeepSeek R1 served
  by older runtimes), `<thinking>…</thinking>` or `<thought>…</thought>` (Gemini).

I read an OpenAI-style assistant message dictionary and answer the visible
`content` without the tags, plus the collected `reasoning`.

```smalltalk
(ChatPharoReasoningExtraction fromMessage: (Dictionary
	with: 'content' -> '<think>2+2 is 4</think>Four.')) reasoning
```
"
Class {
	#name : 'ChatPharoReasoningExtraction',
	#superclass : 'Object',
	#instVars : [
		'content',
		'reasoningParts'
	],
	#category : 'AI-ChatPharo-Tools-Core',
	#package : 'AI-ChatPharo-Tools',
	#tag : 'Core'
}

{ #category : 'instance creation' }
ChatPharoReasoningExtraction class >> fromMessage: aDictionary [

	^ self new
		  readMessage: aDictionary;
		  yourself
]

{ #category : 'accessing' }
ChatPharoReasoningExtraction class >> inlineTagNames [

	^ #( 'think' 'thinking' 'thought' )
]

{ #category : 'accessing' }
ChatPharoReasoningExtraction class >> reasoningFieldNames [

	^ #( 'reasoning_content' 'reasoning' 'thinking' )
]

{ #category : 'private' }
ChatPharoReasoningExtraction >> addReasoning: aString [

	aString trimBoth ifNotEmpty: [ :text | reasoningParts add: text ]
]

{ #category : 'accessing' }
ChatPharoReasoningExtraction >> content [
	"The visible answer, or nil when the model answered with tool calls only."

	^ content
]

{ #category : 'private' }
ChatPharoReasoningExtraction >> extractInlineTagNamed: aTagName [

	| opening closing |
	opening := '<' , aTagName , '>'.
	closing := '</' , aTagName , '>'.
	[ content includesSubstring: opening ] whileTrue: [
		self removeReasoningBetween: opening and: closing ]
]

{ #category : 'testing' }
ChatPharoReasoningExtraction >> hasReasoning [

	^ reasoningParts notEmpty
]

{ #category : 'initialization' }
ChatPharoReasoningExtraction >> initialize [

	super initialize.
	reasoningParts := OrderedCollection new
]

{ #category : 'private' }
ChatPharoReasoningExtraction >> readFieldsOf: aDictionary [

	self class reasoningFieldNames do: [ :each |
		aDictionary at: each ifPresent: [ :value | value isString ifTrue: [ self addReasoning: value ] ] ]
]

{ #category : 'initialization' }
ChatPharoReasoningExtraction >> readMessage: aDictionary [

	content := aDictionary at: 'content' ifAbsent: [ nil ].
	self readFieldsOf: aDictionary.
	(content isString and: [ content includes: $< ]) ifFalse: [ ^ self ].
	self class inlineTagNames do: [ :each | self extractInlineTagNamed: each ].
	content := content trimBoth
]

{ #category : 'accessing' }
ChatPharoReasoningExtraction >> reasoning [
	"Everything the model thought, or nil when it exposed nothing."

	reasoningParts ifEmpty: [ ^ nil ].
	^ (String cr , String cr) join: reasoningParts
]

{ #category : 'private' }
ChatPharoReasoningExtraction >> removeReasoningBetween: opening and: closing [
	"An unterminated tag means the answer was cut while thinking: keep the rest as reasoning."

	| start bodyStart stop |
	start := content findString: opening.
	bodyStart := start + opening size.
	stop := content findString: closing startingAt: bodyStart.
	stop = 0 ifTrue: [
		self addReasoning: (content copyFrom: bodyStart to: content size).
		content := content copyFrom: 1 to: start - 1.
		^ self ].
	self addReasoning: (content copyFrom: bodyStart to: stop - 1).
	content := (content copyFrom: 1 to: start - 1) , (content copyFrom: stop + closing size to: content size)
]
