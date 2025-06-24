"
UI for one chat tab: scrollable message column, a text field, and buttons for submit/cancel/clear. Receives push updates when the model posts a new assistant message.
"
Class {
	#name : 'ChatPharoChatPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'messagesLayout',
		'messageTextField',
		'submitButton',
		'cancelButton',
		'clearButton',
		'model',
		'inspectButton',
		'scrollableMessages'
	],
	#category : 'AI-ChatPharo-Spec-Core',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Core'
}

{ #category : 'initialization' }
ChatPharoChatPresenter >> connectPresenters [

	messageTextField whenSubmitDo: [ :text | self sendMessage ].
	submitButton action: [ self sendMessage ].
	cancelButton action: [
			model cancelMessage.
			messageTextField text: ''.
			submitButton enabled: true.
			messageTextField enabled: true ].
	inspectButton action: [ model inspect ].
	model whenAnswerReceivedDo: [ :message |
			messagesLayout add: message presenter withConstraints: [ :constraints | constraints height: (message height) * 2].
			messageTextField text: ''.
			submitButton enabled: true.
			messageTextField enabled: true ].
	 model whenToolExecutionDo: [
                        messageTextField text: 'Running, searching code and executing tools...' ]
]

{ #category : 'layout' }
ChatPharoChatPresenter >> defaultLayout [
    ^ SpBoxLayout newVertical
          spacing: 10;
          add: (SpScrollableLayout with: scrollableMessages);
          add: (SpBoxLayout newHorizontal
                   spacing: 5;
                   add: messageTextField;
                   add: submitButton expand: false;
                   add: cancelButton expand: false;
						 add: inspectButton expand: false;
                   yourself)
          expand: false;
          yourself
]

{ #category : 'initialization' }
ChatPharoChatPresenter >> initializePresenters [

	messageTextField := self newTextInput
		                    placeholder: 'Type your message here...';
		                    yourself.

	submitButton := self newButton
		                label: 'Submit';
		                icon: (self iconNamed: #glamorousGo);
		                help: 'Submit prompt';
		                yourself.

	cancelButton := self newButton
		                label: 'Cancel';
		                icon: (self iconNamed: #delete);
		                help: 'Cancel prompt';
		                yourself.

	inspectButton := self newButton
		                 label: 'Inspect';
		                 icon: (self iconNamed: #inspect);
		                 help: 'Inspect the chat object';
		                 yourself.

	messagesLayout := SpBoxLayout newVertical.
	scrollableMessages := SpPresenter new.
	scrollableMessages layout: messagesLayout
]

{ #category : 'initialization' }
ChatPharoChatPresenter >> initializeWindow: aWindowPresenter [
	
	super initializeWindow: aWindowPresenter.
	
	aWindowPresenter
		title: 'Pharo chat';
		initialExtent: 800@500
]

{ #category : 'initialization' }
ChatPharoChatPresenter >> sendMessage [

	| text |
	text := messageTextField text.
	        (model agent isConfigured)
                ifFalse: [
                        self inform: model agent configurationErrorMessage.
                        ^ self ].
	submitButton enabled: false.
	messageTextField enabled: false.
	messageTextField text: 'Running...'.
	model sendMessage: text
]

{ #category : 'accessing - model' }
ChatPharoChatPresenter >> setModelBeforeInitialization: anObject [

	model := anObject
]
