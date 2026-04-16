"
Aggregated statistics for a full benchmark *run*.

One report corresponds to: **one benchmark × one configuration** (i.e. one
agent+strategy tuple). Use `ChatPharoBenchmarkComparison` when you want to
contrast two reports (for example ""ChatPharo ecosystem"" vs ""raw LLM"").

The report owns the complete set of `ChatPharoBenchmarkResult` objects and
derives convenience summaries on top of them:

* `passRate` — fraction of cases that pass the primary scorer threshold.
* `averageScoreNamed:` — mean of a given scorer across all results.
* `averageLatencyMs`, `totalTokens`, `totalToolCalls` — operational cost.

Reports are pure data: they can be written to disk in JSON/STON by
`ChatPharoBenchmarkStore` and loaded back verbatim.
"
Class {
	#name : 'ChatPharoBenchmarkReport',
	#superclass : 'Object',
	#instVars : [
		'benchmarkName',
		'benchmarkVersion',
		'sourcePackage',
		'strategy',
		'agentClassName',
		'modelName',
		'apiBaseURL',
		'toolsEnabled',
		'results',
		'startedAt',
		'finishedAt',
		'metadata'
	],
	#category : 'AI-ChatPharo-Benchmarks',
	#package : 'AI-ChatPharo-Benchmarks',
	#tag : 'Core'
}

{ #category : 'instance creation' }
ChatPharoBenchmarkReport class >> fromDictionary: aDictionary [

	| report rawResults |
	report := self new.
	report benchmarkName: (aDictionary at: 'benchmarkName' ifAbsent: [ 'unnamed' ]).
	report benchmarkVersion: (aDictionary at: 'benchmarkVersion' ifAbsent: [ '1' ]).
	report sourcePackage: (aDictionary at: 'sourcePackage' ifAbsent: [ nil ]).
	report strategy: (aDictionary at: 'strategy' ifAbsent: [ 'rawLLM' ]) asSymbol.
	report agentClassName: (aDictionary at: 'agentClassName' ifAbsent: [ nil ]).
	report modelName: (aDictionary at: 'modelName' ifAbsent: [ nil ]).
	report apiBaseURL: (aDictionary at: 'apiBaseURL' ifAbsent: [ nil ]).
	report toolsEnabled: (aDictionary at: 'toolsEnabled' ifAbsent: [ false ]).
	report startedAt: (aDictionary at: 'startedAt' ifAbsent: [ nil ]).
	report finishedAt: (aDictionary at: 'finishedAt' ifAbsent: [ nil ]).
	report metadata: (aDictionary at: 'metadata' ifAbsent: [ Dictionary new ]).
	rawResults := aDictionary at: 'results' ifAbsent: [ #(  ) ].
	report results:
		((rawResults collect: [ :d | ChatPharoBenchmarkResult fromDictionary: d ])
			 asOrderedCollection).
	^ report
]

{ #category : 'adding' }
ChatPharoBenchmarkReport >> addResult: aResult [

	results add: aResult.
	^ aResult
]

{ #category : 'accessing' }
ChatPharoBenchmarkReport >> agentClassName [

	^ agentClassName
]

{ #category : 'accessing' }
ChatPharoBenchmarkReport >> agentClassName: anObject [

	agentClassName := anObject
]

{ #category : 'accessing' }
ChatPharoBenchmarkReport >> apiBaseURL [

	^ apiBaseURL
]

{ #category : 'accessing' }
ChatPharoBenchmarkReport >> apiBaseURL: anObject [

	apiBaseURL := anObject
]

{ #category : 'accessing' }
ChatPharoBenchmarkReport >> asDictionary [

	^ Dictionary new
		  at: 'benchmarkName' put: benchmarkName;
		  at: 'benchmarkVersion' put: benchmarkVersion;
		  at: 'sourcePackage' put: sourcePackage;
		  at: 'strategy' put: strategy asString;
		  at: 'agentClassName' put: agentClassName;
		  at: 'modelName' put: modelName;
		  at: 'apiBaseURL' put: (apiBaseURL ifNil: [ '' ]) asString;
		  at: 'toolsEnabled' put: toolsEnabled;
		  at: 'startedAt' put: (startedAt ifNil: [ '' ]) asString;
		  at: 'finishedAt' put: (finishedAt ifNil: [ '' ]) asString;
		  at: 'metadata' put: (metadata ifNil: [ Dictionary new ]);
		  at: 'summary' put: self summary;
		  at: 'results' put: (results collect: [ :r | r asDictionary ]) asArray;
		  yourself
]

{ #category : 'statistics' }
ChatPharoBenchmarkReport >> averageLatencyMs [

	results isEmpty ifTrue: [ ^ 0 ].
	^ (results inject: 0 into: [ :acc :r | acc + (r latencyMs ifNil: [ 0 ]) ])
	  / results size
]

{ #category : 'statistics' }
ChatPharoBenchmarkReport >> averageScoreNamed: aScorerName [

	| values |
	values := results
		          collect: [ :r | r scores at: aScorerName ifAbsent: [ nil ] ]
		          thenSelect: [ :each | each notNil ].
	values isEmpty ifTrue: [ ^ 0.0 ].
	^ (values inject: 0.0 into: [ :acc :v | acc + v ]) / values size
]

{ #category : 'accessing' }
ChatPharoBenchmarkReport >> benchmarkName [

	^ benchmarkName
]

{ #category : 'accessing' }
ChatPharoBenchmarkReport >> benchmarkName: anObject [

	benchmarkName := anObject
]

{ #category : 'accessing' }
ChatPharoBenchmarkReport >> benchmarkVersion [

	^ benchmarkVersion
]

{ #category : 'accessing' }
ChatPharoBenchmarkReport >> benchmarkVersion: anObject [

	benchmarkVersion := anObject asString
]

{ #category : 'statistics' }
ChatPharoBenchmarkReport >> failureCount [

	^ results size - self passCount
]

{ #category : 'accessing' }
ChatPharoBenchmarkReport >> finishedAt [

	^ finishedAt
]

{ #category : 'accessing' }
ChatPharoBenchmarkReport >> finishedAt: anObject [

	finishedAt := anObject
]

{ #category : 'initialization' }
ChatPharoBenchmarkReport >> initialize [

	super initialize.
	results := OrderedCollection new.
	strategy := #rawLLM.
	toolsEnabled := false.
	metadata := Dictionary new
]

{ #category : 'accessing' }
ChatPharoBenchmarkReport >> metadata [

	^ metadata
]

{ #category : 'accessing' }
ChatPharoBenchmarkReport >> metadata: anObject [

	metadata := anObject ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
ChatPharoBenchmarkReport >> modelName [

	^ modelName
]

{ #category : 'accessing' }
ChatPharoBenchmarkReport >> modelName: anObject [

	modelName := anObject
]

{ #category : 'statistics' }
ChatPharoBenchmarkReport >> passCount [

	^ (results select: [ :r | r passed ]) size
]

{ #category : 'statistics' }
ChatPharoBenchmarkReport >> passRate [

	results isEmpty ifTrue: [ ^ 0.0 ].
	^ self passCount / results size
]

{ #category : 'printing' }
ChatPharoBenchmarkReport >> printOn: aStream [

	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: (benchmarkName ifNil: [ '?' ]);
		nextPutAll: '/';
		nextPutAll: strategy asString;
		nextPutAll: ' ';
		print: self passCount;
		nextPutAll: '/';
		print: results size;
		nextPutAll: ' passed)'
]

{ #category : 'accessing' }
ChatPharoBenchmarkReport >> results [

	^ results
]

{ #category : 'accessing' }
ChatPharoBenchmarkReport >> results: anObject [

	results := anObject asOrderedCollection
]

{ #category : 'accessing' }
ChatPharoBenchmarkReport >> sourcePackage [

	^ sourcePackage
]

{ #category : 'accessing' }
ChatPharoBenchmarkReport >> sourcePackage: anObject [

	sourcePackage := anObject
]

{ #category : 'accessing' }
ChatPharoBenchmarkReport >> startedAt [

	^ startedAt
]

{ #category : 'accessing' }
ChatPharoBenchmarkReport >> startedAt: anObject [

	startedAt := anObject
]

{ #category : 'accessing' }
ChatPharoBenchmarkReport >> strategy [

	^ strategy
]

{ #category : 'accessing' }
ChatPharoBenchmarkReport >> strategy: aSymbol [

	strategy := aSymbol asSymbol
]

{ #category : 'statistics' }
ChatPharoBenchmarkReport >> summary [

	| scorerNames averages |
	scorerNames := Set new.
	results do: [ :r | r scores keysDo: [ :k | scorerNames add: k ] ].
	averages := Dictionary new.
	scorerNames do: [ :name |
		averages at: name put: (self averageScoreNamed: name) ].
	^ Dictionary new
		  at: 'total' put: results size;
		  at: 'passed' put: self passCount;
		  at: 'failed' put: self failureCount;
		  at: 'passRate' put: self passRate asFloat;
		  at: 'averageLatencyMs' put: self averageLatencyMs asFloat;
		  at: 'totalTokens' put: self totalTokens;
		  at: 'totalToolCalls' put: self totalToolCalls;
		  at: 'averageScores' put: averages;
		  yourself
]

{ #category : 'accessing' }
ChatPharoBenchmarkReport >> toolsEnabled [

	^ toolsEnabled
]

{ #category : 'accessing' }
ChatPharoBenchmarkReport >> toolsEnabled: aBoolean [

	toolsEnabled := aBoolean
]

{ #category : 'statistics' }
ChatPharoBenchmarkReport >> totalToolCalls [

	^ results inject: 0 into: [ :acc :r | acc + (r toolCallCount ifNil: [ 0 ]) ]
]

{ #category : 'statistics' }
ChatPharoBenchmarkReport >> totalTokens [

	^ results inject: 0 into: [ :acc :r | acc + (r totalTokens ifNil: [ 0 ]) ]
]
