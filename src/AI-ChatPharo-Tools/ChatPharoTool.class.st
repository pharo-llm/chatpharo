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
		'systemPrompt',
		'onToolExecution',
		'extraParameters',
		'extraHeaders'
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

{ #category : 'accessing' }
ChatPharoTool >> apiKey [

	^ apiKey
]

{ #category : 'accessing' }
ChatPharoTool >> apiKey: anObject [

	apiKey := anObject
]

{ #category : 'initialization' }
ChatPharoTool >> applyToolFunction: functionName arguments: arguments [

	| temporalTool |
	onToolExecution ifNotNil: [ :blk | blk cull: functionName ].
	tools ifNil: [ "Check temporal tools before giving up"
			temporalTool := ChatPharoTemporalToolRegistry current toolNamed: functionName.
			temporalTool ifNotNil: [
					^ [ temporalTool applyTo: arguments ]
						  on: Error
						  do: [ :e | Dictionary with: 'error' -> e messageText ] ].
			^ Dictionary with: 'error' -> ('There is no function named "{1}"' format: { functionName }) ].
	tools do: [ :tool |
			tool name = functionName ifTrue: [
					^ [ tool applyTo: arguments ]
						  on: Error
						  do: [ :e | Dictionary with: 'error' -> e messageText ] ] ]. "Fall back to temporal tool registry"
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

	baseURL := anObject
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

	extraHeaders := aDictionary
]

{ #category : 'initialization' }
ChatPharoTool >> getResponseForHistory: history [

	| messages data response message toolCalls thinkingText allTools |
	messages := Array streamContents: [ :stream |
			            systemPrompt ifNotNil: [ stream nextPut: (Dictionary with: 'role' -> 'system' with: 'content' -> systemPrompt) ].
			            history putOpenAIChatMessagesOn: stream ].
	data := Dictionary with: 'model' -> model with: 'messages' -> messages.
	extraParameters ifNotNil: [ data addAll: extraParameters ]. "Merge static tools with any temporal tools the model has created"
	allTools := tools ifNil: [ OrderedCollection new ] ifNotNil: [ tools asOrderedCollection copy ].
	allTools addAll: ChatPharoTemporalToolRegistry current tools.
	allTools ifNotEmpty: [
			data
				add: 'tools' -> (allTools collect: [ :t | t openAIChatTool ] as: Array);
				add: 'tool_choice' -> 'auto' ].
	response := self client
		            addPath: #( 'chat' 'completions' );
		            entity: (ZnEntity json: (self jsonStringFor: (self normalizeForJson: data)));
		            timeout: self requestTimeoutSeconds;
		            post;
		            response.
	response isSuccess ifFalse: [ Error signal: 'Could not get chat completion' ].
	message := ((STONJSON fromString: response contents) at: 'choices') first at: 'message'. "Extract tool calls"
	toolCalls := self toolCallsFromMessage: message. "Build thinking text from tool calls"
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
	onToolExecution := nil.
	extraParameters := Dictionary new.
	self model: self modelNames first
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
	"Create a JSON-safe copy of anObject without shared references."

	anObject isNil ifTrue: [ ^ nil ].
	(anObject isString or: [ anObject isSymbol ]) ifTrue: [ ^ anObject asString copy ].
	(anObject isNumber or: [ anObject isKindOf: Boolean ]) ifTrue: [ ^ anObject ].
	(anObject isDictionary) ifTrue: [
		| dict |
		dict := Dictionary new.
		anObject keysAndValuesDo: [ :key :value |
			dict at: key asString copy put: (self normalizeForJson: value) ].
		^ dict ].
	(anObject isCollection) ifTrue: [
		^ (anObject collect: [ :each | self normalizeForJson: each ]) as: Array ].
	^ anObject asString copy
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

{ #category : 'accessing' }
ChatPharoTool >> systemPrompt [

	^ systemPrompt
]

{ #category : 'accessing' }
ChatPharoTool >> systemPrompt: aString [

	^ systemPrompt := aString 
]

{ #category : 'accessing' }
ChatPharoTool >> toolCallsFromMessage: message [

    | calls |
    calls := message at: 'tool_calls' ifAbsent: [ nil ].
    calls isNil ifTrue: [ ^ nil ].

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

        callId := c at: 'id' ifAbsent: [ 'tool-', (DateAndTime now asString) ].

        ChatPharoHistorySaverToolCall
            id: callId
            functionName: fn
            arguments: (rawArgs isString ifTrue: [ rawArgs ] ifFalse: [ STONJSON toString: parsedArgs ])
            content: content
    ].
]

{ #category : 'accessing' }
ChatPharoTool >> tools [

	^ tools
]

{ #category : 'accessing' }
ChatPharoTool >> tools: anObject [

	tools := anObject
]
