"
Settings presenter for the LM Studio agent.
Allows configuration of host, port, model selection, and generation parameters.
"
Class {
	#name : 'ChatPharoLMStudioSettingsPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'model',
		'modelsDrop',
		'refreshButton',
		'hostInput',
		'portInput',
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

{ #category : 'initialization' }
ChatPharoLMStudioSettingsPresenter >> connectPresenters [

	hostInput whenTextChangedDo: [ :text | model host: text ].
	portInput whenTextChangedDo: [ :text | model port: text ].
	temperatureInput whenTextChangedDo: [ :text |
			| num |
			num := 0.0.
			[ num := text asNumber ]
				on: Error
				do: [ :ex | num := model temperature ].
			model temperature: num ].

	maxTokensInput whenTextChangedDo: [ :text | self updateMaxTokensFrom: text ].
	topPInput whenTextChangedDo: [ :text | self updateTopPFrom: text ].
	customParametersInput whenTextChangedDo: [ :text | self updateCustomParametersFrom: text ]
]

{ #category : 'initialization' }
ChatPharoLMStudioSettingsPresenter >> defaultLayout [

	| mainLayout rowLayout modelRow hostRow portRow tempRow maxTokensRow topPRow customParamsRow |
	modelRow := SpBoxLayout newHorizontal
		            spacing: 8;
		            add: (self newLabel label: 'Available models:') expand: false;
		            add: self modelsDrop expand: true;
		            add: self refreshButton expand: false;
		            yourself.

	hostRow := SpBoxLayout newHorizontal
		           spacing: 8;
		           add: (self newLabel label: 'Host (e.g. localhost):') expand: false;
		           add: hostInput expand: true;
		           yourself.

	portRow := SpBoxLayout newHorizontal
		           spacing: 8;
		           add: (self newLabel label: 'Port (e.g. 1234):') expand: false;
		           add: portInput expand: true;
		           yourself.

	tempRow := SpBoxLayout newHorizontal
		           spacing: 8;
		           add: (self newLabel label: 'Temperature (0.0 – 1.0):') expand: false;
		           add: temperatureInput expand: true;
		           yourself.

	maxTokensRow := SpBoxLayout newHorizontal
		           spacing: 8;
		           add: (self newLabel label: 'Max tokens (optional):')
		           expand: false;
		           add: maxTokensInput expand: true;
		           yourself.

	topPRow := SpBoxLayout newHorizontal
		           spacing: 8;
		           add: (self newLabel label: 'Top P (0.0 – 1.0, optional):')
		           expand: false;
		           add: topPInput expand: true;
		           yourself.

	customParamsRow := SpBoxLayout newHorizontal
		           spacing: 8;
		           add: (self newLabel label: 'Custom parameters (JSON):')
		           expand: false;
		           add: customParametersInput expand: true;
		           yourself.

	mainLayout := SpBoxLayout newTopToBottom
		              spacing: 8;
		              borderWidth: 8;
		              beNotHomogeneous;
		              add: modelRow expand: false;
		              add: hostRow expand: false;
		              add: portRow expand: false;
		              add: tempRow expand: false;
		              add: maxTokensRow expand: false;
		              add: topPRow expand: false;
		              add: customParamsRow expand: false;
		              add: testButton expand: false;
		              yourself.

	^ mainLayout
]

{ #category : 'initialization' }
ChatPharoLMStudioSettingsPresenter >> initializePresenters [

	super initializePresenters.

	modelsDrop := SpDropListPresenter new.
	modelsDrop whenSelectedItemChangedDo: [ :m | model model: m ].
	refreshButton := self newButton
		                 label: 'Refresh';
		                 icon: (self iconNamed: #refresh);
		                 action: [ self refreshModels ].
	self refreshModels.
	hostInput := self newTextInput
		             placeholder: 'localhost';
		             text: model host;
		             yourself.

	portInput := self newTextInput
		             placeholder: '1234';
		             text: model port;
		             yourself.

	temperatureInput := self newTextInput
		                    placeholder: '0.7';
		                    text: model temperature asString;
		                    yourself.

	maxTokensInput := self newTextInput
		                  placeholder: 'e.g. 1024';
		                  text: (model maxTokens ifNil: [ '' ] ifNotNil: [ model maxTokens asString ]);
		                  yourself.

	topPInput := self newTextInput
		             placeholder: 'e.g. 0.9';
		             text: (model topP ifNil: [ '' ] ifNotNil: [ model topP asString ]);
		             yourself.

	customParametersInput := self newTextInput
		                         placeholder: '{"frequency_penalty":0.1}';
		                         text: (model customParameters isEmpty
				                          ifTrue: [ '' ]
				                          ifFalse: [ STONJSON toString: model customParameters ]);
		                         yourself.

	testButton := self newButton
		              label: 'Test Connection';
		              icon: (self iconNamed: #glamorousGo);
		              action: [ self testConnection ];
		              yourself
]

{ #category : 'initialization' }
ChatPharoLMStudioSettingsPresenter >> model [

	^ model
]

{ #category : 'initialization' }
ChatPharoLMStudioSettingsPresenter >> modelsDrop [

	^ modelsDrop
]

{ #category : 'initialization' }
ChatPharoLMStudioSettingsPresenter >> modelsDrop: anObject [

	modelsDrop := anObject
]

{ #category : 'initialization' }
ChatPharoLMStudioSettingsPresenter >> refreshButton [

	^ refreshButton
]

{ #category : 'initialization' }
ChatPharoLMStudioSettingsPresenter >> refreshButton: anObject [

	refreshButton := anObject
]

{ #category : 'initialization' }
ChatPharoLMStudioSettingsPresenter >> refreshModels [

    | availableModels currentModel |
    availableModels := model class modelNames.
    currentModel := model model.

    modelsDrop
        items: availableModels;
        display: [:eachModelName | eachModelName ].

    (availableModels isEmpty)
        ifFalse: [
            (currentModel isNil or: [ (availableModels includes: currentModel) not ])
                ifTrue: [ modelsDrop selectFirst ]
 ifFalse: [ modelsDrop selectItem: currentModel ].
        ].
]

{ #category : 'initialization' }
ChatPharoLMStudioSettingsPresenter >> setModelBeforeInitialization: anAgent [

	model := anAgent
]

{ #category : 'initialization' }
ChatPharoLMStudioSettingsPresenter >> testButton [

        ^ testButton
]

{ #category : 'initialization' }
ChatPharoLMStudioSettingsPresenter >> testButton: anObject [

        testButton := anObject
]

{ #category : 'initialization' }
ChatPharoLMStudioSettingsPresenter >> testConnection [

        (model testConnection)
                ifTrue: [ self inform: 'Connection successful.' ]
                ifFalse: [ self inform: 'Connection failed.' ]
]

{ #category : 'initialization' }
ChatPharoLMStudioSettingsPresenter >> updateCustomParametersFrom: text [

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
ChatPharoLMStudioSettingsPresenter >> updateMaxTokensFrom: text [

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

{ #category : 'initialization' }
ChatPharoLMStudioSettingsPresenter >> updateTopPFrom: text [

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
