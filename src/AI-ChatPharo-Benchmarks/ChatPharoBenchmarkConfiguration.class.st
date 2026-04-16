"
Describes *how* a benchmark should be run.

One configuration = one row in the final comparison table. It captures:

* `strategy` – `#ecosystem` (use the full ChatPharo agent, tools enabled,
  history, retry loop) or `#rawLLM` (minimal one-shot call, no tools, neutral
  system prompt).
* `agent` – the `ChatPharoAgent` subclass instance providing credentials
  (API key, model, baseURL). The runner reads *from* it; it does not mutate
  the user's shared settings.
* `scorers` – which scorers to apply. Defaults to
  `ChatPharoBenchmarkScorer defaultScorerSet`.
* `primaryScorerName` – scorer that decides `passed` status via `passThreshold`.
* `passThreshold` – float in [0,1]. Default 0.9.
* `timeoutSeconds` – hard wall-clock limit per case (defensive; outside of
  the vendor's own timeout).
* `maxConcurrency` – how many cases to run in parallel (via `#fork`).
  Default 1 (serial) because most vendors rate-limit.
* `label` – free-form human label displayed in reports/comparisons.
"
Class {
	#name : 'ChatPharoBenchmarkConfiguration',
	#superclass : 'Object',
	#instVars : [
		'label',
		'strategy',
		'agent',
		'scorers',
		'primaryScorerName',
		'passThreshold',
		'timeoutSeconds',
		'maxConcurrency',
		'promptTemplate',
		'metadata'
	],
	#category : 'AI-ChatPharo-Benchmarks',
	#package : 'AI-ChatPharo-Benchmarks',
	#tag : 'Runner'
}

{ #category : 'instance creation' }
ChatPharoBenchmarkConfiguration class >> ecosystemWith: anAgent [
	"Full ChatPharo ecosystem: tools, browser env, multi-turn tool calls."

	^ self new
		  label: 'ChatPharo ecosystem';
		  strategy: #ecosystem;
		  agent: anAgent;
		  yourself
]

{ #category : 'instance creation' }
ChatPharoBenchmarkConfiguration class >> rawLLMWith: anAgent [
	"Single-shot call to the underlying vendor API, no tools, neutral system."

	^ self new
		  label: 'Raw LLM (no ChatPharo ecosystem)';
		  strategy: #rawLLM;
		  agent: anAgent;
		  yourself
]

{ #category : 'accessing' }
ChatPharoBenchmarkConfiguration >> agent [

	^ agent
]

{ #category : 'accessing' }
ChatPharoBenchmarkConfiguration >> agent: anObject [

	agent := anObject
]

{ #category : 'initialization' }
ChatPharoBenchmarkConfiguration >> initialize [

	super initialize.
	label := 'unnamed'.
	strategy := #rawLLM.
	scorers := ChatPharoBenchmarkScorer defaultScorerSet.
	primaryScorerName := 'normalizedMatch'.
	passThreshold := 0.9.
	timeoutSeconds := 120.
	maxConcurrency := 1.
	metadata := Dictionary new
]

{ #category : 'accessing' }
ChatPharoBenchmarkConfiguration >> label [

	^ label
]

{ #category : 'accessing' }
ChatPharoBenchmarkConfiguration >> label: anObject [

	label := anObject
]

{ #category : 'accessing' }
ChatPharoBenchmarkConfiguration >> maxConcurrency [

	^ maxConcurrency
]

{ #category : 'accessing' }
ChatPharoBenchmarkConfiguration >> maxConcurrency: anInteger [

	maxConcurrency := anInteger max: 1
]

{ #category : 'accessing' }
ChatPharoBenchmarkConfiguration >> metadata [

	^ metadata
]

{ #category : 'accessing' }
ChatPharoBenchmarkConfiguration >> metadata: anObject [

	metadata := anObject ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
ChatPharoBenchmarkConfiguration >> passThreshold [

	^ passThreshold
]

{ #category : 'accessing' }
ChatPharoBenchmarkConfiguration >> passThreshold: aFloat [

	passThreshold := aFloat
]

{ #category : 'accessing' }
ChatPharoBenchmarkConfiguration >> primaryScorerName [

	^ primaryScorerName
]

{ #category : 'accessing' }
ChatPharoBenchmarkConfiguration >> primaryScorerName: anObject [

	primaryScorerName := anObject
]

{ #category : 'printing' }
ChatPharoBenchmarkConfiguration >> printOn: aStream [

	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: label;
		nextPutAll: ' / ';
		nextPutAll: strategy asString;
		nextPutAll: ')'
]

{ #category : 'accessing' }
ChatPharoBenchmarkConfiguration >> promptTemplate [

	^ promptTemplate ifNil: [ promptTemplate := ChatPharoBenchmarkPromptTemplate default ]
]

{ #category : 'accessing' }
ChatPharoBenchmarkConfiguration >> promptTemplate: aTemplate [

	promptTemplate := aTemplate
]

{ #category : 'accessing' }
ChatPharoBenchmarkConfiguration >> scorers [

	^ scorers
]

{ #category : 'accessing' }
ChatPharoBenchmarkConfiguration >> scorers: aCollection [

	scorers := aCollection asOrderedCollection
]

{ #category : 'accessing' }
ChatPharoBenchmarkConfiguration >> strategy [

	^ strategy
]

{ #category : 'accessing' }
ChatPharoBenchmarkConfiguration >> strategy: aSymbol [

	strategy := aSymbol asSymbol
]

{ #category : 'accessing' }
ChatPharoBenchmarkConfiguration >> timeoutSeconds [

	^ timeoutSeconds
]

{ #category : 'accessing' }
ChatPharoBenchmarkConfiguration >> timeoutSeconds: anObject [

	timeoutSeconds := anObject
]
