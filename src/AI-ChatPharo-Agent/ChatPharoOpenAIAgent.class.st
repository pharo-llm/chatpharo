"
Open AI agent backend
"
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

	^ #( 'Enter your API-Key' )
]

{ #category : 'api' }
ChatPharoOpenAIAgent class >> settingsPresenterFor: anAgent [

	^ ChatPharoOpenAISettingsPresenter on: anAgent
]

{ #category : 'accessing' }
ChatPharoOpenAIAgent >> apiBaseURL [

	^ ZnUrl fromString: self apiBaseURLString
]

{ #category : 'accessing' }
ChatPharoOpenAIAgent >> apiBaseURLString [

	| value |
	value := (host ifNil: [ '' ]) asString trimBoth.
	value isEmpty ifTrue: [ ^ '' ].
	((value beginsWith: 'http://') or: [ value beginsWith: 'https://' ])
		ifFalse: [ value := 'https://' , value ].
	(value last = $/) ifTrue: [ value := value allButLast ].
	(value endsWith: '/v1') ifFalse: [ value := value , '/v1' ].
	^ value
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
ChatPharoOpenAIAgent >> apiKeyPlaceholder [

	^ 'sk-...'
]

{ #category : 'accessing' }
ChatPharoOpenAIAgent >> configurationErrorMessage [

	^ 'Please complete all required fields.'
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
ChatPharoOpenAIAgent >> hostPlaceholder [

	^ 'https://api.openai.com/v1'
]

{ #category : 'accessing' }
ChatPharoOpenAIAgent >> initialize [

	super initialize.
	host := 'api.openai.com'.
	apiKey := ''.
	model := ''
]

{ #category : 'accessing' }
ChatPharoOpenAIAgent >> isConfigured [

	^ host notEmpty and: [ apiKey notEmpty and: [ model notEmpty ] ]
]

{ #category : 'accessing' }
ChatPharoOpenAIAgent >> modelInformation [

	^ 'OpenAI/Codex agent. Requires an API key from
https://platform.openai.com/api-keys'
]

{ #category : 'accessing' }
ChatPharoOpenAIAgent >> modelNames [

	apiKey isEmpty ifTrue: [ ^ self class modelNames ].
	^ [
	  (ChatPharoTool
		   baseURL: self apiBaseURL
		   apiKey: apiKey
		   system: nil) modelNames ]
		  on: Error
		  do: [ self class modelNames ]
]

{ #category : 'private - conversation' }
ChatPharoOpenAIAgent >> newCompletionClient [

	^ ChatPharoTool
		  baseURL: self apiBaseURL
		  apiKey: apiKey
		  system: self systemPrompt
		  tools: self tools
]

{ #category : 'accessing' }
ChatPharoOpenAIAgent >> packageName: aString [

	packageName := aString.
	self systemPrompt: (ChatPharoAgent defaultBrowserSystemPrompt copyReplaceAll: '{packageName}' with: packageName)
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
		  url := self apiBaseURLString , '/models'.
		  client := ZnClient new url: url.
		  apiKey ifNotEmpty: [ client headerAt: 'Authorization' put: 'Bearer ' , apiKey ].
		  client get.
		  client response isSuccess ]
		  on: ZnHttpUnsuccessful , NetworkError
		  do: [ false ]
]
