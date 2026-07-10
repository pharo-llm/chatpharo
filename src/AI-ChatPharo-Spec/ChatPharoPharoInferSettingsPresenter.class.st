"
Settings panel for the PharoInfer local agent.
"
Class {
	#name : 'ChatPharoPharoInferSettingsPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'model',
		'modelsDrop',
		'refreshButton',
		'importButton',
		'prepareButton',
		'statusLabel',
		'temperatureInput',
		'maxTokensInput',
		'topPInput',
		'onSettingsChanged'
	],
	#category : 'AI-ChatPharo-Spec-Agent',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Agent'
}

{ #category : 'initialization' }
ChatPharoPharoInferSettingsPresenter >> connectPresenters [

	modelsDrop whenSelectedItemChangedDo: [ :name |
		name ifNotNil: [
			model model: name.
			self notifySettingsChanged ] ].
	temperatureInput whenTextChangedDo: [ :text |
		self updateTemperatureFrom: text ].
	maxTokensInput whenTextChangedDo: [ :text |
		self updateMaxTokensFrom: text ].
	topPInput whenTextChangedDo: [ :text |
		self updateTopPFrom: text ]
]

{ #category : 'layout' }
ChatPharoPharoInferSettingsPresenter >> defaultLayout [

	| runtimeRow modelRow temperatureRow maxTokensRow topPRow |
	runtimeRow := SpBoxLayout newHorizontal
		              spacing: 8;
		              add: statusLabel expand: true;
		              add: prepareButton expand: false;
		              yourself.
	modelRow := SpBoxLayout newHorizontal
		            spacing: 8;
		            add: (self newLabel label: 'Available GGUF models:') expand: false;
		            add: modelsDrop expand: true;
		            add: refreshButton expand: false;
		            add: importButton expand: false;
		            yourself.
	temperatureRow := SpBoxLayout newHorizontal
		                  spacing: 8;
		                  add: (self newLabel label: 'Temperature (0.0 - 1.0):') expand: false;
		                  add: temperatureInput expand: true;
		                  yourself.
	maxTokensRow := SpBoxLayout newHorizontal
		                spacing: 8;
		                add: (self newLabel label: 'Max tokens (optional):') expand: false;
		                add: maxTokensInput expand: true;
		                yourself.
	topPRow := SpBoxLayout newHorizontal
		           spacing: 8;
		           add: (self newLabel label: 'Top P (optional):') expand: false;
		           add: topPInput expand: true;
		           yourself.

	^ SpBoxLayout newTopToBottom
		  spacing: 8;
		  borderWidth: 8;
		  beNotHomogeneous;
		  add: runtimeRow expand: false;
		  add: modelRow expand: false;
		  add: temperatureRow expand: false;
		  add: maxTokensRow expand: false;
		  add: topPRow expand: false;
		  yourself
]

{ #category : 'initialization' }
ChatPharoPharoInferSettingsPresenter >> initializePresenters [

	super initializePresenters.
	statusLabel := self newLabel
		               label: ChatPharoPharoInferRuntime statusText;
		               yourself.
	modelsDrop := SpDropListPresenter new.
	refreshButton := self newButton
		                 label: 'Refresh';
		                 icon: (self iconNamed: #refresh);
		                 action: [ self refreshModels ];
		                 yourself.
	importButton := self newButton
		                label: 'Import GGUF';
		                icon: (self iconNamed: #smallOpen);
		                action: [ self importModel ];
		                yourself.
	prepareButton := self newButton
		                 label: 'Prepare Runtime';
		                 icon: (self iconNamed: #glamorousGo);
		                 action: [ self prepareRuntime ];
		                 yourself.
	temperatureInput := self newTextInput
		                    placeholder: '0.7';
		                    text: model temperature asString;
		                    yourself.
	maxTokensInput := self newTextInput
		                  placeholder: 'e.g. 512';
		                  text: (model maxTokens
				                   ifNil: [ '' ]
				                   ifNotNil: [ model maxTokens asString ]);
		                  yourself.
	topPInput := self newTextInput
		             placeholder: 'e.g. 0.9';
		             text: (model topP
				              ifNil: [ '' ]
				              ifNotNil: [ model topP asString ]);
		             yourself.
	self refreshModels
]

{ #category : 'actions' }
ChatPharoPharoInferSettingsPresenter >> copyModelFile: sourceFile to: targetFile [

	targetFile parent ensureCreateDirectory.
	sourceFile fullName = targetFile fullName ifTrue: [ ^ targetFile ].
	targetFile exists ifTrue: [ targetFile deleteIfAbsent: [ ] ].
	sourceFile copyTo: targetFile.
	^ targetFile
]

{ #category : 'actions' }
ChatPharoPharoInferSettingsPresenter >> importModel [

	| selected targetFile |
	selected := UIManager default
		            chooseExistingFileReference: 'Import GGUF model'
		            extensions: #( 'gguf' )
		            path: FileLocator home / 'Desktop'.
	selected ifNil: [ ^ self ].
	(selected basename asLowercase endsWith: '.gguf') ifFalse: [
		^ self inform: 'Please select a .gguf model file.' ].

	targetFile := model class modelsDirectory / selected basename.
	(targetFile exists and: [ selected fullName ~= targetFile fullName ]) ifTrue: [
		(self confirm: 'Replace existing model "' , targetFile basename , '"?')
			ifFalse: [ ^ self ] ].

	self importModel: selected to: targetFile
]

{ #category : 'actions' }
ChatPharoPharoInferSettingsPresenter >> importModel: sourceFile to: targetFile [

	statusLabel label: 'Importing model: ' , sourceFile basename.
	[
		[
			| imported modelName |
			imported := self copyModelFile: sourceFile to: targetFile.
			modelName := imported basenameWithoutExtension.
			self defer: [
				self refreshModels.
				model model: modelName.
				modelsDrop selectItem: modelName.
				statusLabel label: 'Imported model: ' , imported basename.
				self notifySettingsChanged.
				self inform: 'Model imported.' ] ]
			on: Error
			do: [ :ex |
				self defer: [
					statusLabel label: 'Model import failed.'.
					self inform: 'Failed to import model: ' , ex messageText ] ] ] fork
]

{ #category : 'accessing' }
ChatPharoPharoInferSettingsPresenter >> model [

	^ model
]

{ #category : 'initialization' }
ChatPharoPharoInferSettingsPresenter >> notifySettingsChanged [

	onSettingsChanged ifNotNil: [ :block | block value ]
]

{ #category : 'actions' }
ChatPharoPharoInferSettingsPresenter >> prepareRuntime [

	ChatPharoPharoInferReadinessPresenter openAndPrepareThen: [
		self refreshStatus.
		self refreshModels.
		self notifySettingsChanged ]
]

{ #category : 'actions' }
ChatPharoPharoInferSettingsPresenter >> refreshModels [

	| availableModels currentModel |
	availableModels := model class modelNames.
	currentModel := model model.
	modelsDrop
		items: availableModels;
		display: [ :eachModelName | eachModelName ].
	availableModels isEmpty ifFalse: [
		(currentModel isNil or: [ (availableModels includes: currentModel) not ])
			ifTrue: [
				model model: availableModels first.
				modelsDrop selectFirst.
				self notifySettingsChanged ]
			ifFalse: [ modelsDrop selectItem: currentModel ] ].
	self refreshStatus
]

{ #category : 'actions' }
ChatPharoPharoInferSettingsPresenter >> refreshStatus [

	statusLabel label: ChatPharoPharoInferRuntime statusText
]

{ #category : 'initialization' }
ChatPharoPharoInferSettingsPresenter >> setModelBeforeInitialization: anAgent [

	model := anAgent
]

{ #category : 'updating' }
ChatPharoPharoInferSettingsPresenter >> updateMaxTokensFrom: text [

	| trimmed |
	trimmed := (text ifNil: [ '' ]) asString trimBoth.
	trimmed isEmpty ifTrue: [
		model maxTokens: nil.
		self notifySettingsChanged.
		^ self ].
	[
		model maxTokens: trimmed asNumber asInteger.
		self notifySettingsChanged ]
		on: Error
		do: [ :ex | model maxTokens: nil ]
]

{ #category : 'updating' }
ChatPharoPharoInferSettingsPresenter >> updateTemperatureFrom: text [

	| number |
	number := model temperature.
	[ number := text asNumber ] on: Error do: [ :ex | ^ self ].
	model temperature: number.
	self notifySettingsChanged
]

{ #category : 'updating' }
ChatPharoPharoInferSettingsPresenter >> updateTopPFrom: text [

	| trimmed |
	trimmed := (text ifNil: [ '' ]) asString trimBoth.
	trimmed isEmpty ifTrue: [
		model topP: nil.
		self notifySettingsChanged.
		^ self ].
	[
		model topP: trimmed asNumber.
		self notifySettingsChanged ]
		on: Error
		do: [ :ex | model topP: nil ]
]
