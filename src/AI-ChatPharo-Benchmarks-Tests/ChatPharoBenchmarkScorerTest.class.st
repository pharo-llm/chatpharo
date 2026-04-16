"
Smoke tests for the scorers — pure logic, no network, fast.
"
Class {
	#name : 'ChatPharoBenchmarkScorerTest',
	#superclass : 'TestCase',
	#category : 'AI-ChatPharo-Benchmarks-Tests',
	#package : 'AI-ChatPharo-Benchmarks-Tests'
}

{ #category : 'fixtures' }
ChatPharoBenchmarkScorerTest >> caseWithGold: aGold [

	^ ChatPharoBenchmarkCase new
		  goldSource: aGold;
		  className: 'Dummy';
		  selector: 'foo';
		  yourself
]

{ #category : 'tests' }
ChatPharoBenchmarkScorerTest >> testCompilationScorerRejectsGarbage [

	| scorer case |
	scorer := ChatPharoBenchmarkCompilationScorer new.
	case := self caseWithGold: 'foo ^ 42'.
	self assert: (scorer score: 'this is not code !!!' against: case) equals: 0.0
]

{ #category : 'tests' }
ChatPharoBenchmarkScorerTest >> testExactMatchIdentical [

	| scorer case |
	scorer := ChatPharoBenchmarkExactMatchScorer new.
	case := self caseWithGold: 'foo ^ 42'.
	self assert: (scorer score: 'foo ^ 42' against: case) equals: 1.0
]

{ #category : 'tests' }
ChatPharoBenchmarkScorerTest >> testExactMatchRejectsDifference [

	| scorer case |
	scorer := ChatPharoBenchmarkExactMatchScorer new.
	case := self caseWithGold: 'foo ^ 42'.
	self assert: (scorer score: 'foo ^ 41' against: case) equals: 0.0
]

{ #category : 'tests' }
ChatPharoBenchmarkScorerTest >> testExtractorHandlesFencedBlock [

	| code |
	code := ChatPharoBenchmarkCodeExtractor extractFrom:
		        'Some preamble

```smalltalk
foo ^ 42
```

tail'.
	self assert: code equals: 'foo ^ 42'
]

{ #category : 'tests' }
ChatPharoBenchmarkScorerTest >> testExtractorHandlesNoFence [

	| code |
	code := ChatPharoBenchmarkCodeExtractor extractFrom: '   foo ^ 42   '.
	self assert: code equals: 'foo ^ 42'
]

{ #category : 'tests' }
ChatPharoBenchmarkScorerTest >> testNormalizedMatchIgnoresWhitespace [

	| scorer case |
	scorer := ChatPharoBenchmarkNormalizedMatchScorer new.
	case := self caseWithGold: 'foo

	^ 42'.
	self assert: (scorer score: 'foo  ^  42' against: case) equals: 1.0
]

{ #category : 'tests' }
ChatPharoBenchmarkScorerTest >> testTokenOverlapIsSymmetric [

	| scorer case a b |
	scorer := ChatPharoBenchmarkTokenOverlapScorer new.
	case := self caseWithGold: 'foo ^ self bar'.
	a := scorer score: 'foo ^ self bar' against: case.
	b := scorer score: (case goldSource) against: case.
	self assert: a equals: b.
	self assert: a equals: 1.0
]
