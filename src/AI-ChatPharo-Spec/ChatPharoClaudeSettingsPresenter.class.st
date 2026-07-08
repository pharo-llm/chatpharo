"
Settings presenter for Claude (Anthropic) agent configuration.
"
Class {
	#name : 'ChatPharoClaudeSettingsPresenter',
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
ChatPharoClaudeSettingsPresenter >> apiKeyField [

	^ apiKeyField
]

{ #category : 'accessing' }
ChatPharoClaudeSettingsPresenter >> apiKeyField: anObject [

	apiKeyField := anObject
]

{ #category : 'accessing' }
ChatPharoClaudeSettingsPresenter >> defaultLayout [

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
ChatPharoClaudeSettingsPresenter >> hostField [

	^ hostField
]

{ #category : 'accessing' }
ChatPharoClaudeSettingsPresenter >> hostField: anObject [

	hostField := anObject
]

{ #category : 'accessing' }
ChatPharoClaudeSettingsPresenter >> initializePresenters [

	super initializePresenters.
	hostField := self newTextInput
		             placeholder: 'api.anthropic.com';
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
		                    placeholder: '0.7 (leave empty for default)';
		                    text: (model temperature ifNil: [ '' ] ifNotNil: [ model temperature asString ]);
		                    yourself.

	temperatureInput whenTextChangedDo: [ :text | self updateTemperatureFrom: text ].

	testButton := self newButton
		              label: 'Test Connection';
		              icon: (self iconNamed: #glamorousGo);
		              action: [ self testConnection ];
		              yourself
]

{ #category : 'accessing' }
ChatPharoClaudeSettingsPresenter >> model [

	^ model
]

{ #category : 'accessing' }
ChatPharoClaudeSettingsPresenter >> modelDrop [

	^ modelDrop
]

{ #category : 'accessing' }
ChatPharoClaudeSettingsPresenter >> modelDrop: anObject [

	modelDrop := anObject
]

{ #category : 'accessing' }
ChatPharoClaudeSettingsPresenter >> refreshModels [

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

{ #category : 'accessing' }
ChatPharoClaudeSettingsPresenter >> setModelBeforeInitialization: anAgent [

    model := anAgent
]

{ #category : 'accessing' }
ChatPharoClaudeSettingsPresenter >> temperatureInput [

	^ temperatureInput
]

{ #category : 'accessing' }
ChatPharoClaudeSettingsPresenter >> temperatureInput: anObject [

	temperatureInput := anObject
]

{ #category : 'accessing' }
ChatPharoClaudeSettingsPresenter >> testButton [

        ^ testButton
]

{ #category : 'accessing' }
ChatPharoClaudeSettingsPresenter >> testButton: anObject [

        testButton := anObject
]

{ #category : 'accessing' }
ChatPharoClaudeSettingsPresenter >> testConnection [

        (model testConnection)
                ifTrue: [ self inform: 'Connection successful.' ]
                ifFalse: [ self inform: 'Connection failed.' ]
]

{ #category : 'accessing' }
ChatPharoClaudeSettingsPresenter >> updateTemperatureFrom: text [

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
