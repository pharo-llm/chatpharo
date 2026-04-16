"
Whitespace-insensitive exact match. Both strings are normalised via
`ChatPharoBenchmarkCodeExtractor>>normalizeWhitespace:` (runs of whitespace
collapsed to a single space, edges trimmed), then compared.

This is the default primary scorer: it rejects nonsense but tolerates
harmless formatting drift.
"
Class {
	#name : 'ChatPharoBenchmarkNormalizedMatchScorer',
	#superclass : 'ChatPharoBenchmarkScorer',
	#category : 'AI-ChatPharo-Benchmarks',
	#package : 'AI-ChatPharo-Benchmarks',
	#tag : 'Scorers'
}

{ #category : 'scoring' }
ChatPharoBenchmarkNormalizedMatchScorer >> score: generated against: aCase [

	| a b |
	a := ChatPharoBenchmarkCodeExtractor normalizeWhitespace: (generated ifNil: [ '' ]).
	b := ChatPharoBenchmarkCodeExtractor normalizeWhitespace: (aCase goldSource ifNil: [ '' ]).
	^ a = b ifTrue: [ 1.0 ] ifFalse: [ 0.0 ]
]

{ #category : 'accessing' }
ChatPharoBenchmarkNormalizedMatchScorer >> scoreName [

	^ 'normalizedMatch'
]
