"
I provide integration with Ollama API for local language model inference.
I support both the native Ollama API and the OpenAI-compatible API provided by Ollama.
"
Class {
	#name : 'OllamaAPI',
	#superclass : 'LLMChatAPI',
	#instVars : [
		'baseURL',
		'useOpenAICompatibleAPI',
		'promptPrefix'
	],
	#category : 'AI-ChatPharo-Ollama',
	#package : 'AI-ChatPharo',
	#tag : 'Ollama'
}

{ #category : 'instance creation' }
OllamaAPI class >> new [
	^ self newWithOpenAICompatibleAPI: true
]

{ #category : 'instance creation' }
OllamaAPI class >> newWithNativeAPI [
	^ self newWithOpenAICompatibleAPI: false
]

{ #category : 'instance creation' }
OllamaAPI class >> newWithOpenAICompatibleAPI: aBoolean [
	^ self basicNew
		initializeWithOpenAICompatibleAPI: aBoolean;
		yourself
]

{ #category : 'ollama models' }
OllamaAPI class >> ollamaVersion [
	"Retrieve the Ollama version"
	| response  |
	
	response := ZnClient new get: 'http://localhost:11434/api/version'.
	^ (STONJSON fromString: response) at: 'version'
]

{ #category : 'instance creation' }
OllamaAPI class >> system: systemText [
	"Create and return an instance with predefined system text for Ollama queries."
	| api |
	api := self new.
	api system: systemText.
	^ api 
]

{ #category : 'instance creation' }
OllamaAPI class >> system: systemText tools: toolsCollection [
	"Create and return an instance with predefined system text and tools for Ollama queries."
	| api |
	api := self new.
	api system: systemText.
	api tools: toolsCollection.
	^ api 
]

{ #category : 'private' }
OllamaAPI >> applyToolFunction: functionName arguments: arguments [
	"Apply a tool function with the given name and arguments"
	
	tools do: [ :tool |
		tool name = functionName ifTrue: [
			^ [ tool applyTo: arguments ] on: Error do: [ Dictionary with: 'error' -> 'Error' ] ] ].
	^ Dictionary with: 'error' -> ('There is no function named "{1}"' format: { functionName })
]

{ #category : 'accessing' }
OllamaAPI >> baseURL [
	^ baseURL
]

{ #category : 'private' }
OllamaAPI >> client [
	"Return a ZnClient configured for the baseURL"
	
	^ ZnClient new
		url: baseURL;
		yourself
]

{ #category : 'accessing' }
OllamaAPI >> getResponseForHistory: history [
	"Gets a response from Ollama based on the chat history"
	
	^ useOpenAICompatibleAPI
		ifTrue: [ self getResponseWithOpenAICompatibleAPIForHistory: history ]
		ifFalse: [ self getResponseWithNativeAPIForHistory: history ]
]

{ #category : 'accessing - private' }
OllamaAPI >> getResponseWithNativeAPIForHistory: history [
	"Gets a response using the native Ollama API"
	
	^ ChatPharoHistorySaver role: 'assistant'
		content: (self promptPrefix: history asPromptPrefix; getResponseWithNativeAPIForPrompt: nil)
]

{ #category : 'accessing - private' }
OllamaAPI >> getResponseWithNativeAPIForPrompt: prompt [
	"Sends a prompt to the native Ollama API, receives JSON response, and extracts the 'response' value"
	| apiGenerateUrl jsonResponse requestDictionary requestBody response |
	
	apiGenerateUrl := 'http://localhost:11434/api/generate'.
	requestDictionary := Dictionary newFrom: { 
		#model -> model.
		#system -> self system.
		#prompt -> (String streamContents: [ :stream |
			stream nextPutAll: self promptPrefix.
			prompt ifNotNil: [ stream nextPutAll: ' '; nextPutAll: prompt ] ]).
		#stream -> false.
		#options -> (Dictionary newFrom: {
			#temperature -> 0})
	}.
	
	requestBody := (STONJSON toString: requestDictionary).
	jsonResponse := ZnClient new
		url: apiGenerateUrl;
		entity: (ZnEntity with: requestBody);
		post;
		contents.
	
	response := (STONJSON fromString: jsonResponse) at: 'response'.
	^ response
]

{ #category : 'accessing - private' }
OllamaAPI >> getResponseWithOpenAICompatibleAPIForHistory: history [
	"Gets a response using the OpenAI-compatible API provided by Ollama"
	
	| messages data response message |

	messages := Array streamContents: [ :stream |
		system ifNotNil: [
			stream nextPut: (Dictionary with: 'role' -> 'system' with: 'content' -> system) ].
		history putOpenAIChatMessagesOn: stream ].
	
	data := Dictionary with: 'model' -> model with: 'messages' -> messages.
	tools ifNotNil: [
		data add: 'tools' -> (tools collect: [ :tool | tool openAIChatTool ] as: Array);
			add: 'tool_choice' -> 'auto' ].
	
	response := self client addPath: #('chat' 'completions');
		entity: (ZnEntity json: (STONJSON toString: data));
		timeout: (Duration minutes: 5) asSeconds;
		post;
		response.
		
	response isSuccess ifFalse: [ Error signal: 'Could not get chat completion' ].
	message := ((STONJSON fromString: response contents) at: 'choices') first at: 'message'.
	
	^ ChatPharoHistorySaver role: 'assistant'
		content: (message at: 'content' ifAbsent: [ nil ])
		toolCalls: (self toolCallsFromMessage: message)
]

{ #category : 'initialization' }
OllamaAPI >> initialize [
	super initialize.
	self promptPrefix: ''.
	self model: self modelNames first.
]

{ #category : 'initialization' }
OllamaAPI >> initializeWithOpenAICompatibleAPI: aBoolean [
	self initialize.
	useOpenAICompatibleAPI := aBoolean.
	baseURL := useOpenAICompatibleAPI
		ifTrue: [ ZnUrl fromString: 'http://localhost:11434/v1' ]
		ifFalse: [ ZnUrl fromString: 'http://localhost:11434/api' ].
]

{ #category : 'model information' }
OllamaAPI >> modelInformation [
	"Show information about a model including details, modelfile, template, parameters, license, system prompt."
	"Check https://github.com/ollama/ollama/blob/main/docs/api.md#show-model-information for details"
	| url jsonResponse requestBody response |
	
	url := 'http://localhost:11434/api/show'.
	requestBody := STONJSON toString: { 
		#model -> model.
	} asDictionary.
	
	jsonResponse := ZnClient new
		url: url;
		entity: (ZnEntity with: requestBody);
		post;
		contents.
		
	response := (STONJSON fromString: jsonResponse).
	^ response
]

{ #category : 'accessing' }
OllamaAPI >> modelNames [
	"Return the available model names from Ollama"
	
	^ useOpenAICompatibleAPI
		ifTrue: [ self modelNamesFromOpenAICompatibleAPI ]
		ifFalse: [ self modelNamesFromNativeAPI ]
]

{ #category : 'accessing - private' }
OllamaAPI >> modelNamesFromNativeAPI [
	"Returns model names from the native Ollama API"
	
	| response |
	response := ZnClient new get: 'http://localhost:11434/api/tags'.
	^ (STONJSON fromString: response) at: 'models' ifPresent: [ :models |
		models collect: [ :ollamaModel | ollamaModel at: 'name' ] ]
]

{ #category : 'accessing - private' }
OllamaAPI >> modelNamesFromOpenAICompatibleAPI [
	"Returns model names from the OpenAI-compatible API"
	
	| response |
	response := self client addPathSegment: 'models'; get; response.
	response isSuccess ifFalse: [ Error signal: 'Could not retrieve models' ].
	^ ((STONJSON fromString: response contents) at: 'data') collect: [ :modelObject | modelObject at: 'id' ]
]

{ #category : 'accessing' }
OllamaAPI >> promptPrefix [
	^ promptPrefix
]

{ #category : 'accessing' }
OllamaAPI >> promptPrefix: anObject [
	promptPrefix := anObject
]

{ #category : 'private' }
OllamaAPI >> toolCallsFromMessage: message [
	"Extracts and processes tool calls from an OpenAI API response message"
	
	^ message at: 'tool_calls'
		ifPresent: [ :toolCalls |
			toolCalls collect: [ :toolCall |
				| function functionName arguments content |
				function := toolCall at: 'function'.
				functionName := function at: 'name'.
				arguments := function at: 'arguments'.
				content := STONJSON toString: (self applyToolFunction: functionName
					arguments: ([ STONJSON fromString: arguments ] on: STONReaderError
						do: [ Dictionary with: 'error' -> 'Invalid arguments' ])).
				ChatPharoHistorySaverToolCall id: (toolCall at: 'id') functionName: functionName
					arguments: arguments content: content ] ]
		ifAbsent: [ nil ]
]

{ #category : 'accessing' }
OllamaAPI >> useOpenAICompatibleAPI [
	^ useOpenAICompatibleAPI
]

{ #category : 'accessing' }
OllamaAPI >> useOpenAICompatibleAPI: aBoolean [
	useOpenAICompatibleAPI := aBoolean.
	baseURL := useOpenAICompatibleAPI
		ifTrue: [ ZnUrl fromString: 'http://localhost:11434/v1' ]
		ifFalse: [ ZnUrl fromString: 'http://localhost:11434/api' ].
]
