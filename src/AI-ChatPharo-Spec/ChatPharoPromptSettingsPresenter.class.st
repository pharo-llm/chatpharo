"
I edit a `ChatPharoPromptSetting`: a line of explanation above a text area.
What the user types is written to the setting as they type.
"
Class {
	#name : 'ChatPharoPromptSettingsPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'setting',
		'promptText'
	],
	#category : 'AI-ChatPharo-Spec-Extentions',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Extentions'
}

{ #category : 'initialization' }
ChatPharoPromptSettingsPresenter >> connectPresenters [

	promptText whenTextChangedDo: [ :text | setting text: text asString ]
]

{ #category : 'layout' }
ChatPharoPromptSettingsPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 6;
		  add: (self newLabel label: setting explanation) expand: false;
		  add: promptText;
		  yourself
]

{ #category : 'initialization' }
ChatPharoPromptSettingsPresenter >> initializePresenters [

	promptText := self newText
		              text: setting text;
		              yourself
]

{ #category : 'accessing - model' }
ChatPharoPromptSettingsPresenter >> setModelBeforeInitialization: aPromptSetting [

	setting := aPromptSetting
]
