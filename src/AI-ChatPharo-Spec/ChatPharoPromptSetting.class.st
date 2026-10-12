"
I am one editable prompt of the settings: an explanation for the user and the
way to read and write the text. `ChatPharoPromptSettingsPresenter` edits me.
"
Class {
	#name : 'ChatPharoPromptSetting',
	#superclass : 'Object',
	#instVars : [
		'explanation',
		'readBlock',
		'writeBlock'
	],
	#category : 'AI-ChatPharo-Spec-Extentions',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Extentions'
}

{ #category : 'instance creation' }
ChatPharoPromptSetting class >> explaining: aString reading: aReadBlock writing: aWriteBlock [

	^ self new
		  setExplanation: aString reading: aReadBlock writing: aWriteBlock;
		  yourself
]

{ #category : 'accessing' }
ChatPharoPromptSetting >> explanation [

	^ explanation
]

{ #category : 'initialization' }
ChatPharoPromptSetting >> setExplanation: aString reading: aReadBlock writing: aWriteBlock [

	explanation := aString.
	readBlock := aReadBlock.
	writeBlock := aWriteBlock
]

{ #category : 'accessing' }
ChatPharoPromptSetting >> text [

	^ readBlock value
]

{ #category : 'accessing' }
ChatPharoPromptSetting >> text: aString [

	writeBlock value: aString
]
