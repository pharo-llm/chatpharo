"
Side-by-side comparison of two (or more) `ChatPharoBenchmarkReport`s against
the **same benchmark**. The obvious use case is:

* Report A: `#ecosystem` (ChatPharo with tools, browser env, multi-turn).
* Report B: `#rawLLM` (plain vendor call, no tools, neutral system prompt).

…which answers the question: *does the ChatPharo ecosystem actually help
this model, and on which cases?*

`#differences` returns a collection of per-case dictionaries for cases where
the result flipped between the reports, so downstream dashboards can focus
human review on the meaningful deltas.

Output dictionary shape (from `#asDictionary`):
```
{
  'benchmark': name,
  'reports': [ { label, strategy, model, passRate, passed, failed }, … ],
  'winnerByCase': { caseId: 'A' | 'B' | 'tie' },
  'overall': { 'byLabel': { label: passRate } }
}
```
"
Class {
	#name : 'ChatPharoBenchmarkComparison',
	#superclass : 'Object',
	#instVars : [
		'reports',
		'labels'
	],
	#category : 'AI-ChatPharo-Benchmarks',
	#package : 'AI-ChatPharo-Benchmarks',
	#tag : 'Core'
}

{ #category : 'instance creation' }
ChatPharoBenchmarkComparison class >> reports: aCollection labels: aLabelCollection [

	^ self new
		  reports: aCollection;
		  labels: aLabelCollection;
		  yourself
]

{ #category : 'accessing' }
ChatPharoBenchmarkComparison >> asDictionary [

	| byCase reportDicts byLabel |
	reportDicts := reports withIndexCollect: [ :r :i |
		               Dictionary new
			               at: 'label' put: (labels at: i ifAbsent: [ r strategy asString ]);
			               at: 'strategy' put: r strategy asString;
			               at: 'model' put: r modelName;
			               at: 'agent' put: r agentClassName;
			               at: 'passRate' put: r passRate asFloat;
			               at: 'passed' put: r passCount;
			               at: 'failed' put: r failureCount;
			               at: 'averageLatencyMs' put: r averageLatencyMs asFloat;
			               at: 'totalTokens' put: r totalTokens;
			               at: 'totalToolCalls' put: r totalToolCalls;
			               yourself ].
	byCase := self winnerByCase.
	byLabel := Dictionary new.
	reports withIndexDo: [ :r :i |
		byLabel
			at: (labels at: i ifAbsent: [ r strategy asString ])
			put: r passRate asFloat ].
	^ Dictionary new
		  at: 'reports' put: reportDicts asArray;
		  at: 'winnerByCase' put: byCase;
		  at: 'overall' put: (Dictionary new at: 'byLabel' put: byLabel; yourself);
		  at: 'differences' put: self differences asArray;
		  yourself
]

{ #category : 'analysis' }
ChatPharoBenchmarkComparison >> differences [
	"Cases that did NOT all agree across the reports (pass/fail flipped)."

	| caseIds diffs |
	reports size < 2 ifTrue: [ ^ #(  ) ].
	caseIds := Set new.
	reports do: [ :r | r results do: [ :res | caseIds add: res caseId ] ].
	diffs := OrderedCollection new.
	caseIds do: [ :cid |
		| statuses |
		statuses := reports collect: [ :r |
			            | res |
			            res := r results detect: [ :each | each caseId = cid ] ifNone: [ nil ].
			            res ifNil: [ nil ] ifNotNil: [ res passed ] ].
		(statuses asSet size > 1) ifTrue: [
			diffs add: (Dictionary new
					 at: 'caseId' put: cid;
					 at: 'statuses' put: statuses asArray;
					 yourself) ] ].
	^ diffs
]

{ #category : 'accessing' }
ChatPharoBenchmarkComparison >> labels [

	^ labels
]

{ #category : 'accessing' }
ChatPharoBenchmarkComparison >> labels: aCollection [

	labels := aCollection asArray
]

{ #category : 'accessing' }
ChatPharoBenchmarkComparison >> reports [

	^ reports
]

{ #category : 'accessing' }
ChatPharoBenchmarkComparison >> reports: aCollection [

	reports := aCollection asArray
]

{ #category : 'analysis' }
ChatPharoBenchmarkComparison >> winnerByCase [
	"For each case id, the index (1-based) of the single report that passed
	 while others failed, or 'tie' if ambiguous."

	| caseIds result |
	caseIds := Set new.
	reports do: [ :r | r results do: [ :res | caseIds add: res caseId ] ].
	result := Dictionary new.
	caseIds do: [ :cid |
		| passes |
		passes := OrderedCollection new.
		reports withIndexDo: [ :r :i |
			(r results anySatisfy: [ :res | res caseId = cid and: [ res passed ] ])
				ifTrue: [ passes add: i ] ].
		passes size = 1
			ifTrue: [ result at: cid put: (passes first asString) ]
			ifFalse: [ result at: cid put: 'tie' ] ].
	^ result
]
