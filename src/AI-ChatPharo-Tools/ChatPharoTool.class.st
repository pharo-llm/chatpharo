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
ChatPharoTool class >> groqWithAPIKey: apiKey system: system [

	^ self groqWithAPIKey: apiKey system: system tools: nil
]

{ #category : 'instance creation' }
ChatPharoTool class >> groqWithAPIKey: apiKey system: system tools: tools [

	^ self
		  baseURL: (ZnUrl fromString: 'https://api.groq.com/openai/v1')
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

{ #category : 'instance creation' }
ChatPharoTool class >> openRouterWithAPIKey: apiKey system: system [

	^ self openRouterWithAPIKey: apiKey system: system tools: nil
]

{ #category : 'instance creation' }
ChatPharoTool class >> openRouterWithAPIKey: apiKey system: system tools: tools [

	^ self
		  baseURL: (ZnUrl fromString: 'https://openrouter.ai/api/v1')
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
	"Run the tool the model asked for and answer its result.

	 The tool is looked up first so that it can say whether it changes the image;
	 the central confirmation gate (ChatPharoToolConfirmation) then asks the user.
	 A denial is answered as a cancellation dictionary that goes back to the model
	 verbatim, so the LLM sees the rejection, and its reason, and can adapt its plan."

	| tool |
	onToolExecution ifNotNil: [ :blk | blk cull: functionName ].
	tool := self toolNamed: functionName.
	ChatPharoToolConfirmation default
		guardToolNamed: functionName
		arguments: arguments
		mutating: (tool notNil and: [ tool isMutating ])
		ifDeniedDo: [ :cancellation | ^ cancellation ].
	tool ifNil: [ ^ Dictionary with: 'error' -> ('There is no function named "{1}"' format: { functionName }) ].
	^ [ tool applyTo: arguments ]
		  on: Error
		  do: [ :e | Dictionary with: 'error' -> e messageText ]
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

{ #category : 'private' }
ChatPharoTool >> chatMessagesFor: history [

	^ Array streamContents: [ :stream |
		  systemPrompt ifNotNil: [ stream nextPut: (Dictionary with: 'role' -> 'system' with: 'content' -> systemPrompt) ].
		  history putOpenAIChatMessagesOn: stream ]
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

{ #category : 'private' }
ChatPharoTool >> completionMessageIn: responseJson [

	| choices |
	choices := responseJson at: 'choices' ifAbsent: [ #(  ) ].
	choices ifEmpty: [ ChatPharoBackendError new signal: 'The backend answered without any completion choice.' ].
	^ choices first at: 'message'
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
ChatPharoTool >> friendlyErrorMessageFor: response [

	| status contents errorMessage |
	status := response status.
	contents := response contents ifNil: [ '' ].

	errorMessage := [ | json |
		json := STONJSON fromString: contents.
		(json at: 'error' ifAbsent: [ nil ])
			ifNotNil: [ :err | err at: 'message' ifAbsent: [ nil ] ]
			ifNil: [ nil ] ]
		on: Error do: [ :ex | nil ].

	status = 402 ifTrue: [
		^ 'Insufficient balance on your API account. Please add credits at your provider''s billing page.' ].
	status = 401 ifTrue: [
		^ 'Invalid or expired API key. Please check your API key in Settings.' ].
	status = 429 ifTrue: [
		^ 'Rate limit exceeded. Please wait a moment and try again.' ].
	status = 404 ifTrue: [
		^ 'Model not found. Please check your model selection in Settings.' ].
	status = 503 ifTrue: [
		^ 'The API service is temporarily unavailable. Please try again later.' ].
	^ 'Could not get chat completion: ' , status asString , ' - ' , (errorMessage ifNil: [ contents ifEmpty: [ 'no details' ] ])
]

{ #category : 'initialization' }
ChatPharoTool >> getClosingResponseForHistory: history [
	"Ask for a final written answer: tools stay declared, because the history refers to them,
	 but the model may not call them, and any call it still emits is not executed."

	| payload responseJson |
	payload := self buildPayloadFor: (self chatMessagesFor: history).
	(payload includesKey: 'tools') ifTrue: [ payload at: 'tool_choice' put: 'none' ].
	responseJson := self postCompletion: payload.
	^ self
		  historyEntryForMessage: (self completionMessageIn: responseJson)
		  toolCalls: nil
		  usage: (responseJson at: 'usage' ifAbsent: [ nil ])
]

{ #category : 'initialization' }
ChatPharoTool >> getResponseForHistory: history [

	| responseJson message |
	responseJson := self postCompletion: (self buildPayloadFor: (self chatMessagesFor: history)).
	message := self withRecoveredToolCalls: (self completionMessageIn: responseJson).
	^ self
		  historyEntryForMessage: message
		  toolCalls: (self toolCallsFromMessage: message)
		  usage: (responseJson at: 'usage' ifAbsent: [ nil ])
]

{ #category : 'private' }
ChatPharoTool >> historyEntryForMessage: message toolCalls: toolCalls usage: usage [

	| extraction counts |
	extraction := ChatPharoReasoningExtraction fromMessage: message.
	counts := usage ifNil: [ Dictionary new ].
	^ (ChatPharoHistorySaver role: 'assistant' content: extraction content toolCalls: toolCalls)
		  thinking: (self thinkingTextForReasoning: extraction reasoning toolCalls: toolCalls);
		  inputTokens: (counts at: 'prompt_tokens' ifAbsent: [ nil ]);
		  outputTokens: (counts at: 'completion_tokens' ifAbsent: [ nil ]);
		  totalTokens: (counts at: 'total_tokens' ifAbsent: [ nil ]);
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
	model := nil.
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
	"Without an explicit model, the first one the backend lists is used.
	 It is resolved on demand so that building a client never costs a network round trip."

	^ model ifNil: [ model := self safeDefaultModelName ]
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

{ #category : 'private' }
ChatPharoTool >> offeredToolNames [

	^ (tools ifNil: [ #(  ) ]) collect: [ :each | each name ]
]

{ #category : 'accessing' }
ChatPharoTool >> onToolExecution [ 

        ^ onToolExecution
]

{ #category : 'accessing' }
ChatPharoTool >> onToolExecution: aBlock [ 

        onToolExecution := aBlock
]

{ #category : 'private' }
ChatPharoTool >> postCompletion: payload [

	| httpClient startedAt response |
	payload removeKey: 'chatpharo_ethics' ifAbsent: [  ].
	httpClient := self cachedClient.
	startedAt := DateAndTime now.
	response := [
		            httpClient
			            resetEntity;
			            entity: (ZnEntity json: (self jsonStringFor: (self normalizeForJson: payload)));
			            timeout: self requestTimeoutSeconds;
			            post;
			            response ] ensure: [ self recordRequestDurationSince: startedAt ].
	response isSuccess ifFalse: [
		(ChatPharoBackendError status: response status message: (self friendlyErrorMessageFor: response)) signal ].
	^ STONJSON fromString: response contents
]

{ #category : 'private' }
ChatPharoTool >> recordRequestDurationSince: startedAt [

	ChatPharoSettings default ethicsDirector ifNotNil: [ :director |
		director lastRequestDurationSeconds: (DateAndTime now - startedAt) asSeconds ]
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
ChatPharoTool >> thinkingTextForReasoning: reasoning toolCalls: toolCalls [
	"What the thinking panel shows for one model reply: its reasoning, then the tools it ran."

	| parts |
	parts := OrderedCollection new.
	reasoning ifNotNil: [ parts add: reasoning ].
	toolCalls isEmptyOrNil ifFalse: [ parts add: (self toolTraceFor: toolCalls) ].
	parts ifEmpty: [ ^ nil ].
	^ (String cr , String cr) join: parts
]

{ #category : 'private' }
ChatPharoTool >> toolCallsFromMessage: message [
	"Parse the tool calls of the message and execute them in the order the model listed them.
	 Order matters: a model routinely creates a class and adds methods to it in a single reply."

	| calls |
	calls := message at: 'tool_calls' ifAbsent: [ nil ].
	calls isEmptyOrNil ifTrue: [ ^ nil ].
	^ self toolCallsFromMessageSequential: calls
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
ChatPharoTool >> toolNamed: aName [
	"The declared tool with that name, else the temporal tool the model created, else nil."

	^ self toolIndex at: aName ifAbsent: [ ChatPharoTemporalToolRegistry current toolNamed: aName ]
]

{ #category : 'private' }
ChatPharoTool >> toolTraceFor: toolCalls [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Tool calls made:';
			  cr;
			  cr.
		  toolCalls do: [ :each | each printTraceOn: stream ] ]
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

{ #category : 'private' }
ChatPharoTool >> withRecoveredToolCalls: message [
	"Small local models often write a tool call as JSON text. Answer the message with that text
	 turned into a proper tool call, or the message itself when it is an ordinary answer."

	| calls |
	(message at: 'tool_calls' ifAbsent: [ nil ]) isEmptyOrNil ifFalse: [ ^ message ].
	calls := (ChatPharoTextualToolCallParser knownToolNames: self offeredToolNames) callsIn:
		         (message at: 'content' ifAbsent: [ nil ]).
	calls ifEmpty: [ ^ message ].
	^ message copy
		  at: 'tool_calls' put: calls;
		  at: 'content' put: nil;
		  yourself
]
