"
Concrete agent for a **local Ollama server**.

* Connectivity helpers ping `http://localhost:11434`.
* Discovers available models via `/api/tags`, asks completions via `/api/generate`, shows model metadata via `/api/show`.
* Uses JSON directly, not `ChatPharoTool`, because the Ollama REST schema is simpler.
* **Why** – wraps the Ollama CLI/daemon behind the polymorphic `ChatPharoAgent` façade so the rest of ChatPharo can treat it exactly like any cloud model.
"
Class {
	#name : 'ChatPharoOllamaAgent',
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
ChatPharoOllamaAgent class >> defaultHost [ 

    ^ 'localhost'
]

{ #category : 'initialization' }
ChatPharoOllamaAgent class >> defaultPort [ 

    ^ '11434'
]

{ #category : 'api' }
ChatPharoOllamaAgent class >> deleteModel: aModelName [ 


        self isReachable ifFalse: [
                ^ self error: 'Ollama server not reachable' ].
        ZnClient new
                url:
                        'http://' , self defaultHost , ':' , self defaultPort , '/api/delete';
                entity: (ZnEntity with:
                                         (STONJSON toString: { (#name -> aModelName) } asDictionary));
                delete;
                yourself
]

{ #category : 'api' }
ChatPharoOllamaAgent class >> displayName [

	^ 'Ollama'
]

{ #category : 'api' }
ChatPharoOllamaAgent class >> isReachable [
	[
		ZnClient new get:
			'http://' , self defaultHost , ':' , self defaultPort
			, '/api/version' ]
		on: NetworkError
		do: [ ^ false ].
	^ true
]

{ #category : 'api' }
ChatPharoOllamaAgent class >> isValidModel: aModelName [ 

    self isReachable ifFalse: [ ^ false ].
    [
        ZnClient new
            url: 'http://' , self defaultHost , ':' , self defaultPort , '/api/show';
            entity: (ZnEntity with:
                                 (STONJSON toString: { (#model -> aModelName) } asDictionary));
            post;
            yourself.
        true
    ] on: ZnHttpUnsuccessful, NetworkError do: [ false ]
]

{ #category : 'api' }
ChatPharoOllamaAgent class >> modelNames [

	^ self models collect: [ :ollamaModel | ollamaModel at: 'name' ]
]

{ #category : 'api' }
ChatPharoOllamaAgent class >> models [
	| response |
	self isReachable ifFalse: [ ^ OrderedCollection empty ].
	response := ZnClient new get:
		            'http://' , self defaultHost , ':' , self defaultPort
		            , '/api/tags'.
	^ (STONJSON fromString: response) at: 'models'
]

{ #category : 'api' }
ChatPharoOllamaAgent class >> newSystem: synstemText promptPrefix: promptPrefixText [

	| prompter |
	prompter := self new.
	prompter systemPrompt: synstemText.
	prompter promptPrefix: promptPrefixText.
	^ prompter
]

{ #category : 'api' }
ChatPharoOllamaAgent class >> ollamaVersion [

	| response |
	response := ZnClient new get:
		            'http://' , self defaultHost , ':' , self defaultPort
		            , '/api/version'.
	^ (STONJSON fromString: response) at: 'version'
]

{ #category : 'api' }
ChatPharoOllamaAgent class >> pullModel: aModelName [

	self isReachable ifFalse: [
		^ self error: 'Ollama server not reachable' ].
	ZnClient new
		url:
			'http://' , self defaultHost , ':' , self defaultPort , '/api/pull';
		entity: (ZnEntity with:
					 (STONJSON toString: { (#name -> aModelName) } asDictionary));
		post;
		yourself
]

{ #category : 'api' }
ChatPharoOllamaAgent class >> settingsPresenterFor: anAgent [

	^ ChatPharoOllamaSettingsPresenter on: anAgent
]

{ #category : 'initialization' }
ChatPharoOllamaAgent >> getResponseForPrompt: prompt [

	| apiGenerateUrl jsonResponse requestDictionary |
	apiGenerateUrl := 'http://' , host , ':' , port , '/api/generate'.

	requestDictionary := Dictionary newFrom: {
			                     (#model -> model).
			                     (#systemPrompt -> self systemPrompt).
			                     (#prompt
			                      -> (String streamContents: [ :stream |
						                       stream nextPutAll: self promptPrefix.
						                       prompt ifNotNil: [
								                       stream
									                       nextPutAll: ' ';
									                       nextPutAll: prompt ] ])).
			                     (#stream -> false).
			                     (#options
			                      ->
			                      (Dictionary newFrom:
				                       { (#temperature -> temperature) })) }.

	jsonResponse := ZnClient new
		                url: apiGenerateUrl;
		                entity:
			                (ZnEntity with:
					                 (STONJSON toString: requestDictionary));
		                post;
		                contents.

	self response: ((STONJSON fromString: jsonResponse) at: 'response').
	^ self response contents
]

{ #category : 'accessing' }
ChatPharoOllamaAgent >> host [

	^ host
]

{ #category : 'accessing' }
ChatPharoOllamaAgent >> host: anObject [

	host := anObject
]

{ #category : 'initialization' }
ChatPharoOllamaAgent >> initialize [

	super initialize.
	host := self class defaultHost.
	port := self class defaultPort.
	temperature := 0.0.
	self model isNil ifTrue: [
	    | availableModels |
	    availableModels := self class modelNames.

	    availableModels isEmpty
		    ifFalse: [ self model: availableModels first ].
    ].

	self systemPrompt: ''.
	self promptPrefix: ''.
	packageName := ''
]

{ #category : 'initialization' }
ChatPharoOllamaAgent >> modelInformation [

	| url jsonResponse |
	url := 'http://' , host , ':' , port , '/api/show'.
	jsonResponse := ZnClient new
		                url: url;
		                entity: (ZnEntity with:
					                 (STONJSON toString:
							                  { (#model -> model) } asDictionary));
		                post;
		                contents.
	^ (STONJSON fromString: jsonResponse) at: 'contents'
]

{ #category : 'api' }
ChatPharoOllamaAgent >> modelNames [

	^ self class modelNames
]

{ #category : 'accessing' }
ChatPharoOllamaAgent >> packageName: aString [ 

        packageName := aString.
        self systemPrompt: (ChatPharoAgent defaultSystemPrompt
                copyReplaceAll: '{packageName}' with: packageName)
]

{ #category : 'accessing' }
ChatPharoOllamaAgent >> port [

	^ port
]

{ #category : 'accessing' }
ChatPharoOllamaAgent >> port: anObject [

	port := anObject
]

{ #category : 'accessing' }
ChatPharoOllamaAgent >> temperature [

	^ temperature
]

{ #category : 'accessing' }
ChatPharoOllamaAgent >> temperature: anObject [

	temperature := anObject
]

{ #category : 'accessing' }
ChatPharoOllamaAgent >> testConnection [

	^ [
		ZnClient new get: 'http://' , host , ':' , port , '/api/version'.
		true ]
		on: ZnHttpUnsuccessful , NetworkError
		do: [ false ]
]

{ #category : 'accessing' }
ChatPharoOllamaAgent >> tools [ 

    | available |
    available := ChatPharoBrowserEnvironment new tools.
    ^ available select: [ :tool |
        ChatPharoSettings default browserToolsEnabled includes: tool name ]
]
