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

{ #category : 'api' }
ChatPharoOllamaAgent class >> autoConfigured [
	"Answer an agent on the best installed model with the other tool-capable models as fallbacks,
	 starting the Ollama server when needed. Answer nil when Ollama is unavailable or has no model yet."

	| names |
	self runtime ensureRunning ifFalse: [ ^ nil ].
	names := self preferredModelNames.
	names ifEmpty: [ ^ nil ].
	^ self new
		  model: names first;
		  fallbackModels: names allButFirst;
		  yourself
]

{ #category : 'initialization' }
ChatPharoOllamaAgent class >> defaultHost [ 

    ^ 'localhost'
]

{ #category : 'api' }
ChatPharoOllamaAgent class >> defaultModelToPull [
	"A small model that calls tools and exposes its reasoning: a sensible first download."

	^ 'qwen3:4b'
]

{ #category : 'initialization' }
ChatPharoOllamaAgent class >> defaultPort [ 

    ^ '11434'
]

{ #category : 'api' }
ChatPharoOllamaAgent class >> deleteModel: aModelName [

	self isReachable ifFalse: [
		^ self error: 'Ollama server not reachable' ].
	self validateModel: aModelName.

	^ [
		  ZnClient new
			  url:
				  'http://' , self defaultHost , ':' , self defaultPort
				  , '/api/delete';
			  entity: (ZnEntity with:
						   (STONJSON toString: { (#model -> aModelName) } asDictionary));
			  contentType: 'application/json';
			  delete;
			  yourself.
		  true ]
		  on: ZnHttpUnsuccessful , NetworkError
		  do: [ false ]
]

{ #category : 'api' }
ChatPharoOllamaAgent class >> displayName [

	^ 'Ollama'
]

{ #category : 'api' }
ChatPharoOllamaAgent class >> isExternalApi [

	^ false
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
    ^ [
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
ChatPharoOllamaAgent class >> preferredModelNames [
	"Installed models, those able to call tools first. Recent Ollama versions list the capabilities
	 of each model; for older ones every model is kept."

	| installed capable |
	installed := self models.
	capable := installed select: [ :each | (each at: 'capabilities' ifAbsent: [ #( 'tools' ) ]) includes: 'tools' ].
	^ (capable , (installed reject: [ :each | capable includes: each ])) collect: [ :each | each at: 'name' ]
]

{ #category : 'api' }
ChatPharoOllamaAgent class >> pullModel: aModelName [

	self isReachable ifFalse: [
		^ self error: 'Ollama server not reachable' ].

	^ [
		  ZnClient new
			  url:
				  'http://' , self defaultHost , ':' , self defaultPort
				  , '/api/pull';
			  entity: (ZnEntity with:
						   (STONJSON toString: { (#name -> aModelName) } asDictionary));
						timeout: 3600;
			  post;
			  yourself ]
		  on: ZnHttpUnsuccessful , NetworkError
		  do: [ :ex |
				  ^ self error: 'Error pulling model: ' , ex messageText
					    , '. Please verify the model name.' ]
]

{ #category : 'api' }
ChatPharoOllamaAgent class >> runtime [
	"The local program that serves my models."

	^ ChatPharoOllamaRuntime new
]

{ #category : 'api' }
ChatPharoOllamaAgent class >> settingsPresenterFor: anAgent [

	^ ChatPharoOllamaSettingsPresenter on: anAgent
]

{ #category : 'api' }
ChatPharoOllamaAgent class >> suggestedModels [
	"Models worth pulling: they call tools, and the qwen3 and deepseek-r1 families also expose their reasoning."

	^ #( 'qwen3:4b' 'qwen3:8b' 'qwen3-coder:30b' 'qwen2.5-coder:7b' 'llama3.2:3b' 'llama3.1:8b' 'mistral-nemo:12b' 'deepseek-r1:8b'
	     'gemma3:4b' 'granite3.3:8b' 'devstral:24b' 'gpt-oss:20b' )
]

{ #category : 'api' }
ChatPharoOllamaAgent class >> validateModel: aModelName [

    (self isValidModel: aModelName) ifFalse: [
        ^ self error: 'Invalid model name or model does not exist on Ollama server' ].
]

{ #category : 'accessing' }
ChatPharoOllamaAgent >> configurationErrorMessage [

	^ 'Please complete all required fields.'
]

{ #category : 'private - conversation' }
ChatPharoOllamaAgent >> ensureBackendReady [
	"Start the local server when it is installed but not running, so the user does not have to."

	ChatPharoSettings default autoStartLocalRuntimes ifFalse: [ ^ self ].
	self class runtime ensureRunning
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
ChatPharoOllamaAgent >> isConfigured [

	^ host notEmpty and: [ port notEmpty and: [ model notNil and: [ model notEmpty ] ] ]
]

{ #category : 'tools support' }
ChatPharoOllamaAgent >> modelDetailsForToolSupport [
	"Fetch model details from Ollama API to check for tool support.
	Returns a dictionary with model info or nil on error."

	| url |
	model ifEmpty: [ ^ nil ].
	self class isReachable ifFalse: [ ^ nil ].
	url := 'http://' , host , ':' , port , '/api/show'.
	^ [
	  | response |
	  response := ZnClient new
		              url: url;
		              entity: (ZnEntity with:
					               (STONJSON toString:
							                { (#model -> model) } asDictionary));
		              post;
		              contents.
	  STONJSON fromString: response ]
		  on: Error
		  do: [ nil ]
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

{ #category : 'private - conversation' }
ChatPharoOllamaAgent >> newCompletionClient [

	^ ChatPharoTool
		  baseURL: (ZnUrl fromString: 'http://' , host , ':' , port , '/v1')
		  system: self systemPrompt
		  tools: self tools
]

{ #category : 'accessing' }
ChatPharoOllamaAgent >> packageName: aString [ 
packageName := aString.
	self systemPrompt: (self browserSystemPrompt
			 copyReplaceAll: '{packageName}'
			 with: packageName)
]

{ #category : 'accessing' }
ChatPharoOllamaAgent >> port [

	^ port
]

{ #category : 'accessing' }
ChatPharoOllamaAgent >> port: anObject [

	port := anObject
]

{ #category : 'tools support' }
ChatPharoOllamaAgent >> supportsToolCalling [
	"Check if the current Ollama model supports tool calling.
	Uses model details from /api/show endpoint to detect capabilities.
	Falls back to checking known model families that support tools."

	| details family modelNameLower toolSupportingFamilies |
	model ifEmpty: [ ^ false ]. "Try to get model details from API"
	details := self modelDetailsForToolSupport.
	details ifNil: [ ^ false ]. "Check if details contains explicit capabilities (newer Ollama versions)"
	(details includesKey: 'capabilities') ifTrue: [
			| capabilities |
			capabilities := details at: 'capabilities'.
			(capabilities isCollection and: [ capabilities includes: 'tools' ]) ifTrue: [ ^ true ] ]. "Fall back to checking model family from details"
	(details includesKey: 'details') ifTrue: [
			| modelDetails |
			modelDetails := details at: 'details'.
			(modelDetails includesKey: 'family') ifTrue: [
					family := (modelDetails at: 'family') asLowercase.
					toolSupportingFamilies := #( 'qwen2' 'qwen' 'mistral' 'mixtral' 'command-r' 'hermes' 'firefunction' ).
					(toolSupportingFamilies anySatisfy: [ :f | family includesSubstring: f ]) ifTrue: [ ^ true ]. "llama family supports tools, but codellama does not"
					(family includesSubstring: 'llama') ifTrue: [ (family includesSubstring: 'codellama') ifFalse: [ ^ true ] ] ] ]. "Last resort: check model name pattern for known tool-capable models"
	modelNameLower := model asLowercase.
	(#( 'llama3.1' 'llama3.2' 'llama3.3' 'qwen2' 'qwen2.5' 'mistral-nemo' 'mistral-small' 'mistral-large' 'mixtral' 'command-r'
	    'hermes3' 'firefunction' 'smollm2' 'athene' 'aya-expanse' ) anySatisfy: [ :pattern |
		 modelNameLower includesSubstring: pattern ]) ifTrue: [ ^ true ]. "Default: assume no tool support for unknown models"
	^ false
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
