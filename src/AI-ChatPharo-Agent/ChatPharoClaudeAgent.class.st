"
Concrete agent for **Anthropic Claude REST API**.
* Holds extra knobs: `apiKey`, `host`, `temperature`.
* Builds a `ChatPharoTool` preconfigured for Anthropic's OpenAI-compatible endpoint and delegates the heavy lifting to it.
* **Why** – same role as other agents but targeting Claude; packaging all Claude-specific wiring in one place keeps the rest of ChatPharo backend-agnostic.
```smalltalk
| chat claude |
claude := ChatPharoClaudeAgent new
	apiKey: 'your-api-key';
	model: 'claude-sonnet-4-20250514';
	yourself.
chat := ChatPharoChat new
	agent: claude;
	yourself.
chat sendMessage: 'Hello Claude!'.
chat waitForPromptProcessDone.
(chat messages last answer) inspect.
"
Class {
	#name : 'ChatPharoClaudeAgent',
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
ChatPharoClaudeAgent class >> displayName [

	^ 'Claude (Anthropic)'
]

{ #category : 'api' }
ChatPharoClaudeAgent class >> isReachable [

	^ [ ZnClient new head: 'https://api.anthropic.com'. true ]
		on: NetworkError do: [ false ]
]

{ #category : 'api' }
ChatPharoClaudeAgent class >> modelNames [

	^ #( 'Enter your API-Key' )
]

{ #category : 'api' }
ChatPharoClaudeAgent class >> settingsPresenterFor: anAgent [

	^ ChatPharoClaudeSettingsPresenter on: anAgent
]

{ #category : 'accessing' }
ChatPharoClaudeAgent >> apiKey [

	^ apiKey
]

{ #category : 'accessing' }
ChatPharoClaudeAgent >> apiKey: anObject [

	apiKey := anObject.
	ChatPharoSettings saveDefault
]

{ #category : 'accessing' }
ChatPharoClaudeAgent >> configurationErrorMessage [

	^ 'Please complete all required fields.'
]

{ #category : 'accessing' }
ChatPharoClaudeAgent >> getResponseForPrompt: userPrompt [

	| api result max count |
	api := ChatPharoTool claudeWithAPIKey: apiKey system: self systemPrompt tools: self tools.
	self onToolExecution ifNotNil: [ api onToolExecution: self onToolExecution ].
	model ifNotEmpty: [ api model: model ].
	self history ifNil: [ self history: ChatPharoHistory new ].
	self history addMessage: (ChatPharoHistorySaver role: 'user' content: userPrompt).
	result := api getResponseForHistory: self history.
	self history addMessage: result.

	max := ChatPharoSettings default maximumIterations ifNil: [ 1 ].
	count := 0.
	[ result toolCalls notNil and: [ count < max ] ] whileTrue: [
			result := api getResponseForHistory: self history.
			self history addMessage: result.
			count := count + 1 ].
self response: result.
	^ result
]

{ #category : 'accessing' }
ChatPharoClaudeAgent >> host [

	^ host
]

{ #category : 'accessing' }
ChatPharoClaudeAgent >> host: anObject [

	host := anObject
]

{ #category : 'accessing' }
ChatPharoClaudeAgent >> initialize [

	super initialize.
	host := 'api.anthropic.com'.
	apiKey := ''.
	model := ''.
	temperature := 0.7
]

{ #category : 'accessing' }
ChatPharoClaudeAgent >> isConfigured [

	^ host notEmpty and: [ apiKey notEmpty and: [ model notEmpty ] ]
]

{ #category : 'initialization' }
ChatPharoClaudeAgent >> modelInformation [
	^ self shouldBeImplemented
]

{ #category : 'initialization' }
ChatPharoClaudeAgent >> modelNames [

	apiKey isEmpty ifTrue: [ ^ self class modelNames ].

	^ [
		(ChatPharoTool
			claudeWithAPIKey: apiKey
			system: nil) modelNames
	] on: Error do: [ self class modelNames ]
]

{ #category : 'initialization' }
ChatPharoClaudeAgent >> packageName: aString [

	packageName := aString.
	self systemPrompt: (ChatPharoAgent defaultBrowserSystemPrompt
			 copyReplaceAll: '{packageName}'
			 with: packageName)
]

{ #category : 'accessing' }
ChatPharoClaudeAgent >> supportsThinkingContent [

	^ true
]

{ #category : 'tools support' }
ChatPharoClaudeAgent >> supportsToolCalling [
	"Check if the current Claude model supports tool calling.
	All Claude 3+ models support tool calling."

	| modelLower |
	model ifEmpty: [ ^ false ].
	self isConfigured ifFalse: [ ^ false ].

	modelLower := model asLowercase.

	"All Claude 3+ models support tool calling"
	(modelLower includesSubstring: 'claude-3') ifTrue: [ ^ true ].
	(modelLower includesSubstring: 'claude-sonnet') ifTrue: [ ^ true ].
	(modelLower includesSubstring: 'claude-opus') ifTrue: [ ^ true ].
	(modelLower includesSubstring: 'claude-haiku') ifTrue: [ ^ true ].

	"Default to true for newer models"
	^ true
]

{ #category : 'initialization' }
ChatPharoClaudeAgent >> temperature [

	^ temperature
]

{ #category : 'accessing' }
ChatPharoClaudeAgent >> temperature: anObject [

	temperature := anObject
]

{ #category : 'accessing' }
ChatPharoClaudeAgent >> testConnection [

	^ [
		| url client |
		url := 'https://' , host , '/v1/models'.
		client := ZnClient new url: url.
		apiKey ifNotEmpty: [ client headerAt: 'x-api-key' put: apiKey ].
		client headerAt: 'anthropic-version' put: '2023-06-01'.
		client get.
		client response isSuccess ]
		on: ZnHttpUnsuccessful , NetworkError
		do: [ false ]
]

{ #category : 'tools support' }
ChatPharoClaudeAgent >> tools [

	| available settings customToolClients |
	settings := ChatPharoSettings default.
	available := ChatPharoBrowserEnvironment new tools.
	available := available select: [ :tool |
		settings browserToolsEnabled includes: tool name ].
	"Add enabled custom tools"
	customToolClients := settings customToolsAsClients.
	^ available , customToolClients
]
