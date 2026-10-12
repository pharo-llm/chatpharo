"
I let the user decide what ChatPharo tells the model before each request, and I
show the exact text that is sent — nothing reaches the model that the user
cannot read here first.
"
Class {
	#name : 'ChatPharoContextSettingsPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'settings',
		'environmentCheckBox',
		'projectCheckBox',
		'sessionCheckBox',
		'previewText'
	],
	#category : 'AI-ChatPharo-Spec-Extentions',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Extentions'
}

{ #category : 'initialization' }
ChatPharoContextSettingsPresenter >> connectPresenters [

	environmentCheckBox whenChangedDo: [ :state |
		settings metadataEnabled: state.
		self updatePreview ].
	projectCheckBox whenChangedDo: [ :state |
		settings projectContextEnabled: state.
		self updatePreview ].
	sessionCheckBox whenChangedDo: [ :state |
		settings sessionContextEnabled: state.
		self updatePreview ]
]

{ #category : 'layout' }
ChatPharoContextSettingsPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 6;
		  add: environmentCheckBox expand: false;
		  add: projectCheckBox expand: false;
		  add: sessionCheckBox expand: false;
		  add: 'Long-term memory is switched with the Memory application. Sent with your next message:' expand: false;
		  add: previewText;
		  yourself
]

{ #category : 'initialization' }
ChatPharoContextSettingsPresenter >> initializePresenters [

	environmentCheckBox := self newCheckBox
		                       label: 'Environment: ChatPharo version, Pharo version, platform';
		                       state: settings metadataEnabled;
		                       yourself.
	projectCheckBox := self newCheckBox
		                   label: 'Project (automatic): image, repositories, branches, uncommitted packages';
		                   state: settings projectContextEnabled;
		                   yourself.
	sessionCheckBox := self newCheckBox
		                   label: 'Session (short-term): focused window, open windows, latest code changes';
		                   state: settings sessionContextEnabled;
		                   yourself.
	previewText := self newText
		               beNotEditable;
		               yourself.
	self updatePreview
]

{ #category : 'accessing - model' }
ChatPharoContextSettingsPresenter >> setModelBeforeInitialization: aSettings [

	settings := aSettings
]

{ #category : 'updating' }
ChatPharoContextSettingsPresenter >> updatePreview [

	previewText text: ((ChatPharoContext settings: settings) promptFor: '')
]
