"
Runs a `ChatPharoBenchmark` against one or more `ChatPharoBenchmarkConfiguration`s
and produces a `ChatPharoBenchmarkReport` per configuration.

Two strategies are supported, matching the two ways users actually talk to
models:

### `#ecosystem` (full ChatPharo pipeline)

The agent is used verbatim via `agent copyForChat`, which means:

* the agent's system prompt is active,
* `ChatPharoBrowserEnvironment` tools are attached,
* tool calls are dispatched and their results fed back into the model,
* the multi-iteration loop inside `ChatPharoOpenAIAgent >> getResponseForPrompt:`
  (or its sibling in each backend) is honoured.

Tool call counts and names are harvested from the agent's history so you can
see *whether the model actually used tools* and *which ones*.

### `#rawLLM` (no ChatPharo ecosystem)

A one-shot call is made directly through a `ChatPharoTool` instance:

* no Pharo-specific system prompt,
* no tools attached at all (`tools: #()`),
* no iterations,
* no memory / history carry-over across cases.

This isolates the underlying model's native performance and is the fair
comparison baseline.

Both strategies record the *API base URL*, *model name*, *agent class* and
*tools-enabled flag* on every `ChatPharoBenchmarkResult`, so reports make it
unambiguous **which API you were using** and whether you were using tools.

Parallelism
-----------
If `configuration maxConcurrency > 1`, cases are forked and collected through
a `Semaphore`. Rate-limited vendors will usually want to keep the default of
1 (serial).
"
Class {
	#name : 'ChatPharoBenchmarkRunner',
	#superclass : 'Object',
	#instVars : [
		'benchmark',
		'configuration',
		'onCaseFinished',
		'onCaseStarted'
	],
	#category : 'AI-ChatPharo-Benchmarks',
	#package : 'AI-ChatPharo-Benchmarks',
	#tag : 'Runner'
}

{ #category : 'instance creation' }
ChatPharoBenchmarkRunner class >> benchmark: aBenchmark configuration: aConfig [

	^ self new
		  benchmark: aBenchmark;
		  configuration: aConfig;
		  yourself
]

{ #category : 'running' }
ChatPharoBenchmarkRunner >> agentDescriptor [
	"Summary of the agent being used, reused on every result."

	| agent className baseURL apiModel |
	agent := configuration agent.
	agent ifNil: [ ^ Dictionary new ].
	className := agent class name asString.
	baseURL := [ self baseURLOf: agent ] on: Error do: [ '' ].
	apiModel := [ agent model ] on: Error do: [ '' ].
	^ Dictionary new
		  at: 'className' put: className;
		  at: 'baseURL' put: baseURL asString;
		  at: 'model' put: apiModel asString;
		  yourself
]

{ #category : 'private' }
ChatPharoBenchmarkRunner >> baseURLOf: anAgent [
	"Best-effort extraction of the base URL from an agent of any backend."

	| direct host port |
	direct := [ anAgent perform: #baseURL ] on: MessageNotUnderstood do: [ nil ].
	direct ifNotNil: [ ^ direct asString ].
	host := [ anAgent perform: #host ] on: MessageNotUnderstood do: [ nil ].
	port := [ anAgent perform: #port ] on: MessageNotUnderstood do: [ nil ].
	host ifNotNil: [
		^ 'http://' , host asString , (port ifNil: [ '' ] ifNotNil: [ ':' , port asString ]) , '/v1' ].
	^ anAgent class name asString
]

{ #category : 'accessing' }
ChatPharoBenchmarkRunner >> benchmark [

	^ benchmark
]

{ #category : 'accessing' }
ChatPharoBenchmarkRunner >> benchmark: aBenchmark [

	benchmark := aBenchmark
]

{ #category : 'private' }
ChatPharoBenchmarkRunner >> buildRawToolForAgent: anAgent system: aSystemPrompt [
	"Construct a `ChatPharoTool` that talks to the same vendor as `anAgent`
	 but with NO tools, NO ChatPharo browser environment, and a neutral
	 system prompt. Used for the rawLLM strategy."

	| toolClass api |
	toolClass := Smalltalk globals at: #ChatPharoTool ifAbsent: [ ^ nil ].
	api := self rawToolVendorFor: anAgent system: aSystemPrompt using: toolClass.
	api ifNil: [ ^ nil ].
	[ api model: anAgent model ] on: Error do: [ "ignore if not settable" ].
	^ api
]

{ #category : 'accessing' }
ChatPharoBenchmarkRunner >> configuration [

	^ configuration
]

{ #category : 'accessing' }
ChatPharoBenchmarkRunner >> configuration: aConfig [

	configuration := aConfig
]

{ #category : 'running' }
ChatPharoBenchmarkRunner >> emptyReport [

	| report descriptor |
	descriptor := self agentDescriptor.
	report := ChatPharoBenchmarkReport new
		          benchmarkName: benchmark name;
		          benchmarkVersion: benchmark version;
		          sourcePackage: benchmark sourcePackage;
		          strategy: configuration strategy;
		          agentClassName: (descriptor at: 'className' ifAbsent: [ nil ]);
		          modelName: (descriptor at: 'model' ifAbsent: [ nil ]);
		          apiBaseURL: (descriptor at: 'baseURL' ifAbsent: [ nil ]);
		          toolsEnabled: configuration strategy = #ecosystem;
		          startedAt: DateAndTime now;
		          yourself.
	report metadata
		at: 'configurationLabel' put: configuration label;
		at: 'passThreshold' put: configuration passThreshold;
		at: 'primaryScorerName' put: configuration primaryScorerName.
	^ report
]

{ #category : 'private' }
ChatPharoBenchmarkRunner >> executeEcosystemCaseFor: aCase [
	"Send `aCase` through the full ChatPharo agent (tools, iterations, …).
	 Return a dictionary with keys:
	   'rawResponse', 'toolCallCount', 'toolCallNames',
	   'promptTokens', 'completionTokens', 'totalTokens'."

	| agent response rawText toolCallCount toolCallNames historyBefore historyAfter newMessages |
	agent := configuration agent copyForChat.
	historyBefore := agent history messages size.
	response := agent getResponseForPrompt: aCase prompt.
	historyAfter := agent history messages size.

	newMessages := (historyAfter > historyBefore)
		               ifTrue: [ agent history messages copyFrom: historyBefore + 1 to: historyAfter ]
		               ifFalse: [ #(  ) ].
	toolCallCount := 0.
	toolCallNames := OrderedCollection new.
	newMessages do: [ :m |
		| tc |
		tc := [ m toolCalls ] on: Error do: [ nil ].
		tc ifNotNil: [
			toolCallCount := toolCallCount + tc size.
			tc do: [ :each |
				| n |
				n := [ each functionName ] on: Error do: [ nil ].
				n ifNotNil: [ toolCallNames add: n asString ] ] ] ].

	rawText := [ response content ] on: Error do: [ response asString ].
	rawText ifNil: [ rawText := '' ].

	^ Dictionary new
		  at: 'rawResponse' put: rawText;
		  at: 'toolCallCount' put: toolCallCount;
		  at: 'toolCallNames' put: toolCallNames asArray;
		  at: 'promptTokens' put: ([ response inputTokens ] on: Error do: [ nil ]);
		  at: 'completionTokens' put: ([ response outputTokens ] on: Error do: [ nil ]);
		  at: 'totalTokens' put: ([ response totalTokens ] on: Error do: [ nil ]);
		  yourself
]

{ #category : 'private' }
ChatPharoBenchmarkRunner >> executeRawCaseFor: aCase [
	"Single-shot call to the vendor API, no ChatPharo tools, neutral system."

	| api historyClass saverClass history response rawText |
	api := self buildRawToolForAgent: configuration agent system: self rawSystemPrompt.
	api ifNil: [ ^ self executeEcosystemCaseFor: aCase ].
	historyClass := Smalltalk globals at: #ChatPharoHistory ifAbsent: [ nil ].
	saverClass := Smalltalk globals at: #ChatPharoHistorySaver ifAbsent: [ nil ].
	(historyClass isNil or: [ saverClass isNil ])
		ifTrue: [ ^ self executeEcosystemCaseFor: aCase ].
	history := historyClass new.
	history addMessage: (saverClass role: 'user' content: aCase prompt).
	response := api getResponseForHistory: history.
	rawText := [ response content ] on: Error do: [ response asString ].
	rawText ifNil: [ rawText := '' ].
	^ Dictionary new
		  at: 'rawResponse' put: rawText;
		  at: 'toolCallCount' put: 0;
		  at: 'toolCallNames' put: #(  );
		  at: 'promptTokens' put: ([ response inputTokens ] on: Error do: [ nil ]);
		  at: 'completionTokens' put: ([ response outputTokens ] on: Error do: [ nil ]);
		  at: 'totalTokens' put: ([ response totalTokens ] on: Error do: [ nil ]);
		  yourself
]

{ #category : 'initialization' }
ChatPharoBenchmarkRunner >> initialize [

	super initialize.
	onCaseStarted := nil.
	onCaseFinished := nil
]

{ #category : 'accessing' }
ChatPharoBenchmarkRunner >> onCaseFinished: aBlock [
	"aBlock value: result"

	onCaseFinished := aBlock
]

{ #category : 'accessing' }
ChatPharoBenchmarkRunner >> onCaseStarted: aBlock [
	"aBlock value: case"

	onCaseStarted := aBlock
]

{ #category : 'private' }
ChatPharoBenchmarkRunner >> rawSystemPrompt [
	"Minimal neutral system prompt — no mention of Pharo tools, no agent
	 persona — so that the rawLLM strategy measures the model itself."

	^ 'You are a helpful assistant. Follow the user instructions exactly and respond with the requested format.'
]

{ #category : 'private' }
ChatPharoBenchmarkRunner >> rawToolVendorFor: anAgent system: aSystemPrompt using: toolClass [
	"Dispatch on the concrete agent class to build a matching `ChatPharoTool`.
	 Falls back to Ollama-style local call if the vendor is unrecognised."

	| agentClass apiKey |
	agentClass := anAgent class name asString.
	apiKey := [ anAgent apiKey ] on: MessageNotUnderstood do: [ nil ].

	(agentClass includesSubstring: 'OpenAI') ifTrue: [
		^ toolClass openAIWithAPIKey: apiKey system: aSystemPrompt tools: #(  ) ].
	(agentClass includesSubstring: 'Claude') ifTrue: [
		^ toolClass claudeWithAPIKey: apiKey system: aSystemPrompt tools: #(  ) ].
	(agentClass includesSubstring: 'DeepSeek') ifTrue: [
		^ toolClass deepSeekWithAPIKey: apiKey system: aSystemPrompt tools: #(  ) ].
	(agentClass includesSubstring: 'Mistral') ifTrue: [
		^ toolClass mistralWithAPIKey: apiKey system: aSystemPrompt tools: #(  ) ].
	(agentClass includesSubstring: 'Gemini') ifTrue: [
		^ toolClass geminiWithAPIKey: apiKey system: aSystemPrompt tools: #(  ) ].
	(agentClass includesSubstring: 'LMStudio') ifTrue: [
		| host port |
		host := [ anAgent host ] on: MessageNotUnderstood do: [ 'localhost' ].
		port := [ anAgent port ] on: MessageNotUnderstood do: [ '1234' ].
		^ toolClass
			  lmStudioWithHost: host asString
			  port: port asString
			  system: aSystemPrompt
			  tools: #(  ) ].
	(agentClass includesSubstring: 'Ollama') ifTrue: [
		^ toolClass ollamaWithSystem: aSystemPrompt tools: #(  ) ].
	"Default: local Ollama-style endpoint."
	self error:
		'Unsupported rawLLM agent class: ' , agentClass
			, '. Use a vendor-backed agent (OpenAI/Claude/DeepSeek/Mistral/Gemini/LMStudio/Ollama).'
]

{ #category : 'running' }
ChatPharoBenchmarkRunner >> run [
	"Execute every case in the benchmark and return a report."

	| report |
	benchmark ifNil: [ ^ self error: 'benchmark is required' ].
	configuration ifNil: [ ^ self error: 'configuration is required' ].
	report := self emptyReport.
	configuration maxConcurrency <= 1
		ifTrue: [ self runSerial: report ]
		ifFalse: [ self runParallel: report ].
	report finishedAt: DateAndTime now.
	^ report
]

{ #category : 'private' }
ChatPharoBenchmarkRunner >> runCase: aCase [
	"Execute one case under the configured strategy and score the output.
	 Always returns a `ChatPharoBenchmarkResult`; on errors the result has
	 `passed = false` and `errorMessage` set."

	| result startedAt finishedAt execution code primary primaryScore descriptor |
	descriptor := self agentDescriptor.
	result := ChatPharoBenchmarkResult new
		          caseId: aCase id;
		          caseDescription: aCase printString;
		          strategy: configuration strategy;
		          agentClassName: (descriptor at: 'className' ifAbsent: [ nil ]);
		          modelName: (descriptor at: 'model' ifAbsent: [ nil ]);
		          apiBaseURL: (descriptor at: 'baseURL' ifAbsent: [ nil ]);
		          toolsEnabled: configuration strategy = #ecosystem;
		          yourself.
	onCaseStarted ifNotNil: [ onCaseStarted cull: aCase ].

	startedAt := DateAndTime now.
	result startedAt: startedAt.
	execution := [
		            self
			             value: [
					             configuration strategy = #ecosystem
						             ifTrue: [ self executeEcosystemCaseFor: aCase ]
						             ifFalse: [ self executeRawCaseFor: aCase ] ]
			             withTimeoutSeconds: configuration timeoutSeconds ]
		             on: Error
		             do: [ :e |
			             result errorMessage: e messageText.
			             nil ].
	finishedAt := DateAndTime now.
	result finishedAt: finishedAt.
	result latencyMs: (finishedAt - startedAt) asMilliSeconds.

	execution ifNotNil: [
		result
			rawResponse: (execution at: 'rawResponse' ifAbsent: [ '' ]);
			toolCallCount: (execution at: 'toolCallCount' ifAbsent: [ 0 ]);
			toolCallNames: (execution at: 'toolCallNames' ifAbsent: [ #(  ) ]);
			promptTokens: (execution at: 'promptTokens' ifAbsent: [ nil ]);
			completionTokens: (execution at: 'completionTokens' ifAbsent: [ nil ]);
			totalTokens: (execution at: 'totalTokens' ifAbsent: [ nil ]).
		code := ChatPharoBenchmarkCodeExtractor extractFrom: result rawResponse.
		result extractedCode: code.
		configuration scorers do: [ :scorer |
			| value |
			value := [ scorer score: code against: aCase ]
				         on: Error
				         do: [ :e | 0.0 ].
			result scores at: scorer scoreName put: value asFloat ].
		primary := configuration primaryScorerName.
		primaryScore := result scores at: primary ifAbsent: [ 0.0 ].
		result passed: primaryScore >= configuration passThreshold ].

	onCaseFinished ifNotNil: [ onCaseFinished cull: result ].
	^ result
]

{ #category : 'private' }
ChatPharoBenchmarkRunner >> runParallel: aReport [

	| semaphore running results |
	results := Array new: benchmark cases size.
	semaphore := Semaphore new.
	running := 0.
	benchmark cases withIndexDo: [ :aCase :index |
		[ running >= configuration maxConcurrency ] whileTrue: [
			semaphore wait.
			running := running - 1 ].
		running := running + 1.
		[
			| r |
			[
				r := self runCase: aCase.
				results at: index put: r ]
				ensure: [ semaphore signal ]
		] fork ].
	[ running > 0 ] whileTrue: [
		semaphore wait.
		running := running - 1 ].
	results do: [ :r | r ifNotNil: [ aReport addResult: r ] ]
]

{ #category : 'private' }
ChatPharoBenchmarkRunner >> value: aBlock withTimeoutSeconds: timeoutSeconds [

	| completed worker result error seconds timeoutMs |
	seconds := (timeoutSeconds ifNil: [ 120 ]) asNumber max: 1.
	timeoutMs := (seconds * 1000) asInteger.
	completed := Semaphore new.
	worker := [
	          [ result := aBlock value ]
		          on: Error
		          do: [ :e | error := e ]
		          ensure: [ completed signal ] ] fork.
	(completed waitTimeoutMilliseconds: timeoutMs) ifTrue: [
		worker terminate.
		Error signal: 'Case execution timed out after ' , seconds asString , ' seconds' ].
	error ifNotNil: [ Error signal: error messageText ].
	^ result
]

{ #category : 'private' }
ChatPharoBenchmarkRunner >> runSerial: aReport [

	benchmark cases do: [ :aCase |
		aReport addResult: (self runCase: aCase) ]
]
