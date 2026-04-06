"
A **general OpenAI-style REST client**.

* Configured through a family of factory methods (`geminiWithAPIKey:`, `ollamaWithSystem:` …) which set `baseURL`, `apiKey`, default `model`, etc.
* Accepts a list of **tools** (see `ChatPharoClient`) so that function-calling requests can be routed automatically.
* Central routine `getResponseForHistory:` posts *one composite JSON* (`model`, `messages`, optional `tools/tool_choice`) to `/chat/completions`, then converts the reply back into `ChatPharoHistorySaver` plus `ChatPharoHistorySaverToolCall` objects.
* **Why** – unifies all “talk to an LLM” code in one tested component, eliminating duplication in the agent subclasses.


```smalltalk
(ChatPharoBrowserEnvironment new functionGetClassesInPackages
    applyTo: (Dictionary with: 'packages' -> #('AI-ChatPharo-Agent')))
```
"
Class {
	#name : 'ChatPharoTool',
	#superclass : 'Object',
	#instVars : [
		'baseURL',
		'apiKey',
		'model',
		'tools',
		'toolIndex',
		'systemPrompt',
		'onToolExecution',
		'extraParameters',
		'extraHeaders',
		'cachedClient',
		'cachedToolSchemas',
		'lastTemporalToolCount'
	],
	#category : 'AI-ChatPharo-Tools-Core',
	#package : 'AI-ChatPharo-Tools',
	#tag : 'Core'
}

{ #category : 'instance creation' }
ChatPharoTool class >> baseURL: baseURL apiKey: apiKey system: system [

	^ self
		  baseURL: baseURL
		  apiKey: apiKey
		  system: system
		  tools: nil
]

{ #category : 'instance creation' }
ChatPharoTool class >> baseURL: baseURL apiKey: apiKey system: system tools: tools [

	^ self basicNew
		  initializeWithBaseURL: baseURL
		  apiKey: apiKey
		  system: system
		  tools: tools;
		  yourself
]

{ #category : 'instance creation' }
ChatPharoTool class >> baseURL: baseURL system: system [

	^ self baseURL: baseURL system: system tools: nil
]

{ #category : 'instance creation' }
ChatPharoTool class >> baseURL: baseURL system: system tools: tools [

	^ self
		  baseURL: baseURL
		  apiKey: nil
		  system: system
		  tools: tools
]

{ #category : 'instance creation' }
ChatPharoTool class >> claudeWithAPIKey: apiKey system: system [

	^ self claudeWithAPIKey: apiKey system: system tools: nil
]

{ #category : 'instance creation' }
ChatPharoTool class >> claudeWithAPIKey: apiKey system: system tools: tools [

| tool |
	tool := self basicNew.
	tool extraHeaders: (Dictionary new
		at: 'x-api-key' put: apiKey;
		at: 'anthropic-version' put: '2023-06-01';
		yourself).
	tool
		initializeWithBaseURL: (ZnUrl fromString: 'https://api.anthropic.com/v1')
		apiKey: apiKey
		system: system
		tools: tools.
	^ tool
]

{ #category : 'instance creation' }
ChatPharoTool class >> deepSeekWithAPIKey: apiKey system: system [

	^ self deepSeekWithAPIKey: apiKey system: system tools: nil
]

{ #category : 'instance creation' }
ChatPharoTool class >> deepSeekWithAPIKey: apiKey system: system tools: tools [

	^ self
		baseURL: (ZnUrl fromString: 'https://api.deepseek.com/v1')
		apiKey: apiKey
		system: system
		tools: tools
]

{ #category : 'instance creation' }
ChatPharoTool class >> geminiWithAPIKey: apiKey system: system [

	^ self geminiWithAPIKey: apiKey system: system tools: nil
]

{ #category : 'instance creation' }
ChatPharoTool class >> geminiWithAPIKey: apiKey system: system tools: tools [

	^ self
		  baseURL: (ZnUrl fromString:
				   'https://generativelanguage.googleapis.com/v1beta/openai')
		  apiKey: apiKey
		  system: system
		  tools: tools
]

{ #category : 'instance creation' }
ChatPharoTool class >> lmStudioWithHost: host port: port system: system tools: tools [

	| url |
	url := 'http://' , host , ':' , port , '/v1'.
	^ self baseURL: (ZnUrl fromString: url) system: system tools: tools
]

{ #category : 'instance creation' }
ChatPharoTool class >> mistralWithAPIKey: apiKey system: system [ 


        ^ self mistralWithAPIKey: apiKey system: system tools: nil
]

{ #category : 'instance creation' }
ChatPharoTool class >> mistralWithAPIKey: apiKey system: system tools: tools [ 


        ^ self
                  baseURL: (ZnUrl fromString: 'https://api.mistral.ai/v1')
                  apiKey: apiKey
                  system: system
                  tools: tools
]

{ #category : 'instance creation' }
ChatPharoTool class >> new [

	^ self ollamaWithSystem: nil
]

{ #category : 'instance creation' }
ChatPharoTool class >> ollamaWithSystem: system [ 

	^ self ollamaWithSystem: system tools: nil
]

{ #category : 'instance creation' }
ChatPharoTool class >> ollamaWithSystem: system tools: tools [ 

	^ self baseURL: (ZnUrl fromString: 'http://localhost:11434/v1') system: system tools: tools
]

{ #category : 'instance creation' }
ChatPharoTool class >> openAIWithAPIKey: apiKey system: system [

	^ self openAIWithAPIKey: apiKey system: system tools: #(  )
]

{ #category : 'instance creation' }
ChatPharoTool class >> openAIWithAPIKey: apiKey system: system tools: tools [

	^ self
		  baseURL: (ZnUrl fromString: 'https://api.openai.com/v1')
		  apiKey: apiKey
		  system: system
		  tools: tools
]

{ #category : 'accessing' }
ChatPharoTool >> apiKey [

	^ apiKey
]

{ #category : 'accessing' }
ChatPharoTool >> apiKey: anObject [

	apiKey := anObject.
	self resetCachedClient
]

{ #category : 'initialization' }
ChatPharoTool >> applyToolFunction: functionName arguments: arguments [

"Look up the tool by name using the dictionary index (O(1) instead of linear scan),
	 then fall back to the temporal tool registry."

	| tool temporalTool |
	onToolExecution ifNotNil: [ :blk | blk cull: functionName ].

	"Try indexed tool lookup first"
	tool := self toolIndex at: functionName ifAbsent: [ nil ].
	tool ifNotNil: [
		^ [ tool applyTo: arguments ]
			on: Error
			do: [ :e | Dictionary with: 'error' -> e messageText ] ].

	"Fall back to temporal tool registry"
	temporalTool := ChatPharoTemporalToolRegistry current toolNamed: functionName.
	temporalTool ifNotNil: [
		^ [ temporalTool applyTo: arguments ]
			on: Error
			do: [ :e | Dictionary with: 'error' -> e messageText ] ].

	^ Dictionary with: 'error' -> ('There is no function named "{1}"' format: { functionName })
]

{ #category : 'accessing' }
ChatPharoTool >> baseURL [

	^ baseURL
]

{ #category : 'accessing' }
ChatPharoTool >> baseURL: anObject [

	baseURL := anObject.
	self resetCachedClient
]

{ #category : 'initialization' }
ChatPharoTool >> buildPayloadFor: messages [

	| data toolSchemas ethicsPayload director tokenBudgetValue |
	data := Dictionary new: 8.
	data at: 'model' put: model.
	data at: 'messages' put: messages.
	extraParameters ifNotNil: [ data addAll: extraParameters ].
	toolSchemas := self resolvedToolSchemas.
	toolSchemas ifNotEmpty: [
		data at: 'tools' put: toolSchemas.
		data at: 'tool_choice' put: 'auto' ].
	director := ChatPharoSettings default ethicsDirector.
	director ifNotNil: [
		ethicsPayload := Dictionary new.
		ethicsPayload at: 'enabled' put: director enabled.
		ethicsPayload at: 'mandate' put: director mandate.
		ethicsPayload at: 'cognitive_load_budget' put: director cognitiveLoadBudget.
		ethicsPayload at: 'token_budget' put: director tokenBudget.
		ethicsPayload at: 'time_budget_minutes' put: director timeBudgetMinutes.
		ethicsPayload at: 'message_limit' put: director messageLimit.
		ethicsPayload at: 'request_timeout_seconds' put: director requestTimeoutSeconds.
		ethicsPayload at: 'last_request_duration_seconds' put: director lastRequestDurationSeconds.
		data at: 'chatpharo_ethics' put: ethicsPayload.
		tokenBudgetValue := director tokenBudget.
		(tokenBudgetValue notNil and: [ (data includesKey: 'max_tokens') not ]) ifTrue: [
			data at: 'max_tokens' put: tokenBudgetValue ] ].
	^ data
]

{ #category : 'initialization' }
ChatPharoTool >> cachedClient [

	^ cachedClient ifNil: [
		| client |
		client := ZnClient new
			url: baseURL;
			addPath: #( 'chat' 'completions' );
			yourself.
		extraHeaders ifNotNil: [
			extraHeaders keysAndValuesDo: [ :key :value |
				client headerAt: key put: value ] ]
		ifNil: [
			apiKey ifNotNil: [ client setBearerAuthentication: apiKey ] ].
		cachedClient := client ]
]

{ #category : 'initialization' }
ChatPharoTool >> client [

	| client |
	client := ZnClient new
		url: baseURL;
		yourself.
	extraHeaders ifNotNil: [
		extraHeaders keysAndValuesDo: [ :key :value |
			client headerAt: key put: value ] ]
	ifNil: [
		apiKey ifNotNil: [ client setBearerAuthentication: apiKey ] ].
	^ client
]

{ #category : 'accessing' }
ChatPharoTool >> extraHeaders [

	^ extraHeaders
]

{ #category : 'accessing' }
ChatPharoTool >> extraHeaders: aDictionary [

	extraHeaders := aDictionary.
	self resetCachedClient
]

{ #category : 'initialization' }
ChatPharoTool >> getResponseForHistory: history [
	| messages data response message toolCalls thinkingText httpClient startedAt elapsedSeconds director |
	messages := Array streamContents: [ :stream |
			            systemPrompt ifNotNil: [ stream nextPut: (Dictionary with: 'role' -> 'system' with: 'content' -> systemPrompt) ].
			            history putOpenAIChatMessagesOn: stream ].
	data := self buildPayloadFor: messages.
	httpClient := self cachedClient.
	startedAt := DateAndTime now.
	response := [
		            httpClient
			            resetEntity;
			            entity: (ZnEntity json: (self jsonStringFor: (self normalizeForJson: data)));
			            timeout: self requestTimeoutSeconds;
			            post;
			            response ] ensure: [
			            elapsedSeconds := (DateAndTime now - startedAt) asSeconds.
			            director := ChatPharoSettings default ethicsDirector.
			            director ifNotNil: [ director lastRequestDurationSeconds: elapsedSeconds ] ].
	response := httpClient
		            resetEntity;
		            entity: (ZnEntity json: (self jsonStringFor: (self normalizeForJson: data)));
		            timeout: self requestTimeoutSeconds;
		            post;
		            response.
	response isSuccess ifFalse: [ Error signal: 'Could not get chat completion' ].
	message := ((STONJSON fromString: response contents) at: 'choices') first at: 'message'.
	toolCalls := self toolCallsFromMessage: message.
	thinkingText := nil.
	toolCalls ifNotNil: [
			toolCalls ifNotEmpty: [
					thinkingText := String streamContents: [ :stream |
							                stream
								                nextPutAll: 'Tool calls made:';
								                cr;
								                cr.
							                toolCalls do: [ :tc |
									                stream
										                nextPutAll: 'Function: ';
										                nextPutAll: tc functionName;
										                cr.
									                stream
										                nextPutAll: 'Arguments: ';
										                nextPutAll: tc arguments asString;
										                cr.
									                tc content ifNotNil: [ :content |
											                stream
												                nextPutAll: 'Result: ';
												                nextPutAll: (content copyFrom: 1 to: (content size min: 200));
												                nextPutAll: '...';
												                cr ].
									                stream cr ] ] ] ].

	^ (ChatPharoHistorySaver role: 'assistant' content: (message at: 'content' ifAbsent: [ nil ]) toolCalls: toolCalls)
		  thinking: thinkingText;
		  yourself
]

{ #category : 'initialization' }
ChatPharoTool >> initializeWithBaseURL: initialBaseURL apiKey: initialAPIKey system: initialSystem tools: initialTools [

	super initialize.
	baseURL := initialBaseURL.
	apiKey := initialAPIKey.
	systemPrompt := initialSystem.
	tools := initialTools.
	toolIndex := nil.
	onToolExecution := nil.
	extraParameters := Dictionary new.
	self model: self safeDefaultModelName.
	cachedClient := nil.
	cachedToolSchemas := nil.
	lastTemporalToolCount := nil
]

{ #category : 'accessing' }
ChatPharoTool >> jsonStringFor: anObject [
	"Serialize JSON while ignoring shared reference warnings."

	^ STONJSON toString: anObject
]

{ #category : 'accessing' }
ChatPharoTool >> model [

	^ model
]

{ #category : 'accessing' }
ChatPharoTool >> model: anObject [

	model := anObject
]

{ #category : 'initialization' }
ChatPharoTool >> modelNames [ 

	| response |
	response := self client addPathSegment:'models'; get; response.
	response isSuccess ifFalse:[ Error signal:'Could not retrieve models' ].
	^ ((STONJSON fromString: response contents) at:'data') collect:[:m| m at:'id' ]
]

{ #category : 'accessing' }
ChatPharoTool >> normalizeForJson: anObject [

	anObject isNil ifTrue: [ ^ nil ].
	anObject isNumber ifTrue: [ ^ anObject ].
	(anObject isKindOf: Boolean) ifTrue: [ ^ anObject ].
	anObject isSymbol ifTrue: [ ^ anObject asString ].
	anObject isString ifTrue: [ ^ anObject ].
	(anObject isString or: [ anObject isSymbol ]) ifTrue: [ ^ anObject asString copy ].
	(anObject isNumber or: [ anObject isKindOf: Boolean ]) ifTrue: [ ^ anObject ].
	anObject isDictionary ifTrue: [
			| dict |
			dict := Dictionary new: anObject size.
			anObject keysAndValuesDo: [ :key :value |
					dict
						at: (key isSymbol
								 ifTrue: [ key asString ]
								 ifFalse: [ key ])
						put: (self normalizeForJson: value) ].
			^ dict ].
	anObject isCollection ifTrue: [ ^ (anObject collect: [ :each | self normalizeForJson: each ]) as: Array ].
	^ anObject asString
]

{ #category : 'accessing' }
ChatPharoTool >> onToolExecution [ 

        ^ onToolExecution
]

{ #category : 'accessing' }
ChatPharoTool >> onToolExecution: aBlock [ 

        onToolExecution := aBlock
]

{ #category : 'initialization' }
ChatPharoTool >> requestParameters [

	^ extraParameters ifNil: [ extraParameters := Dictionary new ]
]

{ #category : 'initialization' }
ChatPharoTool >> requestParameters: aDictionary [

	extraParameters := aDictionary ifNil: [ Dictionary new ]
]

{ #category : 'initialization' }
ChatPharoTool >> requestTimeoutSeconds [

	^ ChatPharoSettings default requestTimeoutSeconds
]

{ #category : 'initialization' }
ChatPharoTool >> resetCachedClient [


	cachedClient ifNotNil: [ :c | [ c close ] on: Error do: [ "ignore" ] ].
	cachedClient := nil
]

{ #category : 'initialization' }
ChatPharoTool >> resolvedToolSchemas [
	| currentTemporalCount |
	currentTemporalCount := ChatPharoTemporalToolRegistry current size.
	(cachedToolSchemas notNil and: [ lastTemporalToolCount = currentTemporalCount ]) ifTrue: [ ^ cachedToolSchemas ].
	lastTemporalToolCount := currentTemporalCount.
	cachedToolSchemas := Array streamContents: [ :stream |
			                     tools ifNotNil: [ tools do: [ :t | stream nextPut: t openAIChatTool ] ].
			                     ChatPharoTemporalToolRegistry current tools do: [ :t | stream nextPut: t openAIChatTool ] ].
	^ cachedToolSchemas
]

{ #category : 'initialization' }
ChatPharoTool >> safeDefaultModelName [
	"Pick a default model while allowing offline initialization."

	| availableModels |
	availableModels := [
		self modelNames ]
			on: Error
			do: [ #() ].
	availableModels ifEmpty: [ ^ '' ].
	^ availableModels first
]

{ #category : 'accessing' }
ChatPharoTool >> systemPrompt [

	^ systemPrompt
]

{ #category : 'accessing' }
ChatPharoTool >> systemPrompt: aString [

	^ systemPrompt := aString 
]

{ #category : 'private' }
ChatPharoTool >> toolCallsFromMessage: message [
	"Parse tool calls from the message and execute them.
	 When multiple tool calls are present, they are executed in parallel
	 using forked processes with a shared semaphore for synchronization."

	| calls |
	calls := message at: 'tool_calls' ifAbsent: [ nil ].
	calls isNil ifTrue: [ ^ nil ].

	"For a single tool call, execute directly without parallelism overhead"
	calls size = 1 ifTrue: [ ^ self toolCallsFromMessageSequential: calls ].

	"For multiple tool calls, execute in parallel"
	^ self toolCallsFromMessageParallel: calls
]

{ #category : 'private' }
ChatPharoTool >> toolCallsFromMessageParallel: calls [
	"Execute multiple tool calls in parallel using forked processes.
	 Results are collected via a shared array and synchronized with a semaphore."

	| results semaphore |
	results := Array new: calls size.
	semaphore := Semaphore new.

	calls withIndexCollect: [ :c :index |
		| fn rawArgs parsedArgs callId |
		fn := (c at: 'function') at: 'name'.
		rawArgs := (c at: 'function') at: 'arguments' ifAbsent: [ '{}' ].
		parsedArgs := (rawArgs isString
			ifTrue: [
				[ STONJSON fromString: rawArgs ]
					on: Error do: [ Dictionary with: 'error' -> 'Invalid arguments' ] ]
			ifFalse: [ rawArgs ifNil: [ Dictionary new ] ]).
		callId := c at: 'id' ifAbsent: [ 'tool-' , DateAndTime now asString ].

		"Fork the tool execution"
		[
			| content |
			[ content := self jsonStringFor:
				(self normalizeForJson: (self applyToolFunction: fn arguments: parsedArgs)) ]
				on: Error
				do: [ :e | content := self jsonStringFor: (Dictionary with: 'error' -> e messageText) ].
			results at: index put: (ChatPharoHistorySaverToolCall
				id: callId
				functionName: fn
				arguments: (rawArgs isString ifTrue: [ rawArgs ] ifFalse: [ STONJSON toString: parsedArgs ])
				content: content).
			semaphore signal
		] fork ].

	"Wait for all tool calls to complete"
	calls size timesRepeat: [ semaphore wait ].
	^ results
]

{ #category : 'private' }
ChatPharoTool >> toolCallsFromMessageSequential: calls [
	"Execute tool calls sequentially (used when there is only one call)."

	^ calls collect: [ :c |
		| fn rawArgs parsedArgs content callId |
		fn := (c at: 'function') at: 'name'.
		rawArgs := (c at: 'function') at: 'arguments' ifAbsent: [ '{}' ].
		parsedArgs := (rawArgs isString
			ifTrue: [
				[ STONJSON fromString: rawArgs ]
					on: Error do: [ Dictionary with: 'error' -> 'Invalid arguments' ] ]
			ifFalse: [ rawArgs ifNil: [ Dictionary new ] ]).

		content := self jsonStringFor:
			(self normalizeForJson: (self applyToolFunction: fn arguments: parsedArgs)).

		callId := c at: 'id' ifAbsent: [ 'tool-' , DateAndTime now asString ].

		ChatPharoHistorySaverToolCall
			id: callId
			functionName: fn
			arguments: (rawArgs isString ifTrue: [ rawArgs ] ifFalse: [ STONJSON toString: parsedArgs ])
			content: content
	]
]

{ #category : 'initialization' }
ChatPharoTool >> toolIndex [
	"Returns a Dictionary mapping tool name -> tool for O(1) lookup.
	 Lazily built and invalidated when tools change."

	^ toolIndex ifNil: [
		toolIndex := Dictionary new.
		tools ifNotNil: [
			tools do: [ :tool | toolIndex at: tool name put: tool ] ].
		toolIndex ]
]

{ #category : 'accessing' }
ChatPharoTool >> tools [

	^ tools
]

{ #category : 'accessing' }
ChatPharoTool >> tools: anObject [

	tools := anObject.
	toolIndex := nil.
	cachedToolSchemas := nil
]
