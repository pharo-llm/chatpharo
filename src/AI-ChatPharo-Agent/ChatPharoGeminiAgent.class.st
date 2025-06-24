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

	| api result |
	api := ChatPharoTool
		       geminiWithAPIKey: apiKey
		       system: self systemPrompt
		       tools: self tools.
	self onToolExecution ifNotNil: [ api onToolExecution: self onToolExecution ].
	model ifNotEmpty: [ api model: model ].
	self history ifNil: [ self history: ChatPharoHistory new ].
	self history addMessage:
		(ChatPharoHistorySaver role: 'user' content: userPrompt).

	result := api getResponseForHistory: self history.
	self history addMessage: result.

	[ result toolCalls notNil ] whileTrue: [
			result := api getResponseForHistory: self history.
			self history addMessage: result ].

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
    | available |
    available := ChatPharoBrowserEnvironment new tools.
    ^ available select: [ :tool |
        ChatPharoSettings default browserToolsEnabled includes: tool name ]
]
