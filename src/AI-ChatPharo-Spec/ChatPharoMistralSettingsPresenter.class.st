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
		'testButton'
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

	| mainLayout hostRow keyRow modelRow tempRow |
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

	mainLayout := SpBoxLayout newTopToBottom
		              spacing: 8;
		              borderWidth: 8;
		              beNotHomogeneous;
		              add: hostRow expand: false;
		              add: keyRow expand: false;
		              add: modelRow expand: false;
		              add: tempRow expand: false;
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
	hostField := self newTextInput placeholder: 'api.mistral.ai';
	text: model host.
	apiKeyField := self newTextInput placeholder: 'API-KEY'.
	modelDrop := SpDropListPresenter new.
	self refreshModels.
	hostField whenTextChangedDo: [ :t | model host: t ].
	apiKeyField whenTextChangedDo: [ :t |
			model apiKey: t.
			self refreshModels ].
	modelDrop whenSelectedItemChangedDo: [ :m | model model: m ].
	temperatureInput := self newTextInput
		                    placeholder: '0.0';
		                    text: model temperature asString;
		                    yourself.
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

{ #category : 'layout' }
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
