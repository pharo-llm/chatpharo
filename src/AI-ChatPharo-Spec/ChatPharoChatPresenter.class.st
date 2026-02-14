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
		'newChatButton',
		'popOutButton',
		'model',
		'inspectButton',
		'scrollableMessages',
		'thinkingPresenter',
		'errorPresenter',
		'moreMenuButton',
		'attachButton',
		'attachedFiles',
		'attachedFilesLayout',
		'attachedFilesPresenter'
	],
	#category : 'AI-ChatPharo-Spec-Core',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Core'
}

{ #category : 'initialization' }
ChatPharoChatPresenter >> attachFile [
	"Allow user to select and attach files"

	| fileReference |
	fileReference := UIManager default
		                 chooseExistingFileReference: 'Select file to attach'
		                 extensions: nil
		                 path: FileLocator home.

	fileReference ifNil: [ ^ self ].

	ChatPharoLogger logFrontend: 'File attached' details: (Dictionary new
			 at: 'chatId' put: model identityHash;
			 at: 'fileName' put: fileReference basename;
			 at: 'fileSize' put: fileReference size;
			 yourself).

	attachedFiles add: fileReference.
	self updateAttachedFilesDisplay
]

{ #category : 'initialization' }
ChatPharoChatPresenter >> clearAttachments [
	"Clear all attached files"

	attachedFiles removeAll.
	self updateAttachedFilesDisplay
]

{ #category : 'initialization' }
ChatPharoChatPresenter >> connectPresenters [

	model messages do: [ :each |
		messagesLayout add: each presenter withConstraints: [ :constraints | constraints height: each height ] ].

	messageTextField whenSubmitDo: [ :text | self sendMessage ].

	submitButton action: [ self sendMessage ].

	cancelButton action: [
			ChatPharoLogger logFrontend: 'Cancel button pressed in chat tab' details: (Dictionary new
					 at: 'chatId' put: model identityHash;
					 yourself).
			model cancelMessage.
			self hideThinking.
			cancelButton visible: false.
			messageTextField text: ''.
			submitButton enabled: true.
			messageTextField enabled: true ].

	newChatButton action: [
			ChatPharoLogger logFrontend: 'New chat requested from chat tab' details: (Dictionary new
					 at: 'chatId' put: model identityHash;
					 yourself).
			model requestNewChat ].

	popOutButton action: [
			ChatPharoLogger logFrontend: 'Pop out chat requested' details: (Dictionary new
					 at: 'chatId' put: model identityHash;
					 yourself).
			model presenter open ].

	inspectButton action: [
			ChatPharoLogger logFrontend: 'Inspect chat requested' details: (Dictionary new
					 at: 'chatId' put: model identityHash;
					 yourself).
			model inspect ].

	moreMenuButton action: [ self showMoreMenu ].

	model whenAnswerReceivedDo: [ :message |
			thinkingPresenter thinkingContent: (message thinking ifNil: [ '' ]).
			self hideThinking.
			cancelButton visible: false.
			messagesLayout add: message presenter withConstraints: [ :constraints | constraints height: message height ].
			messageTextField text: ''.
			submitButton enabled: true.
			messageTextField enabled: true.
			ChatPharoLogger logFrontend: 'Assistant message rendered' details: (Dictionary new
					 at: 'chatId' put: model identityHash;
					 at: 'assistantLabel' put: message assistantLabel;
					 yourself) ].


	model whenToolExecutionDo: [
			thinkingPresenter phase: #executing.
			ChatPharoLogger logFrontend: 'Tool execution feedback shown' details: (Dictionary new
					 at: 'chatId' put: model identityHash;
					 yourself) ].

	model whenErrorReceivedDo: [ :errorMessage |
			self hideThinking.
			cancelButton visible: false.
			self showError: errorMessage.
			submitButton enabled: true.
			messageTextField enabled: true.
			ChatPharoLogger logFrontend: 'Error displayed in transcript' details: (Dictionary new
					 at: 'chatId' put: model identityHash;
					 at: 'error' put: errorMessage;
					 yourself) ].
	model whenChatResetDo: [ self reloadMessages ]
]

{ #category : 'layout' }
ChatPharoChatPresenter >> defaultLayout [

	^ SpBoxLayout newVertical
		  spacing: 10;
		  add: (SpScrollableLayout with: scrollableMessages);
		  add: attachedFilesPresenter expand: false;
		  add: (SpBoxLayout newHorizontal
				   spacing: 5;
				   add: messageTextField;
				   add: submitButton expand: false;
				   add: cancelButton expand: false;
				   add: moreMenuButton expand: false;
				   yourself)
		  expand: false;
		  yourself
]

{ #category : 'accessing' }
ChatPharoChatPresenter >> exportAsJson [

    | msgs |
    msgs :=  model historyMessages collect: [ :msg |
        | dict |
        dict := Dictionary new
            at: 'role' put: msg role;
            at: 'content' put: (msg content ifNil: [ '' ]);
            yourself.
        msg toolCalls ifNotNil: [
            dict at: 'tool_calls' put:
                (msg toolCalls collect: [ :tc |
                    (tc respondsTo: #openAIChatToolCall)
                        ifTrue: [ tc openAIChatToolCall ]
                        ifFalse: [ tc ] ] as: Array)
        ].
        dict ].
   ^ (model respondsTo: #jsonStringFor:)
        ifTrue: [ model jsonStringFor: (msgs as: Array) ]
        ifFalse: [ STONJSON toString: (msgs as: Array) ]
]

{ #category : 'initialization' }
ChatPharoChatPresenter >> formatFileSize: bytes [
	"Format file size in human readable format"

	bytes < 1024 ifTrue: [ ^ bytes asString , ' B' ].
	bytes < 1048576 ifTrue: [ ^ (bytes / 1024) asFloat printShowingDecimalPlaces: 1 , ' KB' ].
	^ (bytes / 1048576) asFloat printShowingDecimalPlaces: 1 , ' MB'
]

{ #category : 'initialization' }
ChatPharoChatPresenter >> hideError [
	"Hide the error indicator"

	messagesLayout remove: errorPresenter ifAbsent: [ "not shown" ]
]

{ #category : 'initialization' }
ChatPharoChatPresenter >> hideThinking [
	"Hide the thinking indicator and stop animation"

thinkingPresenter phase: #finished.
	thinkingPresenter stopAnimation.
	[
		(Delay forMilliseconds: 600) wait.
		thinkingPresenter isFinished ifTrue: [
			messagesLayout remove: thinkingPresenter ifAbsent: [ "not shown" ] ] ] fork
]

{ #category : 'initialization' }
ChatPharoChatPresenter >> initializePresenters [

	messageTextField := self newTextInput
		                    placeholder: 'Type your message here...';
		                    yourself.

	submitButton := self newButton
		                label: '';
		                icon: (self iconNamed: #glamorousGo);
		                help: 'Submit prompt';
		                yourself.

	cancelButton := self newButton
		                label: '';
		                icon: (self iconNamed: #delete);
		                help: 'Cancel prompt';
		                yourself.

	newChatButton := self newButton
		                 label: 'New chat';
		                 icon: (self iconNamed: #add);
		                 help: 'Start a new chat in this pane';
		                 yourself.

	popOutButton := self newButton
		                label: 'Pop out';
		                icon: (self iconNamed: #glamorousUp);
		                help: 'Open this chat in its own window';
		                yourself.



	inspectButton := self newButton
		                 label: 'Inspect';
		                 icon: (self iconNamed: #inspect);
		                 help: 'Inspect the chat object';
		                 yourself.

	moreMenuButton := self newButton
		                  label: 'More';
		                  icon: (self iconNamed: #add);
		                  help: 'More options';
		                  yourself.

	attachButton := self newButton
		                label: '';
		                icon: (self iconNamed: #smallOpen);
		                help: 'Attach files';
		                yourself.

	thinkingPresenter := self instantiate: ChatPharoThinkingPresenter.
	errorPresenter := self instantiate: ChatPharoErrorPresenter.

	attachedFiles := OrderedCollection new.
	attachedFilesLayout := SpBoxLayout newVertical.
	attachedFilesPresenter := SpPresenter new.
	attachedFilesPresenter layout: attachedFilesLayout.

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
ChatPharoChatPresenter >> messageText [
	"Returns the current text in the message input field"

	^ messageTextField text
]

{ #category : 'initialization' }
ChatPharoChatPresenter >> reloadMessages [

	self hideThinking.
	self hideError.
	messagesLayout := SpBoxLayout newVertical.
	scrollableMessages layout: messagesLayout.
	model messages do: [ :each | messagesLayout add: each presenter ].
	messageTextField text: ''.
	cancelButton visible: false.
	submitButton enabled: true.
	messageTextField enabled: true
]

{ #category : 'initialization' }
ChatPharoChatPresenter >> sendMessage [

	| text attachmentsCopy parser result commandResponse |
	text := messageTextField text. "Check if the text is a command (starts with / or @)"
	parser := ChatPharoCommandParser default.
	result := parser parse: text.

	result isCommand ifTrue: [ "Handle command execution"
			ChatPharoLogger logFrontend: 'Command detected' details: (Dictionary new
					 at: 'chatId' put: model identityHash;
					 at: 'command' put: result commandName;
					 yourself).
			messageTextField text: ''.
			commandResponse := result execute: model. "Show command response as a system message"
			self showCommandResponse: commandResponse.
			^ self ]. "Regular message handling"

	model agent isConfigured ifFalse: [
			ChatPharoLogger logFrontend: 'Send blocked - agent not configured' details: (Dictionary new
					 at: 'chatId' put: model identityHash;
					 at: 'agent' put: (ChatPharoLogger agentNameFor: model agent);
					 at: 'attachments' put: attachedFiles size;
					 yourself).
			self inform: model agent configurationErrorMessage.
			^ self ].
	ChatPharoLogger logFrontend: 'Chat tab send triggered' details: (Dictionary new
			 at: 'chatId' put: model identityHash;
			 at: 'text' put: text;
			 at: 'agent' put: (ChatPharoLogger agentNameFor: model agent);
			 yourself).
	attachmentsCopy := attachedFiles copy.
	submitButton enabled: false.
	cancelButton visible: true.
	messageTextField enabled: false.
	messageTextField text: ''.
	self clearAttachments.
	self showThinking.
	model sendMessage: text withAttachments: attachmentsCopy
]

{ #category : 'accessing - model' }
ChatPharoChatPresenter >> setModelBeforeInitialization: anObject [

	model := anObject
]

{ #category : 'initialization' }
ChatPharoChatPresenter >> showCommandResponse: aString [

	"Show a command response message to the user"

	| responseMessage |
	responseMessage := ChatPharoMessage new
		answer: aString;
		assistantLabel: 'System';
		yourself.
	model messages add: responseMessage.
	messagesLayout add: responseMessage presenter withConstraints: [ :constraints | constraints height: responseMessage height ].

	ChatPharoLogger logFrontend: 'Command response displayed' details: (Dictionary new
		at: 'chatId' put: model identityHash;
		at: 'response' put: aString;
		yourself)
]

{ #category : 'initialization' }
ChatPharoChatPresenter >> showError: aString [
	"Show the error indicator with the given error message"
errorPresenter ifNil: [ errorPresenter := self instantiate: ChatPharoErrorPresenter ].
	self hideError.
	errorPresenter errorMessage: aString.
	errorPresenter whenDismissedDo: [ self hideError ].
	messagesLayout add: errorPresenter withConstraints: [ :constraints | constraints height: 40 ]
]

{ #category : 'initialization' }
ChatPharoChatPresenter >> showMoreMenu [
	"Show a context menu with more options"

	| menu |
	menu := self newMenu.
	menu
		addItem: [ :item |
				item
					name: 'Attach file';
					icon: (self iconNamed: #smallOpen);
					action: [ self attachFile ] ];
		addItem: [ :item |
				item
					name: 'Pop out';
					icon: (self iconNamed: #glamorousUp);
					action: [
							ChatPharoLogger logFrontend: 'Pop out chat requested' details: (Dictionary new
										 at: 'chatId' put: model identityHash;
										 yourself).
							model presenter open ] ];
		addItem: [ :item |
				item
					name: 'Inspect';
					icon: (self iconNamed: #inspect);
					action: [
							ChatPharoLogger logFrontend: 'Inspect chat requested' details: (Dictionary new
										 at: 'chatId' put: model identityHash;
										 yourself).
							model inspect ] ].

	menu openWithSpecAt: moreMenuButton adapter widget bounds bottomLeft
]

{ #category : 'initialization' }
ChatPharoChatPresenter >> showThinking [
	"Show the thinking indicator with animation"
messagesLayout remove: thinkingPresenter ifAbsent: [ "not shown" ].
	thinkingPresenter phase: #thinking.
	thinkingPresenter startAnimation.
	messagesLayout add: thinkingPresenter withConstraints: [ :constraints | constraints height: 40 ]
]

{ #category : 'initialization' }
ChatPharoChatPresenter >> updateAttachedFilesDisplay [
	"Update the display of attached files"

	| fileRowPresenter |
	attachedFilesLayout := SpBoxLayout newVertical spacing: 2.
	attachedFilesPresenter layout: attachedFilesLayout.

	attachedFiles ifEmpty: [ ^ self ].

	attachedFiles do: [ :fileRef |
		| fileLayout nameLabel removeButton |
		nameLabel := self newLabel
			             label: fileRef basename , ' (' , (self formatFileSize: fileRef size) , ')';
			             yourself.

		removeButton := self newButton
			                label: '';
			                icon: (self iconNamed: #smallDelete);
			                help: 'Remove attachment';
			                action: [
				                attachedFiles remove: fileRef.
				                self updateAttachedFilesDisplay ];
			                yourself.

		fileLayout := SpBoxLayout newHorizontal
			              spacing: 5;
			              add: nameLabel;
			              add: removeButton expand: false;
			              yourself.

		fileRowPresenter := SpPresenter new.
		fileRowPresenter layout: fileLayout.

		attachedFilesLayout add: fileRowPresenter expand: false ]
]
