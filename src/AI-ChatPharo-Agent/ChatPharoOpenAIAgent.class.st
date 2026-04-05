Class {
	#name : 'ChatPharoOpenAIAgent',
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
ChatPharoOpenAIAgent class >> displayName [

	^ 'OpenAI / Codex'
]

{ #category : 'api' }
ChatPharoOpenAIAgent class >> isReachable [

	^ [
		  ZnClient new head: 'https://api.openai.com'.
		  true ]
		  on: NetworkError
		  do: [ false ]
]

{ #category : 'api' }
ChatPharoOpenAIAgent class >> modelNames [

	^ #( 'gpt-4o' 'gpt-4o-mini' 'gpt-4-turbo' 'gpt-3.5-turbo' 'o1' 'o1-mini' 'o3-mini' 'codex-mini-latest' )
]

{ #category : 'api' }
ChatPharoOpenAIAgent class >> settingsPresenterFor: anAgent [

	^ ChatPharoOpenAISettingsPresenter on: anAgent
]

{ #category : 'accessing' }
ChatPharoOpenAIAgent >> apiKey [

	^ apiKey
]

{ #category : 'accessing' }
ChatPharoOpenAIAgent >> apiKey: anObject [

	apiKey := anObject.
	ChatPharoSettings saveDefault
]

{ #category : 'accessing' }
ChatPharoOpenAIAgent >> configurationErrorMessage [

	^ 'Please complete all required fields.'
]

{ #category : 'accessing' }
ChatPharoOpenAIAgent >> getResponseForPrompt: userPrompt [

	| api result max count params accIn accOut |
	api := ChatPharoTool openAIWithAPIKey: apiKey system: self systemPrompt tools: self tools.
	self onToolExecution ifNotNil: [ api onToolExecution: self onToolExecution ].
	params := self requestParameters copy.
	temperature ifNotNil: [ params at: 'temperature' put: temperature ].
	api requestParameters: params.
	model ifNotEmpty: [ api model: model ].
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
	^ result
]

{ #category : 'accessing' }
ChatPharoOpenAIAgent >> host [

	^ host
]

{ #category : 'accessing' }
ChatPharoOpenAIAgent >> host: anObject [

	host := anObject
]

{ #category : 'accessing' }
ChatPharoOpenAIAgent >> initialize [

	super initialize.
	host := 'api.openai.com'.
	apiKey := ''.
	model := ''.
	temperature := 0.7
]

{ #category : 'accessing' }
ChatPharoOpenAIAgent >> isConfigured [

	^ host notEmpty and: [ apiKey notEmpty and: [ model notEmpty ] ]
]

{ #category : 'accessing' }
ChatPharoOpenAIAgent >> modelInformation [

	^ self shouldBeImplemented
]

{ #category : 'accessing' }
ChatPharoOpenAIAgent >> modelNames [

	apiKey isEmpty ifTrue: [ ^ self class modelNames ].
	^ [ (ChatPharoTool openAIWithAPIKey: apiKey system: nil) modelNames ]
		  on: Error
		  do: [ self class modelNames ]
]

{ #category : 'accessing' }
ChatPharoOpenAIAgent >> packageName: aString [

	packageName := aString.
	self systemPrompt: (ChatPharoAgent defaultBrowserSystemPrompt copyReplaceAll: '{packageName}' with: packageName)
]

{ #category : 'accessing' }
ChatPharoOpenAIAgent >> supportsThinkingContent [

	^ false
]

{ #category : 'accessing' }
ChatPharoOpenAIAgent >> supportsToolCalling [

	| modelLower |
	model ifEmpty: [ ^ false ].
	self isConfigured ifFalse: [ ^ false ].
	modelLower := model asLowercase.
	(modelLower includesSubstring: 'gpt-4') ifTrue: [ ^ true ].
	(modelLower includesSubstring: 'gpt-3.5') ifTrue: [ ^ true ].
	(modelLower includesSubstring: 'o1') ifTrue: [ ^ true ].
	(modelLower includesSubstring: 'o3') ifTrue: [ ^ true ].
	^ true
]

{ #category : 'accessing' }
ChatPharoOpenAIAgent >> temperature [

	^ temperature
]

{ #category : 'accessing' }
ChatPharoOpenAIAgent >> temperature: anObject [

	temperature := anObject
]

{ #category : 'accessing' }
ChatPharoOpenAIAgent >> testConnection [

	^ [
		  | url client |
		  url := 'https://' , host , '/v1/models'.
		  client := ZnClient new url: url.
		  apiKey ifNotEmpty: [ client headerAt: 'Authorization' put: 'Bearer ' , apiKey ].
		  client get.
		  client response isSuccess ]
		  on: ZnHttpUnsuccessful , NetworkError
		  do: [ false ]
]

{ #category : 'accessing' }
ChatPharoOpenAIAgent >> tools [

	| available settings customToolClients |
	settings := ChatPharoSettings default.
	available := ChatPharoBrowserEnvironment new tools.
	available := available select: [ :tool | settings browserToolsEnabled includes: tool name ].
	customToolClients := settings customToolsAsClients.
	^ available , customToolClients
]
