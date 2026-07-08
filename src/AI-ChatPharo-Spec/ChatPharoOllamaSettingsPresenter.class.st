"
Equivalent sub-panel for the Ollama agent: lists local models and lets the user refresh/re-select them.
"
Class {
	#name : 'ChatPharoOllamaSettingsPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'model',
		'modelsDrop',
		'refreshButton',
		'hostInput',
		'portInput',
		'temperatureInput',
		'suggestedModelsDrop',
		'installInput',
		'installButton',
		'deleteButton',
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
ChatPharoOllamaSettingsPresenter >> connectPresenters [

	modelsDrop whenSelectedItemChangedDo: [ :name | model model: name ].
	hostInput whenTextChangedDo: [ :text | model host: text ].
	portInput whenTextChangedDo: [ :text | model port: text ].
	temperatureInput whenTextChangedDo: [ :text |
			| num |
			num := 0.0.
			[ num := text asNumber ]
				on: Error
				do: [ :ex | num := model temperature ].
			model temperature: num ].
	
	maxTokensInput whenTextChangedDo: [ :text |
		self updateMaxTokensFrom: text ].
	topPInput whenTextChangedDo: [ :text |
		self updateTopPFrom: text ].
	customParametersInput whenTextChangedDo: [ :text |
		self updateCustomParametersFrom: text ].
]

{ #category : 'layout' }
ChatPharoOllamaSettingsPresenter >> defaultLayout [

	| mainLayout rowLayout modelRow hostRow portRow tempRow installRow maxTokensRow topPRow customParamsRow suggestedRow |
	modelRow := SpBoxLayout newHorizontal
		            spacing: 8;
		            add: (self newLabel label: 'Available models:') expand: false;
		            add: self modelsDrop expand: true;
		            add: self refreshButton expand: false;
		            yourself.
	suggestedRow := SpBoxLayout newHorizontal
		              spacing: 8;
		              add: (self newLabel label: 'Suggested models:')
		              expand: false;
		              add: suggestedModelsDrop expand: true;
		              yourself.

	installRow := SpBoxLayout newHorizontal
		              spacing: 8;
		              add: (self newLabel label: 'Pull model:') expand: false;
		              add: installInput expand: true;
		              add: installButton expand: false;
		              "add: deleteButton expand: false;"yourself.

	hostRow := SpBoxLayout newHorizontal
		           spacing: 8;
		           add: (self newLabel label: 'Host (e.g. localhost):') expand: false;
		           add: hostInput expand: true;
		           yourself.

	portRow := SpBoxLayout newHorizontal
		           spacing: 8;
		           add: (self newLabel label: 'Port (e.g. 11434):') expand: false;
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
		add: suggestedRow expand: false;
		              add: installRow expand: false;
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

{ #category : 'accessing' }
ChatPharoOllamaSettingsPresenter >> deleteButton [ 

        ^ deleteButton
]

{ #category : 'accessing' }
ChatPharoOllamaSettingsPresenter >> deleteButton: anObject [ 

        deleteButton := anObject
]

{ #category : 'initialization' }
ChatPharoOllamaSettingsPresenter >> initializePresenters [

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
		             placeholder: '11434';
		             text: model port;
		             yourself.

	temperatureInput := self newTextInput
		                    placeholder: '0.0';
		                    text: model temperature asString;
		                    yourself.
	suggestedModelsDrop := SpDropListPresenter new
		                       items: #( '' ) , model class suggestedModels;
		                       display: [ :name | name ifEmpty: [ '-- Select a model --' ] ifNotEmpty: [ name ] ];
		                       whenSelectedItemChangedDo: [ :name | name ifNotEmpty: [ installInput text: name ] ];
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
	installInput := self newTextInput
		                placeholder: 'model name (e.g. codellama:7b)';
		                yourself.

	installButton := self newButton
		                 label: 'Install';
		                 icon: (self iconNamed: #add);
		                 action: [
				                 ChatPharoModelPullProgressPresenter
					                 pullModel: installInput text
					                 onComplete: [ self refreshModels ]
					                 onError: [ :ex | self inform: 'Error pulling model: ' , ex messageText , '. Please verify the model name.' ] ];
		                 yourself.
	deleteButton := self newButton
		                label: 'Delete';
		                icon: (self iconNamed: #delete);
		                action: [
				                (model class isValidModel: installInput text)
					                ifTrue: [
							                model class deleteModel: installInput text.
							                self refreshModels ]
					                ifFalse: [ self inform: 'Model ' , installInput text , ' not found.' ] ];
		                yourself.
	testButton := self newButton
		              label: 'Test Connection';
		              icon: (self iconNamed: #glamorousGo);
		              action: [ self testConnection ];
		              yourself
]

{ #category : 'accessing' }
ChatPharoOllamaSettingsPresenter >> installButton [

	^ installButton
]

{ #category : 'accessing' }
ChatPharoOllamaSettingsPresenter >> installButton: anObject [

	installButton := anObject
]

{ #category : 'accessing' }
ChatPharoOllamaSettingsPresenter >> installInput [

	^ installInput
]

{ #category : 'accessing' }
ChatPharoOllamaSettingsPresenter >> installInput: anObject [

	installInput := anObject
]

{ #category : 'accessing' }
ChatPharoOllamaSettingsPresenter >> model [

	^ model
]

{ #category : 'accessing' }
ChatPharoOllamaSettingsPresenter >> modelsDrop [

	^ modelsDrop
]

{ #category : 'accessing' }
ChatPharoOllamaSettingsPresenter >> modelsDrop: anObject [

	modelsDrop := anObject
]

{ #category : 'accessing' }
ChatPharoOllamaSettingsPresenter >> refreshButton [

	^ refreshButton
]

{ #category : 'accessing' }
ChatPharoOllamaSettingsPresenter >> refreshButton: anObject [

	refreshButton := anObject
]

{ #category : 'initialization' }
ChatPharoOllamaSettingsPresenter >> refreshModels [ 


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

{ #category : 'accessing - model' }
ChatPharoOllamaSettingsPresenter >> setModelBeforeInitialization: anAgent [
	model := anAgent
]

{ #category : 'initialization' }
ChatPharoOllamaSettingsPresenter >> suggestedModelsDrop [

	^ suggestedModelsDrop
]

{ #category : 'initialization' }
ChatPharoOllamaSettingsPresenter >> suggestedModelsDrop: anObject [

	suggestedModelsDrop := anObject
]

{ #category : 'layout' }
ChatPharoOllamaSettingsPresenter >> testButton [ 

        ^ testButton
]

{ #category : 'layout' }
ChatPharoOllamaSettingsPresenter >> testButton: anObject [ 

        testButton := anObject
]

{ #category : 'initialization' }
ChatPharoOllamaSettingsPresenter >> testConnection [ 

        (model testConnection)
                ifTrue: [ self inform: 'Connection successful.' ]
                ifFalse: [ self inform: 'Connection failed.' ]
]

{ #category : 'initialization' }
ChatPharoOllamaSettingsPresenter >> updateCustomParametersFrom: text [

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
ChatPharoOllamaSettingsPresenter >> updateMaxTokensFrom: text [

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
ChatPharoOllamaSettingsPresenter >> updateTopPFrom: text [

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
