"
Jaccard-style token overlap:
  |tokens(generated) ∩ tokens(gold)| / |tokens(generated) ∪ tokens(gold)|

Tokens are maximal runs of letters, digits or `:` (so that keyword message
selectors such as `at:put:` stay intact). Punctuation, whitespace and
operators are stripped.

This is the most *lenient* scorer — reformattings, renamings of temporary
variables, and reordered statements will still produce a high score. Useful
as a ""coverage"" metric: did the model at least mention the right identifiers?
"
Class {
	#name : 'ChatPharoBenchmarkTokenOverlapScorer',
	#superclass : 'ChatPharoBenchmarkScorer',
	#category : 'AI-ChatPharo-Benchmarks',
	#package : 'AI-ChatPharo-Benchmarks',
	#tag : 'Scorers'
}

{ #category : 'scoring' }
ChatPharoBenchmarkTokenOverlapScorer >> score: generated against: aCase [

	| a b intersection union |
	a := self tokensOf: generated.
	b := self tokensOf: aCase goldSource.
	(a isEmpty and: [ b isEmpty ]) ifTrue: [ ^ 1.0 ].
	(a isEmpty or: [ b isEmpty ]) ifTrue: [ ^ 0.0 ].
	intersection := a copy.
	intersection := intersection select: [ :t | b includes: t ].
	union := a copy.
	b do: [ :t | union add: t ].
	^ intersection size / union size
]

{ #category : 'accessing' }
ChatPharoBenchmarkTokenOverlapScorer >> scoreName [

	^ 'tokenOverlap'
]

{ #category : 'private' }
ChatPharoBenchmarkTokenOverlapScorer >> tokensOf: aString [

	| set current flush |
	set := Set new.
	aString ifNil: [ ^ set ].
	current := WriteStream on: String new.
	flush := [
		| token |
		token := current contents.
		token isEmpty ifFalse: [ set add: token ].
		current := WriteStream on: String new ].
	aString do: [ :c |
		(c isLetter or: [ c isDigit or: [ c = $: or: [ c = $_ ] ] ])
			ifTrue: [ current nextPut: c ]
			ifFalse: [ flush value ] ].
	flush value.
	^ set
]
