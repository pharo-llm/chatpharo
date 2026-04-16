"
Binary exact-string match scorer. 1.0 iff `generated = goldSource`, else 0.0.
"
Class {
	#name : 'ChatPharoBenchmarkExactMatchScorer',
	#superclass : 'ChatPharoBenchmarkScorer',
	#category : 'AI-ChatPharo-Benchmarks',
	#package : 'AI-ChatPharo-Benchmarks',
	#tag : 'Scorers'
}

{ #category : 'scoring' }
ChatPharoBenchmarkExactMatchScorer >> score: generated against: aCase [

	^ generated = aCase goldSource
		  ifTrue: [ 1.0 ]
		  ifFalse: [ 0.0 ]
]

{ #category : 'accessing' }
ChatPharoBenchmarkExactMatchScorer >> scoreName [

	^ 'exactMatch'
]
