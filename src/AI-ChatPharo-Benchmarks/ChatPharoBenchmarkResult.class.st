"
The **result of running one benchmark case** with a concrete agent
configuration.

A `ChatPharoBenchmarkResult` captures *everything* that is needed to reproduce,
analyse and grade a single LLM interaction:

* Which case it belongs to (`caseId`).
* Exactly *which API / model* was used, and *whether tools were enabled* (the
  user asked for this explicitly: the result must make it obvious whether the
  answer came from the raw LLM or from the full ChatPharo ecosystem).
* How long the call took and how many tokens it consumed.
* How many tool calls the agent issued during the turn (0 for raw LLM mode).
* The raw LLM response plus the *extracted code block* — scoring and human
  inspection both look at these.
* A `scores` dictionary: each `ChatPharoBenchmarkScorer` contributes one
  entry (scorer name → score in [0.0, 1.0]). The aggregated `passed` flag is
  simply `score >= passThreshold` on the configured primary scorer.

The result is *JSON-friendly* (see `#asDictionary`), so it can be written
to disk by `ChatPharoBenchmarkStore`.
"
Class {
	#name : 'ChatPharoBenchmarkResult',
	#superclass : 'Object',
	#instVars : [
		'caseId',
		'caseDescription',
		'strategy',
		'agentClassName',
		'modelName',
		'apiBaseURL',
		'toolsEnabled',
		'toolCallCount',
		'toolCallNames',
		'promptTokens',
		'completionTokens',
		'totalTokens',
		'latencyMs',
		'rawResponse',
		'extractedCode',
		'scores',
		'passed',
		'errorMessage',
		'startedAt',
		'finishedAt'
	],
	#category : 'AI-ChatPharo-Benchmarks',
	#package : 'AI-ChatPharo-Benchmarks',
	#tag : 'Core'
}

{ #category : 'instance creation' }
ChatPharoBenchmarkResult class >> fromDictionary: aDictionary [

	^ self new
		  caseId: (aDictionary at: 'caseId' ifAbsent: [ nil ]);
		  caseDescription: (aDictionary at: 'caseDescription' ifAbsent: [ '' ]);
		  strategy: (aDictionary at: 'strategy' ifAbsent: [ 'rawLLM' ]) asSymbol;
		  agentClassName: (aDictionary at: 'agentClassName' ifAbsent: [ nil ]);
		  modelName: (aDictionary at: 'modelName' ifAbsent: [ nil ]);
		  apiBaseURL: (aDictionary at: 'apiBaseURL' ifAbsent: [ nil ]);
		  toolsEnabled: (aDictionary at: 'toolsEnabled' ifAbsent: [ false ]);
		  toolCallCount: (aDictionary at: 'toolCallCount' ifAbsent: [ 0 ]);
		  toolCallNames: (aDictionary at: 'toolCallNames' ifAbsent: [ #(  ) ]) asArray;
		  promptTokens: (aDictionary at: 'promptTokens' ifAbsent: [ nil ]);
		  completionTokens: (aDictionary at: 'completionTokens' ifAbsent: [ nil ]);
		  totalTokens: (aDictionary at: 'totalTokens' ifAbsent: [ nil ]);
		  latencyMs: (aDictionary at: 'latencyMs' ifAbsent: [ 0 ]);
		  rawResponse: (aDictionary at: 'rawResponse' ifAbsent: [ '' ]);
		  extractedCode: (aDictionary at: 'extractedCode' ifAbsent: [ '' ]);
		  scores: (aDictionary at: 'scores' ifAbsent: [ Dictionary new ]);
		  passed: (aDictionary at: 'passed' ifAbsent: [ false ]);
		  errorMessage: (aDictionary at: 'errorMessage' ifAbsent: [ nil ]);
		  startedAt: (aDictionary at: 'startedAt' ifAbsent: [ nil ]);
		  finishedAt: (aDictionary at: 'finishedAt' ifAbsent: [ nil ]);
		  yourself
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> agentClassName [

	^ agentClassName
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> agentClassName: anObject [

	agentClassName := anObject
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> apiBaseURL [

	^ apiBaseURL
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> apiBaseURL: anObject [

	apiBaseURL := anObject asString
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> asDictionary [

	^ Dictionary new
		  at: 'caseId' put: caseId;
		  at: 'caseDescription' put: (caseDescription ifNil: [ '' ]);
		  at: 'strategy' put: strategy asString;
		  at: 'agentClassName' put: agentClassName;
		  at: 'modelName' put: modelName;
		  at: 'apiBaseURL' put: (apiBaseURL ifNil: [ '' ]);
		  at: 'toolsEnabled' put: toolsEnabled;
		  at: 'toolCallCount' put: toolCallCount;
		  at: 'toolCallNames' put: (toolCallNames ifNil: [ #(  ) ]) asArray;
		  at: 'promptTokens' put: promptTokens;
		  at: 'completionTokens' put: completionTokens;
		  at: 'totalTokens' put: totalTokens;
		  at: 'latencyMs' put: latencyMs;
		  at: 'rawResponse' put: (rawResponse ifNil: [ '' ]);
		  at: 'extractedCode' put: (extractedCode ifNil: [ '' ]);
		  at: 'scores' put: scores;
		  at: 'passed' put: passed;
		  at: 'errorMessage' put: errorMessage;
		  at: 'startedAt' put: (startedAt ifNil: [ '' ]) asString;
		  at: 'finishedAt' put: (finishedAt ifNil: [ '' ]) asString;
		  yourself
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> caseDescription [

	^ caseDescription
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> caseDescription: anObject [

	caseDescription := anObject
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> caseId [

	^ caseId
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> caseId: anObject [

	caseId := anObject
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> completionTokens [

	^ completionTokens
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> completionTokens: anObject [

	completionTokens := anObject
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> errorMessage [

	^ errorMessage
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> errorMessage: anObject [

	errorMessage := anObject
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> extractedCode [

	^ extractedCode
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> extractedCode: anObject [

	extractedCode := anObject
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> finishedAt [

	^ finishedAt
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> finishedAt: anObject [

	finishedAt := anObject
]

{ #category : 'initialization' }
ChatPharoBenchmarkResult >> initialize [

	super initialize.
	strategy := #rawLLM.
	toolsEnabled := false.
	toolCallCount := 0.
	toolCallNames := #(  ).
	latencyMs := 0.
	scores := Dictionary new.
	passed := false
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> latencyMs [

	^ latencyMs
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> latencyMs: anObject [

	latencyMs := anObject
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> modelName [

	^ modelName
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> modelName: anObject [

	modelName := anObject
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> passed [

	^ passed
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> passed: anObject [

	passed := anObject
]

{ #category : 'printing' }
ChatPharoBenchmarkResult >> printOn: aStream [

	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: (caseId ifNil: [ '?' ]);
		nextPutAll: ', ';
		nextPutAll: strategy asString;
		nextPutAll: ', ';
		nextPutAll: (passed ifTrue: [ 'PASS' ] ifFalse: [ 'FAIL' ]);
		nextPutAll: ')'
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> promptTokens [

	^ promptTokens
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> promptTokens: anObject [

	promptTokens := anObject
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> rawResponse [

	^ rawResponse
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> rawResponse: anObject [

	rawResponse := anObject
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> scores [

	^ scores
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> scores: anObject [

	scores := anObject ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> startedAt [

	^ startedAt
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> startedAt: anObject [

	startedAt := anObject
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> strategy [

	^ strategy
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> strategy: aSymbol [

	strategy := aSymbol asSymbol
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> toolCallCount [

	^ toolCallCount
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> toolCallCount: anObject [

	toolCallCount := anObject ifNil: [ 0 ]
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> toolCallNames [

	^ toolCallNames
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> toolCallNames: anObject [

	toolCallNames := anObject asArray
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> toolsEnabled [

	^ toolsEnabled
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> toolsEnabled: aBoolean [

	toolsEnabled := aBoolean
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> totalTokens [

	^ totalTokens
]

{ #category : 'accessing' }
ChatPharoBenchmarkResult >> totalTokens: anObject [

	totalTokens := anObject
]
