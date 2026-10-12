"
I am one layer of the context ChatPharo gives a model **before** the user's
first word reaches it.

A model only knows what is in its prompt. The layers are, from the most stable
to the most volatile:

- `ChatPharoEnvironmentLayer` — which ChatPharo, Pharo and platform this is;
- `ChatPharoProjectLayer` — project context (automatic): image, repositories, branches, uncommitted packages;
- `ChatPharoSessionLayer` — session context (short-term): what the user is doing right now;
- `ChatPharoMemoryLayer` — user and work memory (long-term): who the user is, past decisions, corrections.

Subclasses answer `title`, `isEnabled` and `linesFor:`. I render the section
and keep it within `characterBudget`, so a huge image cannot flood the prompt.
"
Class {
	#name : 'ChatPharoContextLayer',
	#superclass : 'Object',
	#instVars : [
		'settings'
	],
	#category : 'AI-ChatPharo-Context',
	#package : 'AI-ChatPharo-Context'
}

{ #category : 'testing' }
ChatPharoContextLayer class >> isAbstract [

	^ self = ChatPharoContextLayer
]

{ #category : 'instance creation' }
ChatPharoContextLayer class >> settings: aSettings [

	^ self new
		  settings: aSettings;
		  yourself
]

{ #category : 'accessing' }
ChatPharoContextLayer >> characterBudget [

	^ 2000
]

{ #category : 'testing' }
ChatPharoContextLayer >> isEnabled [

	^ true
]

{ #category : 'accessing' }
ChatPharoContextLayer >> linesFor: aQueryString [
	"Answer the facts of this layer, one per line, most important first. Empty when there is nothing to say."

	^ self subclassResponsibility
]

{ #category : 'accessing' }
ChatPharoContextLayer >> settings [

	^ settings ifNil: [ settings := ChatPharoSettings default ]
]

{ #category : 'accessing' }
ChatPharoContextLayer >> settings: aSettings [

	settings := aSettings
]

{ #category : 'accessing' }
ChatPharoContextLayer >> textFor: aQueryString [
	"Answer my rendered section, or an empty string when I am disabled or have nothing to say."

	| lines |
	self isEnabled ifFalse: [ ^ '' ].
	lines := self linesFor: aQueryString.
	lines ifEmpty: [ ^ '' ].
	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: '## ';
			  nextPutAll: self title.
		  self write: lines within: self characterBudget on: stream ]
]

{ #category : 'accessing' }
ChatPharoContextLayer >> title [

	^ self subclassResponsibility
]

{ #category : 'private' }
ChatPharoContextLayer >> write: lines within: aBudget on: aStream [

	| remaining |
	remaining := aBudget.
	lines do: [ :each |
		remaining < each size ifTrue: [
			aStream
				cr;
				nextPutAll: '- (more omitted)'.
			^ self ].
		aStream
			cr;
			nextPutAll: each.
		remaining := remaining - each size ]
]
