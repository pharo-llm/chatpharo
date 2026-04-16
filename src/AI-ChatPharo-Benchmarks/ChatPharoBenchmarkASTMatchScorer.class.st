"
Structural equality of the parsed Pharo AST.

Falls back to the *RBParser* infrastructure available in the running image.
Two ASTs are considered equal when the Smalltalk equality semantics on the
parsed node match (`= / hash` are implemented structurally on RBProgramNode).

Returns:

* 1.0 – both parse and their ASTs are structurally equal.
* 0.5 – both parse, but the ASTs differ (i.e. syntactically distinct; a
  partial-credit signal preferred over 0 for human analysis).
* 0.0 – the generated code fails to parse.
"
Class {
	#name : 'ChatPharoBenchmarkASTMatchScorer',
	#superclass : 'ChatPharoBenchmarkScorer',
	#category : 'AI-ChatPharo-Benchmarks',
	#package : 'AI-ChatPharo-Benchmarks',
	#tag : 'Scorers'
}

{ #category : 'private' }
ChatPharoBenchmarkASTMatchScorer >> parse: aString [

	| parserClass |
	aString isNil ifTrue: [ ^ nil ].
	aString trimBoth isEmpty ifTrue: [ ^ nil ].
	parserClass := Smalltalk globals at: #RBParser ifAbsent: [ nil ].
	parserClass ifNil: [ ^ nil ].
	^ [ parserClass parseMethod: aString ]
		  on: Error
		  do: [ [ parserClass parseExpression: aString ]
			  on: Error
			  do: [ nil ] ]
]

{ #category : 'scoring' }
ChatPharoBenchmarkASTMatchScorer >> score: generated against: aCase [

	| generatedAst goldAst |
	generatedAst := self parse: generated.
	generatedAst ifNil: [ ^ 0.0 ].
	goldAst := self parse: aCase goldSource.
	goldAst ifNil: [ ^ 0.5 ].
	^ (generatedAst = goldAst) ifTrue: [ 1.0 ] ifFalse: [ 0.5 ]
]

{ #category : 'accessing' }
ChatPharoBenchmarkASTMatchScorer >> scoreName [

	^ 'astMatch'
]
