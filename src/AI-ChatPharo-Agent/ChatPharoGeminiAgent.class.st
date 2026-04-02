"
Concrete agent for **Google Gemini REST**.

* Holds extra knobs: `apiKey`, `host`, `temperature`.
* Builds a `ChatPharoTool` preconfigured for Google’s “OpenAI-compatible” endpoint and delegates the heavy lifting to it.
* **Why** – same role as the Ollama agent but targeting Gemini; packaging all Gemini-specific wiring in one place keeps the rest of the codebase backend-agnostic.



```smalltalk
| chat gemini |
gemini := GeminiAgent new
	apiKey: '';
	model: 'models/gemini-2.0-flash';
	yourself.

chat := ChatPharoChat new
	agent: gemini;
	yourself.

chat sendMessage: 'Hello Gemini!'.
chat waitForPromptProcessDone.
(chat messages last answer) inspect.

```
"
Class {
	#name : 'ChatPharoGeminiAgent',
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
ChatPharoGeminiAgent class >> displayName [

	^ 'Gemini'
]

{ #category : 'api' }
ChatPharoGeminiAgent class >> isReachable [

	^ [
		| url |
		url := 'https://generativelanguage.googleapis.com/v1beta/models?key=dummy'.
		ZnClient new get: url.
		true ]
		on: ZnHttpUnsuccessful , NetworkError
		do: [ ^ false ].

]

{ #category : 'api' }
ChatPharoGeminiAgent class >> modelNames [

	^ #( 'Enter your API-Key' )
]

{ #category : 'api' }
ChatPharoGeminiAgent class >> settingsPresenterFor: anAgent [

	^ ChatPharoGeminiSettingsPresenter on: anAgent
]

{ #category : 'accessing' }
ChatPharoGeminiAgent >> apiKey [

	^ apiKey
]

{ #category : 'accessing' }
ChatPharoGeminiAgent >> apiKey: anObject [

	apiKey := anObject.
	ChatPharoSettings saveDefault
]

{ #category : 'accessing' }
ChatPharoGeminiAgent >> configurationErrorMessage [

	^ 'Please complete all required fields.'
]

{ #category : 'initialization' }
ChatPharoGeminiAgent >> getResponseForPrompt: userPrompt [

	| api result max count params accIn accOut |
	api := ChatPharoTool geminiWithAPIKey: apiKey system: self systemPrompt tools: self tools.
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
			count := count + 1 ].
	result inputTokens: accIn.
	result outputTokens: accOut.
	result totalTokens: accIn + accOut.
	self response: result.

	^ result content
]

{ #category : 'accessing' }
ChatPharoGeminiAgent >> host [

	^ host
]

{ #category : 'accessing' }
ChatPharoGeminiAgent >> host: anObject [

	host := anObject
]

{ #category : 'initialization' }
ChatPharoGeminiAgent >> initialize [

	super initialize.
	host := 'generativelanguage.googleapis.com'.
	apiKey := ''.
	model := ''.
	temperature := 0.7
]

{ #category : 'accessing' }
ChatPharoGeminiAgent >> isConfigured [

	^ host notEmpty and: [ apiKey notEmpty and: [ model notEmpty ] ]
]

{ #category : 'initialization' }
ChatPharoGeminiAgent >> modelInformation [
	^ self shouldBeImplemented
]

{ #category : 'accessing' }
ChatPharoGeminiAgent >> modelNames [ 

        apiKey isEmpty ifTrue: [ ^ self class modelNames ].

        ^ [
                (ChatPharoTool
                        geminiWithAPIKey: apiKey
                        system: nil) modelNames
        ] on: Error do: [ self class modelNames ]
]

{ #category : 'accessing' }
ChatPharoGeminiAgent >> packageName: aString [

	packageName := aString.
	self systemPrompt: (ChatPharoAgent defaultBrowserSystemPrompt
			 copyReplaceAll: '{packageName}'
			 with: packageName)
]

{ #category : 'accessing' }
ChatPharoGeminiAgent >> supportsThinkingContent [

	^ false
]

{ #category : 'tools support' }
ChatPharoGeminiAgent >> supportsToolCalling [
	"Check if the current Gemini model supports tool calling.
	Most Gemini models support tools, except embedding and some legacy models."

	| modelLower nonToolModels |
	model ifEmpty: [ ^ false ].
	self isConfigured ifFalse: [ ^ false ].

	modelLower := model asLowercase.

	"Models that don't support tool calling"
	nonToolModels := #( 'embedding' 'text-embedding' 'aqa' ).
	(nonToolModels anySatisfy: [ :pattern |
		 modelLower includesSubstring: pattern ]) ifTrue: [ ^ false ].

	"All other Gemini models support tool calling"
	^ true
]

{ #category : 'accessing' }
ChatPharoGeminiAgent >> temperature [

	^ temperature
]

{ #category : 'accessing' }
ChatPharoGeminiAgent >> temperature: anObject [

	temperature := anObject
]

{ #category : 'accessing' }
ChatPharoGeminiAgent >> testConnection [

	^ [
		| url |
		url := 'https://' , host , '/v1beta/models?key=' , apiKey.
		ZnClient new get: url.
		true ]
		on: ZnHttpUnsuccessful , NetworkError
		do: [ false ]
]

{ #category : 'tools support' }
ChatPharoGeminiAgent >> tools [
       | available settings customToolClients |
    settings := ChatPharoSettings default.
    available := ChatPharoBrowserEnvironment new tools.
    available := available select: [ :tool |
        settings browserToolsEnabled includes: tool name ].
    "Add enabled custom tools"
    customToolClients := settings customToolsAsClients.
    ^ available , customToolClients
]
