"
Concrete agent for **LM Studio local server**.
* Connects to LM Studio's OpenAI-compatible API endpoint.
* Discovers available models via `/models`, handles chat completions via `/chat/completions`.
* Uses OpenAI-compatible API format through ChatPharoTool.
* **Why** – allows local LLM execution through LM Studio with full OpenAI API compatibility.
"
Class {
	#name : 'ChatPharoLMStudioAgent',
	#superclass : 'ChatPharoAgent',
	#instVars : [
		'host',
		'port',
		'temperature',
		'packageName'
	],
	#category : 'AI-ChatPharo-Agent',
	#package : 'AI-ChatPharo-Agent'
}

{ #category : 'initialization' }
ChatPharoLMStudioAgent class >> defaultHost [

    ^ 'localhost'
]

{ #category : 'initialization' }
ChatPharoLMStudioAgent class >> defaultPort [

    ^ '1234'
]

{ #category : 'api' }
ChatPharoLMStudioAgent class >> displayName [

	^ 'LM Studio'
]

{ #category : 'api' }
ChatPharoLMStudioAgent class >> isExternalApi [

	^ false
]

{ #category : 'api' }
ChatPharoLMStudioAgent class >> isReachable [
	[
		ZnClient new get:
			'http://' , self defaultHost , ':' , self defaultPort
			, '/v1/models' ]
		on: NetworkError
		do: [ ^ false ].
	^ true
]

{ #category : 'api' }
ChatPharoLMStudioAgent class >> modelNames [

	^ self models collect: [ :modelInfo | modelInfo at: 'id' ]
]

{ #category : 'api' }
ChatPharoLMStudioAgent class >> models [

	| response |
	self isReachable ifFalse: [ ^ OrderedCollection empty ].
	response := ZnClient new get:
		            'http://' , self defaultHost , ':' , self defaultPort
		            , '/v1/models'.
	^ (STONJSON fromString: response) at: 'data'
]

{ #category : 'api' }
ChatPharoLMStudioAgent class >> settingsPresenterFor: anAgent [

	^ ChatPharoLMStudioSettingsPresenter on: anAgent
]

{ #category : 'accessing' }
ChatPharoLMStudioAgent >> configurationErrorMessage [

	^ 'Please complete all required fields.'
]

{ #category : 'accessing' }
ChatPharoLMStudioAgent >> getResponseForPrompt: userPrompt [

	| api result params accIn accOut |
	api := ChatPharoTool
		       lmStudioWithHost: host
		       port: port
		       system: self systemPrompt
		       tools: self tools.
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
	[ result toolCalls isEmptyOrNil not ] whileTrue: [
			result := api getResponseForHistory: self history.
			self history addMessage: result.
			result inputTokens ifNotNil: [ :v | accIn := accIn + v ].
			result outputTokens ifNotNil: [ :v | accOut := accOut + v ] ].
	result inputTokens: accIn.
	result outputTokens: accOut.
	result totalTokens: accIn + accOut.
	self response: result.
	^ result content
]

{ #category : 'accessing' }
ChatPharoLMStudioAgent >> host [

	^ host
]

{ #category : 'accessing' }
ChatPharoLMStudioAgent >> host: anObject [

	host := anObject
]

{ #category : 'accessing' }
ChatPharoLMStudioAgent >> initialize [

	super initialize.
	host := self class defaultHost.
	port := self class defaultPort.
	temperature := 0.7.
	self model ifNil: [
			| availableModels |
			availableModels := self class modelNames.

			availableModels isEmpty ifFalse: [
				self model: availableModels first ] ].

	self systemPrompt: self class defaultSystemPrompt.
	self promptPrefix: ''.
	packageName := ''
]

{ #category : 'accessing' }
ChatPharoLMStudioAgent >> isConfigured [

        ^ host notEmpty and: [ port notEmpty and: [ model notEmpty ] ]
]

{ #category : 'initialization' }
ChatPharoLMStudioAgent >> modelInformation [

	| url jsonResponse |
	url := 'http://' , host , ':' , port , '/v1/models/' , model.
	jsonResponse := ZnClient new
		                url: url;
		                get;
		                contents.
	^ STONJSON fromString: jsonResponse
]

{ #category : 'initialization' }
ChatPharoLMStudioAgent >> modelNames [

	^ self class modelNames
]

{ #category : 'initialization' }
ChatPharoLMStudioAgent >> packageName: aString [

packageName := aString.
	self systemPrompt: (self browserSystemPrompt
			 copyReplaceAll: '{packageName}'
			 with: packageName)
]

{ #category : 'initialization' }
ChatPharoLMStudioAgent >> port [

	^ port
]

{ #category : 'initialization' }
ChatPharoLMStudioAgent >> port: anObject [

	port := anObject
]

{ #category : 'accessing' }
ChatPharoLMStudioAgent >> supportsThinkingContent [

	^ false
]

{ #category : 'tools support' }
ChatPharoLMStudioAgent >> supportsToolCalling [

	"Check if the current LM Studio model supports tool calling.
	Most modern models loaded in LM Studio support function calling."

	| modelNameLower toolSupportingPatterns |
	model ifEmpty: [ ^ false ].

	"Check model name pattern for known tool-capable models"
	modelNameLower := model asLowercase.
	toolSupportingPatterns := #( 'llama-3' 'llama3' 'mistral' 'mixtral'
	    'qwen' 'hermes' 'functionary' 'firefunction' 'phi-3' 'phi3'
	    'gemma-2' 'gemma2' 'command-r' 'granite' ).

	(toolSupportingPatterns anySatisfy: [ :pattern |
		modelNameLower includesSubstring: pattern ])
		ifTrue: [ ^ true ].

	"Default: assume tool support for unknown models as LM Studio is typically used with capable models"
	^ true
]

{ #category : 'tools support' }
ChatPharoLMStudioAgent >> temperature [

	^ temperature
]

{ #category : 'tools support' }
ChatPharoLMStudioAgent >> temperature: anObject [

	temperature := anObject
]

{ #category : 'tools support' }
ChatPharoLMStudioAgent >> testConnection [

	^ [
		ZnClient new get: 'http://' , host , ':' , port , '/v1/models'.
		true ]
		on: ZnHttpUnsuccessful , NetworkError
		do: [ false ]
]

{ #category : 'tools support' }
ChatPharoLMStudioAgent >> tools [

	 | available settings customToolClients |
    settings := ChatPharoSettings default.
    available := ChatPharoBrowserEnvironment new tools.
    available := available select: [ :tool |
        settings browserToolsEnabled includes: tool name ].
    "Add enabled custom tools"
    customToolClients := settings customToolsAsClients.
    ^ available , customToolClients
]
