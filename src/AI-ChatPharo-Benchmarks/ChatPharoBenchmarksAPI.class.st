"
High-level entry point — the class most users should interact with.

Three things you can do, all with one-liners:

### 1. Build a benchmark from a live package

```smalltalk
bench := ChatPharoBenchmarksAPI buildFromPackage: 'AI-ChatPharo-Tools'.
ChatPharoBenchmarksAPI save: bench.
```

Builds fresh gold data from the current image. Re-run after a package change
and you get fresh cases — the whole point of having this live.

### 2. Run a benchmark against an agent

```smalltalk
agent := ChatPharoSettings default agent.
report := ChatPharoBenchmarksAPI
             run: bench
             withAgent: agent
             strategy: #ecosystem.
ChatPharoBenchmarksAPI save: report.
```

`strategy` is either `#ecosystem` (full ChatPharo pipeline, tools, history) or
`#rawLLM` (single call, no tools, neutral system). Each result carries which
model, which API base URL, and whether tool calls happened.

### 3. Compare both strategies head-to-head

```smalltalk
comparison := ChatPharoBenchmarksAPI
                  compare: bench
                  ecosystemAgent: agent
                  rawAgent: agent.
comparison asDictionary.
```

The comparison tells you on which cases the ecosystem actually helped the
model, and on which it hurt.

### Configurability

Every one-liner above has a `with:` variant that accepts a
`ChatPharoBenchmarkConfiguration` instance so you can tweak scorers,
threshold, concurrency, prompt template, etc.
"
Class {
	#name : 'ChatPharoBenchmarksAPI',
	#superclass : 'Object',
	#category : 'AI-ChatPharo-Benchmarks',
	#package : 'AI-ChatPharo-Benchmarks',
	#tag : 'API'
}

{ #category : 'building' }
ChatPharoBenchmarksAPI class >> buildFromPackage: aPackageName [
	"Build a method-generation benchmark from the given Pharo package,
	 using sensible defaults. See `ChatPharoBenchmarkBuilder` for full options."

	^ ChatPharoBenchmarkBuilder new
		  packageNamed: aPackageName;
		  build
]

{ #category : 'building' }
ChatPharoBenchmarksAPI class >> buildFromPackage: aPackageName kind: aKind [

	^ ChatPharoBenchmarkBuilder new
		  packageNamed: aPackageName;
		  kind: aKind;
		  build
]

{ #category : 'comparing' }
ChatPharoBenchmarksAPI class >> compare: aBenchmark ecosystemAgent: ecosystemAgent rawAgent: rawAgent [
	"Run the benchmark twice — once through the full ChatPharo ecosystem
	 and once as a raw LLM call — and return a `ChatPharoBenchmarkComparison`."

	| ecoReport rawReport |
	ecoReport := self
		             run: aBenchmark
		             withAgent: ecosystemAgent
		             strategy: #ecosystem.
	rawReport := self
		             run: aBenchmark
		             withAgent: rawAgent
		             strategy: #rawLLM.
	^ ChatPharoBenchmarkComparison
		  reports: { ecoReport. rawReport }
		  labels: #( 'ChatPharo ecosystem' 'Raw LLM' )
]

{ #category : 'comparing' }
ChatPharoBenchmarksAPI class >> compare: aBenchmark withConfigurations: aConfigCollection [
	"Run the benchmark with each configuration and return a
	 `ChatPharoBenchmarkComparison`."

	| reports labels |
	reports := aConfigCollection collect: [ :cfg |
		           self run: aBenchmark withConfiguration: cfg ].
	labels := aConfigCollection collect: [ :cfg | cfg label ].
	^ ChatPharoBenchmarkComparison
		  reports: reports asArray
		  labels: labels asArray
]

{ #category : 'loading' }
ChatPharoBenchmarksAPI class >> loadBenchmarkFrom: aFileReference [

	^ ChatPharoBenchmarkStore default loadBenchmarkFrom: aFileReference
]

{ #category : 'loading' }
ChatPharoBenchmarksAPI class >> loadReportFrom: aFileReference [

	^ ChatPharoBenchmarkStore default loadReportFrom: aFileReference
]

{ #category : 'running' }
ChatPharoBenchmarksAPI class >> run: aBenchmark withAgent: anAgent strategy: aStrategy [
	"Run `aBenchmark` against `anAgent` using the given strategy
	 (#ecosystem or #rawLLM). Returns a `ChatPharoBenchmarkReport`."

	| config |
	config := aStrategy = #ecosystem
		          ifTrue: [ ChatPharoBenchmarkConfiguration ecosystemWith: anAgent ]
		          ifFalse: [ ChatPharoBenchmarkConfiguration rawLLMWith: anAgent ].
	^ self run: aBenchmark withConfiguration: config
]

{ #category : 'running' }
ChatPharoBenchmarksAPI class >> run: aBenchmark withConfiguration: aConfig [

	^ (ChatPharoBenchmarkRunner benchmark: aBenchmark configuration: aConfig) run
]

{ #category : 'saving' }
ChatPharoBenchmarksAPI class >> save: aBenchmarkOrReport [
	"Dispatch on runtime type so users don't have to pick the right method."

	(aBenchmarkOrReport isKindOf: ChatPharoBenchmark) ifTrue: [
		^ ChatPharoBenchmarkStore default save: aBenchmarkOrReport ].
	(aBenchmarkOrReport isKindOf: ChatPharoBenchmarkReport) ifTrue: [
		^ ChatPharoBenchmarkStore default saveReport: aBenchmarkOrReport ].
	^ self error: 'ChatPharoBenchmarksAPI>>save: expects a ChatPharoBenchmark or ChatPharoBenchmarkReport'
]

{ #category : 'saving' }
ChatPharoBenchmarksAPI class >> save: aBenchmarkOrReport to: aFileReference [
	"Save to a custom location by pointing a dedicated store at the given root."

	| store |
	store := ChatPharoBenchmarkStore new.
	store root: aFileReference asFileReference.
	(aBenchmarkOrReport isKindOf: ChatPharoBenchmark) ifTrue: [
		^ store save: aBenchmarkOrReport ].
	(aBenchmarkOrReport isKindOf: ChatPharoBenchmarkReport) ifTrue: [
		^ store saveReport: aBenchmarkOrReport ].
	^ self error: 'ChatPharoBenchmarksAPI>>save:to: expects a ChatPharoBenchmark or ChatPharoBenchmarkReport'
]
