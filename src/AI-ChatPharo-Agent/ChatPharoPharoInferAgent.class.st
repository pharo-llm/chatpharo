"
Concrete agent for PharoInfer local inference.
"
Class {
	#name : 'ChatPharoPharoInferAgent',
	#superclass : 'ChatPharoAgent',
	#instVars : [
		'temperature'
	],
	#category : 'AI-ChatPharo-Agent',
	#package : 'AI-ChatPharo-Agent'
}

{ #category : 'api' }
ChatPharoPharoInferAgent class >> displayName [

	^ 'PharoInfer'
]

{ #category : 'models' }
ChatPharoPharoInferAgent class >> discoverModels [

	| managerClass manager |
	managerClass := Smalltalk at: #AIModelManager ifAbsent: [ ^ OrderedCollection new ].
	manager := managerClass default.
	^ [ 
	  manager discoverModelsInDirectory: self modelsDirectory.
	  manager allModels asOrderedCollection ]
		  on: Error
		  do: [ OrderedCollection new ]
]

{ #category : 'api' }
ChatPharoPharoInferAgent class >> isExternalApi [

	^ false
]

{ #category : 'api' }
ChatPharoPharoInferAgent class >> isReachable [

	^ (Smalltalk at: #AIInferenceEngine ifAbsent: [ nil ]) notNil
	  and: [ ChatPharoPharoInferRuntime isReady ]
]

{ #category : 'models' }
ChatPharoPharoInferAgent class >> modelNames [

	| names |
	names := self discoverModels collect: [ :model | model name ].
	^ names asSortedCollection asArray
]

{ #category : 'models' }
ChatPharoPharoInferAgent class >> modelsDirectory [

	| configClass |
	configClass := Smalltalk at: #AIInferenceConfig ifAbsent: [ nil ].
	configClass ifNil: [ ^ FileLocator home / 'pharo-models' ].
	^ configClass default modelsDirectory
]

{ #category : 'api' }
ChatPharoPharoInferAgent class >> settingsPresenterFor: anAgent [

	^ ChatPharoPharoInferSettingsPresenter on: anAgent
]

{ #category : 'accessing' }
ChatPharoPharoInferAgent >> configurationErrorMessage [

	ChatPharoPharoInferRuntime isReady ifFalse: [
		^ ChatPharoPharoInferRuntime statusText ].
	^ 'Select a local GGUF model from ' , self class modelsDirectory fullName , '.'
]

{ #category : 'generation' }
ChatPharoPharoInferAgent >> generationOptions [

	| optionsClass options |
	optionsClass := Smalltalk at: #AIGenerationOptions ifAbsent: [
		                self error: 'PharoInfer generation options are not loaded.' ].
	options := optionsClass default.
	temperature ifNotNil: [ options temperature: temperature ].
	self maxTokens ifNotNil: [ :value | options maxTokens: value ].
	self topP ifNotNil: [ :value | options topP: value ].
	^ options
]

{ #category : 'initialization' }
ChatPharoPharoInferAgent >> getResponseForPrompt: userPrompt [

	| engineClass modelName answer |
	ChatPharoPharoInferRuntime ensureReady ifFalse: [
		self error: ChatPharoPharoInferRuntime statusText ].
	(self model isNil or: [ self model isEmpty ]) ifTrue: [
		self error: 'Select a PharoInfer model before sending a prompt.' ].

	modelName := self resolvedModelName.
	engineClass := Smalltalk at: #AIInferenceEngine ifAbsent: [
		               self error: 'PharoInfer inference engine is not loaded.' ].
	answer := engineClass default
		          complete: (self promptFor: userPrompt)
		          model: modelName
		          options: self generationOptions.
	self response: answer.
	^ answer
]

{ #category : 'initialization' }
ChatPharoPharoInferAgent >> initialize [

	super initialize.
	temperature := 0.7.
	self model ifEmpty: [
		self class modelNames ifNotEmpty: [ :models | self model: models first ] ]
]

{ #category : 'accessing' }
ChatPharoPharoInferAgent >> isConfigured [

	^ ChatPharoPharoInferRuntime isReady
	  and: [ self model notNil and: [ self model notEmpty ] ]
]

{ #category : 'accessing' }
ChatPharoPharoInferAgent >> modelInformation [

	self model ifNil: [ ^ 'No PharoInfer model selected.' ].
	self model isEmpty ifTrue: [ ^ 'No PharoInfer model selected.' ].
	^ 'PharoInfer model: ' , self model
]

{ #category : 'private' }
ChatPharoPharoInferAgent >> promptFor: userPrompt [

	^ String streamContents: [ :stream |
		  self systemPrompt ifNotEmpty: [
			  stream
				  nextPutAll: 'system: ';
				  nextPutAll: self systemPrompt;
				  cr ].
		  self promptPrefix ifNotEmpty: [
			  stream nextPutAll: self promptPrefix.
			  stream cr ].
		  (self promptPrefix includesSubstring: userPrompt) ifFalse: [
			  stream
				  nextPutAll: 'user: ';
				  nextPutAll: userPrompt;
				  cr ].
		  stream nextPutAll: 'assistant: ' ]
]

{ #category : 'private' }
ChatPharoPharoInferAgent >> resolvedModelName [

	| managerClass manager registered loaded |
	managerClass := Smalltalk at: #AIModelManager ifAbsent: [
		                self error: 'PharoInfer model manager is not loaded.' ].
	manager := managerClass default.
	manager discoverModelsInDirectory: self class modelsDirectory.

	registered := manager modelNamed: self model.
	registered ifNotNil: [ ^ registered name ].

	self model asFileReference exists ifFalse: [
		self error: 'Model not found: ' , self model ].
	loaded := manager loadModel: self model.
	^ loaded name
]

{ #category : 'tools support' }
ChatPharoPharoInferAgent >> supportsToolCalling [

	^ false
]

{ #category : 'accessing' }
ChatPharoPharoInferAgent >> temperature [

	^ temperature
]

{ #category : 'accessing' }
ChatPharoPharoInferAgent >> temperature: aNumber [

	temperature := aNumber
]

{ #category : 'accessing' }
ChatPharoPharoInferAgent >> testConnection [

	^ self class isReachable
]
