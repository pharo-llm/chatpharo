"
Concrete agent for **DeepSeek REST API**.
* Holds extra knobs: `apiKey`, `host`, `temperature`.
* Builds a `ChatPharoTool` preconfigured for DeepSeek's OpenAI-compatible endpoint and delegates the heavy lifting to it.
* **Why** – same role as other agents but targeting DeepSeek; packaging all DeepSeek-specific wiring in one place keeps the rest of ChatPharo backend-agnostic.
```smalltalk
| chat deepseek |
deepseek := ChatPharoDeepSeekAgent new
	apiKey: 'your-api-key';
	model: 'deepseek-chat';
	yourself.
chat := ChatPharoChat new
	agent: deepseek;
	yourself.
chat sendMessage: 'Hello DeepSeek!'.
chat waitForPromptProcessDone.
(chat messages last answer) inspect.
"
Class {
	#name : 'ChatPharoDeepSeekAgent',
	#superclass : 'ChatPharoAgent',
	#instVars : [
		'host',
		'apiKey',
		'temperature',
		'packageName'
	],
	#category : 'AI-ChatPharo-Agent',
	#package : 'AI-ChatPharo-Agent'
}

{ #category : 'api' }
ChatPharoDeepSeekAgent class >> displayName [

	^ 'DeepSeek'
]

{ #category : 'api' }
ChatPharoDeepSeekAgent class >> isReachable [

	^ [ ZnClient new head: 'https://api.deepseek.com'. true ]
		on: NetworkError do: [ false ]
]

{ #category : 'api' }
ChatPharoDeepSeekAgent class >> modelNames [ 

	^ #( 'Enter your API-Key' )
]

{ #category : 'api' }
ChatPharoDeepSeekAgent class >> settingsPresenterFor: anAgent [

	^ ChatPharoDeepSeekSettingsPresenter on: anAgent
]

{ #category : 'accessing' }
ChatPharoDeepSeekAgent >> apiKey [

	^ apiKey
]

{ #category : 'accessing' }
ChatPharoDeepSeekAgent >> apiKey: anObject [

	apiKey := anObject.
	ChatPharoSettings saveDefault
]

{ #category : 'accessing' }
ChatPharoDeepSeekAgent >> configurationErrorMessage [

	^ 'Please complete all required fields.'
]

{ #category : 'accessing' }
ChatPharoDeepSeekAgent >> getResponseForPrompt: userPrompt [

	| api result max count accIn accOut params |
	api := ChatPharoTool deepSeekWithAPIKey: apiKey system: self systemPrompt tools: self tools.
	self onToolExecution ifNotNil: [ api onToolExecution: self onToolExecution ].
	model ifNotEmpty: [ api model: model ].
		params := self requestParameters copy.
	temperature ifNotNil: [ params at: 'temperature' put: temperature ].
	api requestParameters: params.
	self history ifNil: [ self history: ChatPharoHistory new ].
	self history addMessage: (ChatPharoHistorySaver role: 'user' content: userPrompt).
	result := api getResponseForHistory: self history.
	self history addMessage: result.
	accIn := result inputTokens ifNil: [ 0 ].
	accOut := result outputTokens ifNil: [ 0 ].
	max := ChatPharoSettings default maximumIterations ifNil: [ 1 ].
	count := 0.
	[ result toolCalls notNil and: [ count < max ] ] whileTrue: [
			result := api getResponseForHistory: self history.
			self history addMessage: result.
			result inputTokens ifNotNil: [ :v | accIn := accIn + v ].
			result outputTokens ifNotNil: [ :v | accOut := accOut + v ].
			count := count + 1 ].
	result inputTokens: accIn.
	result outputTokens: accOut.
	result totalTokens: accIn + accOut.
	self response: result.
	^ result content
]

{ #category : 'accessing' }
ChatPharoDeepSeekAgent >> host [

	^ host
]

{ #category : 'accessing' }
ChatPharoDeepSeekAgent >> host: anObject [

	host := anObject
]

{ #category : 'accessing' }
ChatPharoDeepSeekAgent >> initialize [

	super initialize.
	host := 'api.deepseek.com'.
	apiKey := ''.
	model := ''.
	temperature := 0.7
]

{ #category : 'accessing' }
ChatPharoDeepSeekAgent >> isConfigured [

	^ host notEmpty and: [ apiKey notEmpty and: [ model notEmpty ] ]
]

{ #category : 'initialization' }
ChatPharoDeepSeekAgent >> modelInformation [
	^ self shouldBeImplemented
]

{ #category : 'initialization' }
ChatPharoDeepSeekAgent >> modelNames [

	apiKey isEmpty ifTrue: [ ^ self class modelNames ].

	^ [
		(ChatPharoTool
			deepSeekWithAPIKey: apiKey
			system: nil) modelNames
	] on: Error do: [ self class modelNames ]
]

{ #category : 'initialization' }
ChatPharoDeepSeekAgent >> packageName: aString [

	packageName := aString.
	self systemPrompt: (ChatPharoAgent defaultBrowserSystemPrompt
			 copyReplaceAll: '{packageName}'
			 with: packageName)
]

{ #category : 'accessing' }
ChatPharoDeepSeekAgent >> supportsThinkingContent [

	^ false
]

{ #category : 'tools support' }
ChatPharoDeepSeekAgent >> supportsToolCalling [
	"Check if the current DeepSeek model supports tool calling.
	DeepSeek chat and coder models support function calling."

	| modelLower nonToolModels |
	model ifEmpty: [ ^ false ].
	self isConfigured ifFalse: [ ^ false ].

	modelLower := model asLowercase.

	"Models that don't support tool calling"
	nonToolModels := #( 'embed' 'reasoner' ).
	(nonToolModels anySatisfy: [ :pattern |
		 modelLower includesSubstring: pattern ]) ifTrue: [ ^ false ].

	"DeepSeek chat and coder models support tool calling"
	^ true
]

{ #category : 'accessing' }
ChatPharoDeepSeekAgent >> temperature [

	^ temperature
]

{ #category : 'accessing' }
ChatPharoDeepSeekAgent >> temperature: anObject [

	temperature := anObject
]

{ #category : 'accessing' }
ChatPharoDeepSeekAgent >> testConnection [

	^ [
		| url client |
		url := 'https://' , host , '/v1/models'.
		client := ZnClient new url: url.
		apiKey ifNotEmpty: [ client setBearerAuthentication: apiKey ].
		client head.
		true ]
		on: ZnHttpUnsuccessful , NetworkError
		do: [ false ]
]

{ #category : 'tools support' }
ChatPharoDeepSeekAgent >> tools [

	| available settings customToolClients |
	settings := ChatPharoSettings default.
	available := ChatPharoBrowserEnvironment new tools.
	available := available select: [ :tool |
		settings browserToolsEnabled includes: tool name ].
	"Add enabled custom tools"
	customToolClients := settings customToolsAsClients.
	^ available , customToolClients
]
