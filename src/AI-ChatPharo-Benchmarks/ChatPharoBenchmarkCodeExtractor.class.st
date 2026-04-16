"
Extracts the Smalltalk source code block from an LLM response.

LLMs wrap code in ```smalltalk … ``` (preferred), plain ``` … ```, or
occasionally no fence at all. This class tries each strategy in order and
returns the first match — with leading/trailing whitespace trimmed, ready
for scorers to compare against `goldSource`.
"
Class {
	#name : 'ChatPharoBenchmarkCodeExtractor',
	#superclass : 'Object',
	#category : 'AI-ChatPharo-Benchmarks',
	#package : 'AI-ChatPharo-Benchmarks',
	#tag : 'Runner'
}

{ #category : 'extracting' }
ChatPharoBenchmarkCodeExtractor class >> extractFrom: aString [
	"Return the most plausible Smalltalk code block in aString, trimmed."

	| block |
	aString isNil ifTrue: [ ^ '' ].
	aString isEmpty ifTrue: [ ^ '' ].

	"1. Fenced ```smalltalk block"
	block := self extractFencedBlock: aString withTag: 'smalltalk'.
	block ifNotNil: [ ^ block trimBoth ].

	"2. Fenced ```pharo block"
	block := self extractFencedBlock: aString withTag: 'pharo'.
	block ifNotNil: [ ^ block trimBoth ].

	"3. Any generic fenced block"
	block := self extractFencedBlock: aString withTag: nil.
	block ifNotNil: [ ^ block trimBoth ].

	"4. Nothing fenced — return the whole response, trimmed."
	^ aString trimBoth
]

{ #category : 'private' }
ChatPharoBenchmarkCodeExtractor class >> extractFencedBlock: aString withTag: tagOrNil [
	"Find ```<tag>\n …\n``` (tag optional) and return the inside. nil if absent."

	| marker start newlineIndex closeIndex |
	marker := tagOrNil
		          ifNil: [ '```' ]
		          ifNotNil: [ '```' , tagOrNil ].

	start := aString indexOfSubCollection: marker.
	start = 0 ifTrue: [ ^ nil ].

	"Jump past the marker"
	start := start + marker size.

	"Skip whitespace/newline after the opening fence."
	newlineIndex := aString indexOf: Character lf startingAt: start.
	newlineIndex = 0
		ifTrue: [ newlineIndex := start ]
		ifFalse: [ newlineIndex := newlineIndex + 1 ].

	closeIndex := aString
		              indexOfSubCollection: '```'
		              startingAt: newlineIndex.
	closeIndex = 0 ifTrue: [ ^ nil ].

	^ aString copyFrom: newlineIndex to: closeIndex - 1
]

{ #category : 'extracting' }
ChatPharoBenchmarkCodeExtractor class >> normalizeWhitespace: aString [
	"Collapse all runs of whitespace into single spaces; trim edges.
	 Useful for lenient equality scoring."

	| stream prevSpace |
	aString isNil ifTrue: [ ^ '' ].
	stream := WriteStream on: String new.
	prevSpace := false.
	aString do: [ :c |
		c isSeparator
			ifTrue: [
				prevSpace ifFalse: [
					stream nextPut: $ .
					prevSpace := true ] ]
			ifFalse: [
				stream nextPut: c.
				prevSpace := false ] ].
	^ stream contents trimBoth
]
