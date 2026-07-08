"
not supported yet
"
Class {
	#name : 'ChatPharoMistralSettingsPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'hostField',
		'apiKeyField',
		'modelDrop',
		'model',
		'temperatureInput',
		'testButton',
		'maxTokensInput',
		'topPInput',
		'customParametersInput'
	],
	#category : 'AI-ChatPharo-Spec-Agent',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Agent'
}

{ #category : 'accessing' }
ChatPharoMistralSettingsPresenter >> apiKeyField [

	^ apiKeyField
]

{ #category : 'accessing' }
ChatPharoMistralSettingsPresenter >> apiKeyField: anObject [

	apiKeyField := anObject
]

{ #category : 'layout' }
ChatPharoMistralSettingsPresenter >> defaultLayout [

	| mainLayout hostRow keyRow modelRow tempRow maxTokensRow topPRow customParamsRow |
	hostRow := SpBoxLayout newHorizontal
		           spacing: 8;
		           add: (self newLabel label: 'Host') expand: false;
		           add: hostField expand: true;
		           yourself.

	keyRow := SpBoxLayout newHorizontal
		          spacing: 8;
		          add: (self newLabel label: 'API Key:') expand: false;
		          add: apiKeyField expand: true;
		          yourself.

	modelRow := SpBoxLayout newHorizontal
		            spacing: 8;
		            add: (self newLabel label: 'Model:') expand: false;
		            add: modelDrop expand: true;
		            yourself.

	tempRow := SpBoxLayout newHorizontal
		           spacing: 8;
		           add: (self newLabel label: 'Temperature (0.0 – 1.0):') expand: false;
		           add: temperatureInput expand: true;
		           yourself.
		
	maxTokensRow := SpBoxLayout newHorizontal
		           spacing: 8;
		           add: (self newLabel label: 'Max tokens (optional):') expand: false;
		           add: maxTokensInput expand: true;
		           yourself.

	topPRow := SpBoxLayout newHorizontal
		           spacing: 8;
		           add: (self newLabel label: 'Top P (0.0 – 1.0, optional):') expand: false;
		           add: topPInput expand: true;
		           yourself.

	customParamsRow := SpBoxLayout newHorizontal
		           spacing: 8;
		           add: (self newLabel label: 'Custom parameters (JSON):') expand: false;
		           add: customParametersInput expand: true;
		           yourself.

	mainLayout := SpBoxLayout newTopToBottom
		              spacing: 8;
		              borderWidth: 8;
		              beNotHomogeneous;
		              add: hostRow expand: false;
		              add: keyRow expand: false;
		              add: modelRow expand: false;
		              add: tempRow expand: false;
		 add: maxTokensRow expand: false;
		              add: topPRow expand: false;
		              add: customParamsRow expand: false;
		              add: testButton expand: false;
		              yourself.

	^ mainLayout
]

{ #category : 'accessing' }
ChatPharoMistralSettingsPresenter >> hostField [

	^ hostField
]

{ #category : 'accessing' }
ChatPharoMistralSettingsPresenter >> hostField: anObject [

	hostField := anObject
]

{ #category : 'initialization' }
ChatPharoMistralSettingsPresenter >> initializePresenters [

	super initializePresenters.
	hostField := self newTextInput
		             placeholder: 'api.mistral.ai';
		             text: model host.

	apiKeyField := self newTextInput bePassword
		               placeholder: 'API-KEY';
		               text: (model apiKey isEmpty
				                ifTrue: ''
				                ifFalse: (String new: model apiKey size withAll: $*)).

	modelDrop := SpDropListPresenter new.
	modelDrop whenSelectedItemChangedDo: [ :m | model model: m ].
	
	
	self refreshModels.
	hostField whenTextChangedDo: [ :t | model host: t ].
	apiKeyField whenTextChangedDo: [ :t |
			model apiKey: t.
			self refreshModels ].

	temperatureInput := self newTextInput
		                    placeholder: '0.0 (leave empty for default)';
		                    text: (model temperature ifNil: [ '' ] ifNotNil: [ model temperature asString ]);
		                    yourself.

	temperatureInput whenTextChangedDo: [ :text | self updateTemperatureFrom: text ].
	maxTokensInput := self newTextInput
		                  placeholder: 'e.g. 1024';
		                  text: (model maxTokens ifNil: [ '' ] ifNotNil: [ model maxTokens asString ]);
		                  yourself.
	maxTokensInput whenTextChangedDo: [ :text | self updateMaxTokensFrom: text ].

	topPInput := self newTextInput
		             placeholder: 'e.g. 0.9';
		             text: (model topP ifNil: [ '' ] ifNotNil: [ model topP asString ]);
		             yourself.
	topPInput whenTextChangedDo: [ :text | self updateTopPFrom: text ].

	customParametersInput := self newTextInput
		                         placeholder: '{"frequency_penalty":0.1}';
		                         text: (model customParameters isEmpty
				                          ifTrue: [ '' ]
				                          ifFalse: [ STONJSON toString: model customParameters ]);
		                         yourself.
	customParametersInput whenTextChangedDo: [ :text | self updateCustomParametersFrom: text ].

	testButton := self newButton
		              label: 'Test Connection';
		              icon: (self iconNamed: #glamorousGo);
		              action: [ self testConnection ];
		              yourself
]

{ #category : 'accessing' }
ChatPharoMistralSettingsPresenter >> model [

	^ model
]

{ #category : 'accessing' }
ChatPharoMistralSettingsPresenter >> modelDrop [

	^ modelDrop
]

{ #category : 'accessing' }
ChatPharoMistralSettingsPresenter >> modelDrop: anObject [

	modelDrop := anObject
]

{ #category : 'layout' }
ChatPharoMistralSettingsPresenter >> refreshModels [

	modelDrop
		items: model modelNames;
		display: [ :m | m ].
	    modelDrop items ifNotEmpty: [
        | selected |
        selected := modelDrop items
            detect: [:each | each = model model] ifNone: [ nil ].
        selected
            ifNotNil: [ modelDrop selectItem: selected ]
            ifNil: [ modelDrop selectFirst ]
    ]
]

{ #category : 'accessing - model' }
ChatPharoMistralSettingsPresenter >> setModelBeforeInitialization: anAgent [ 

    model := anAgent
]

{ #category : 'accessing' }
ChatPharoMistralSettingsPresenter >> temperatureInput [

	^ temperatureInput
]

{ #category : 'accessing' }
ChatPharoMistralSettingsPresenter >> temperatureInput: anObject [

	temperatureInput := anObject
]

{ #category : 'initialization' }
ChatPharoMistralSettingsPresenter >> testButton [ 

        ^ testButton

]

{ #category : 'initialization' }
ChatPharoMistralSettingsPresenter >> testButton: anObject [ 

        testButton := anObject
]

{ #category : 'initialization' }
ChatPharoMistralSettingsPresenter >> testConnection [ 

        (model testConnection)
                ifTrue: [ self inform: 'Connection successful.' ]
                ifFalse: [ self inform: 'Connection failed.' ]
]

{ #category : 'initialization' }
ChatPharoMistralSettingsPresenter >> updateCustomParametersFrom: text [

	| parsed trimmed |
	trimmed := (text ifNil: [ '' ]) asString trimBoth.
	trimmed isEmpty ifTrue: [
		model customParameters: Dictionary new.
		^ self
	].

	[ parsed := STONJSON fromString: trimmed ]
		on: Error do: [
			self inform: 'Custom parameters must be valid JSON.'.
			^ self
		].

	(parsed isDictionary)
		ifTrue: [ model customParameters: parsed ]
		ifFalse: [ self inform: 'Custom parameters must be a JSON object.' ]
]

{ #category : 'initialization' }
ChatPharoMistralSettingsPresenter >> updateMaxTokensFrom: text [

	| trimmed number |
	trimmed := (text ifNil: [ '' ]) asString trimBoth.
	trimmed isEmpty ifTrue: [
		model maxTokens: nil.
		^ self
	].

	[ number := Number readFrom: trimmed readStream ]
		on: Error do: [
			self inform: 'Max tokens must be a whole number.'.
			^ self
		].

	number isInteger
		ifFalse: [ self inform: 'Max tokens must be a whole number.' ]
		ifTrue: [ model maxTokens: number ]
]

{ #category : 'helper' }
ChatPharoMistralSettingsPresenter >> updateTemperatureFrom: text [

	| s num |
	s := (text ifNil: ['']) asString trimBoth.

	s isEmpty ifTrue: [
		model temperature: nil.
		^ self
	].

	[ num := Number readFrom: s readStream ]
		on: Error do: [
			self inform: 'Temperature must be a number between 0.0 and 1.0 (or leave empty).'.
			^ self
		].

	(num < 0.0 or: [ num > 1.0 ])
		ifTrue: [ self inform: 'Temperature must be between 0.0 and 1.0 (or leave empty).' ]
		ifFalse: [ model temperature: num asFloat ].
]

{ #category : 'initialization' }
ChatPharoMistralSettingsPresenter >> updateTopPFrom: text [

	| trimmed number |
	trimmed := (text ifNil: [ '' ]) asString trimBoth.
	trimmed isEmpty ifTrue: [
		model topP: nil.
		^ self
	].

	[ number := Number readFrom: trimmed readStream ]
		on: Error do: [
			self inform: 'Top P must be a number between 0.0 and 1.0.'.
			^ self
		].

	(number < 0.0 or: [ number > 1.0 ])
		ifTrue: [ self inform: 'Top P must be between 0.0 and 1.0.' ]
		ifFalse: [ model topP: number asFloat ]
]
