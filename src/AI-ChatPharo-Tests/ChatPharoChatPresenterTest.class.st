Class {
	#name : 'ChatPharoChatPresenterTest',
	#superclass : 'TestCase',
	#instVars : [
		'presenter',
		'chat'
	],
	#category : 'AI-ChatPharo-Tests-Spec',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Spec'
}

{ #category : 'running' }
ChatPharoChatPresenterTest >> setUp [

	super setUp.
	chat := ChatPharoChat new agent: ChatPharoNullAgent new.
	presenter := ChatPharoChatPresenter on: chat
]

{ #category : 'running' }
ChatPharoChatPresenterTest >> tearDown [

	presenter := nil.
	chat := nil.
	super tearDown
]

{ #category : 'running' }
ChatPharoChatPresenterTest >> testAttachedFilesInitiallyEmpty [

	self assert: (presenter instVarNamed: #attachedFiles) isEmpty
]

{ #category : 'running' }
ChatPharoChatPresenterTest >> testClearAttachments [

	| files |
	files := presenter instVarNamed: #attachedFiles.
	files add: FileLocator temp asFileReference.
	presenter clearAttachments.
	self assert: files isEmpty
]

{ #category : 'running' }
ChatPharoChatPresenterTest >> testHasAttachButton [

	self assert: (presenter instVarNamed: #attachButton) isNotNil
]

{ #category : 'running' }
ChatPharoChatPresenterTest >> testHasCancelButton [

	self assert: (presenter instVarNamed: #cancelButton) isNotNil
]

{ #category : 'running' }
ChatPharoChatPresenterTest >> testHasMessageTextField [

	self assert: (presenter instVarNamed: #messageTextField) isNotNil
]

{ #category : 'running' }
ChatPharoChatPresenterTest >> testHasMessagesLayout [

	self assert: (presenter instVarNamed: #messagesLayout) isNotNil.
	self assert: (presenter instVarNamed: #model) equals: chat.
	self assert: (presenter instVarNamed: #newChatButton) isNotNil.
	self assert: (presenter instVarNamed: #submitButton) isNotNil.
	self assert: presenter isNotNil.
	self assert: (presenter isKindOf: SpPresenter)
]

{ #category : 'running' }
ChatPharoChatPresenterTest >> testSubmitDisabledForWhitespaceOnlyMessage [

	| submitButton textField |
	textField := presenter instVarNamed: #messageTextField.
	submitButton := presenter instVarNamed: #submitButton.
	textField text: '   '.
	presenter updateSubmitButtonState.
	self deny: submitButton isEnabled
]

{ #category : 'running' }
ChatPharoChatPresenterTest >> testSubmitEnabledWhenMessageContainsText [

	| submitButton textField |
	textField := presenter instVarNamed: #messageTextField.
	submitButton := presenter instVarNamed: #submitButton.
	textField text: 'Hello'.
	presenter updateSubmitButtonState.
	self assert: submitButton isEnabled
]
