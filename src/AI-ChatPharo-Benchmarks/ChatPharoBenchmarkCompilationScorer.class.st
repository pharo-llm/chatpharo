"
A minimal sanity check: does the generated code at least *parse* as a Pharo
method? 1.0 if yes, 0.0 otherwise. Not a correctness signal — just a
syntax signal. Useful to distinguish ""the model produced nonsense"" from
""the model produced a wrong but valid method"".
"
Class {
	#name : 'ChatPharoBenchmarkCompilationScorer',
	#superclass : 'ChatPharoBenchmarkScorer',
	#category : 'AI-ChatPharo-Benchmarks',
	#package : 'AI-ChatPharo-Benchmarks',
	#tag : 'Scorers'
}

{ #category : 'scoring' }
ChatPharoBenchmarkCompilationScorer >> score: generated against: aCase [

	| parserClass |
	generated isNil ifTrue: [ ^ 0.0 ].
	generated trimBoth isEmpty ifTrue: [ ^ 0.0 ].
	parserClass := Smalltalk globals at: #RBParser ifAbsent: [ nil ].
	parserClass ifNil: [ ^ 0.0 ].
	^ [
	  parserClass parseMethod: generated.
	  1.0 ]
		  on: Error
		  do: [ [
			  parserClass parseExpression: generated.
			  1.0 ]
			  on: Error
			  do: [ 0.0 ] ]
]

{ #category : 'accessing' }
ChatPharoBenchmarkCompilationScorer >> scoreName [

	^ 'compilation'
]
