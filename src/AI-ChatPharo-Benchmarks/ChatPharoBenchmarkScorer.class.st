"
Abstract superclass for benchmark scorers.

A scorer maps `(case, llmOutput)` → Float in `[0.0, 1.0]`. Each scorer reports
under a **stable name** (see `#scoreName`) which is used as the key in
`ChatPharoBenchmarkResult >> scores` and referenced by configurations to pick
the *primary* scorer for pass/fail deciding.

Subclasses override at minimum:

* `scoreName` – unique short identifier (e.g. 'exactMatch', 'astMatch').
* `score:against:` – return a Float in [0,1].

Why multiple scorers?
---------------------
For code, no single metric is perfect. `exactMatch` is too strict,
`normalizedMatch` ignores whitespace, `astMatch` ignores variable renaming,
`tokenOverlap` is robust to formatting, `compilation` only asks ""does it
parse?"". Running several and averaging is almost always more informative
than any one alone.
"
Class {
	#name : 'ChatPharoBenchmarkScorer',
	#superclass : 'Object',
	#category : 'AI-ChatPharo-Benchmarks',
	#package : 'AI-ChatPharo-Benchmarks',
	#tag : 'Scorers'
}

{ #category : 'defaults' }
ChatPharoBenchmarkScorer class >> defaultScorerSet [
	"Cheap, deterministic scorers that make sense without network access."

	^ OrderedCollection new
		  add: ChatPharoBenchmarkExactMatchScorer new;
		  add: ChatPharoBenchmarkNormalizedMatchScorer new;
		  add: ChatPharoBenchmarkASTMatchScorer new;
		  add: ChatPharoBenchmarkCompilationScorer new;
		  add: ChatPharoBenchmarkTokenOverlapScorer new;
		  yourself
]

{ #category : 'scoring' }
ChatPharoBenchmarkScorer >> score: generated against: aCase [
	"Answer a Float in [0.0, 1.0] expressing how close `generated` is to
	 the gold source of aCase. Subclass responsibility."

	^ self subclassResponsibility
]

{ #category : 'accessing' }
ChatPharoBenchmarkScorer >> scoreName [

	^ self subclassResponsibility
]
