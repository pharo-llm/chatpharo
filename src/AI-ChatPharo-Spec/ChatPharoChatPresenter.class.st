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
		'attachedFilesPresenter',
		'messagePresenters',
		'messagesScroll'
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
		self showMessage: each ].

	messageTextField whenSubmitDo: [ :text | self sendMessage ].
	messageTextField whenTextChangedDo: [ :text | self updateSubmitButtonState ].

	submitButton action: [ self sendMessage ].
	self updateSubmitButtonState.

	cancelButton action: [
			ChatPharoLogger logFrontend: 'Cancel button pressed in chat tab' details: (Dictionary new
					 at: 'chatId' put: model identityHash;
					 yourself).
			model cancelMessage.
			self hideThinking.
			cancelButton visible: false.
			self showCommandResponse: 'Operations cancelled by the user.'.
			messageTextField text: ''.
			messageTextField enabled: true.
			messageTextField takeKeyboardFocus.
			self updateSubmitButtonState ].

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

	"The chat answers from a background process; widgets are only touched on the UI process,
	 in the order the events happened."
	model whenQuestionRecordedDo: [ :message | self defer: [ self showPendingMessage: message ] ].
	model whenAnswerReceivedDo: [ :message | self defer: [ self showAnswerOf: message ] ].
	model whenToolExecutionDo: [ :toolName | self defer: [ self showToolExecution: toolName ] ].
	model whenErrorReceivedDo: [ :errorMessage | self defer: [ self showSendFailure: errorMessage ] ].
	model whenChatResetDo: [ self reloadMessages ]
]

{ #category : 'layout' }
ChatPharoChatPresenter >> defaultLayout [

	^ SpBoxLayout newVertical
		  spacing: 10;
		  add: scrollableMessages expand: true;
		  add: thinkingPresenter withConstraints: [ :c | c height: self statusBarHeight ];
		  add: errorPresenter withConstraints: [ :c | c height: self statusBarHeight ];
		  add: attachedFilesPresenter expand: false;
		  add: (SpBoxLayout newHorizontal
				   spacing: 5;
				   add: moreMenuButton withConstraints: [ :c |
						   c
							   width: 30;
							   padding: 2 ];
				   add: messageTextField;
				   add: (SpBoxLayout newHorizontal
						    add: submitButton expand: true;
						    add: cancelButton expand: true;
						    yourself)
				   withConstraints: [ :c |
						   c
							   width: 30;
							   padding: 0 ];
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

	errorPresenter hide
]

{ #category : 'initialization' }
ChatPharoChatPresenter >> hideThinking [
	"Stop the indicator, leave 'Done' readable for a moment, then hide it."

	thinkingPresenter phase: #finished.
	thinkingPresenter stopAnimation.
	[
		(Delay forMilliseconds: 600) wait.
		self defer: [ thinkingPresenter isFinished ifTrue: [ thinkingPresenter hide ] ] ] fork
]

{ #category : 'initialization' }
ChatPharoChatPresenter >> initializePresenters [

	messageTextField := self newTextInput
		                    placeholder: 'Ask a question or type /help ';
		                    yourself.

	submitButton := self newButton
		                label: '';
		                icon: (self iconNamed: #smallDoIt);
		                help: 'Submit prompt';
		                yourself.

	cancelButton := self newButton
		                label: '';
		                icon: (self iconNamed: #smallCancel);
		                help: 'Cancel prompt';
		                visible: false;
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
	thinkingPresenter hide.
	errorPresenter hide.

	attachedFiles := OrderedCollection new.
	attachedFilesLayout := SpBoxLayout newVertical.
	attachedFilesPresenter := SpPresenter new.
	attachedFilesPresenter layout: attachedFilesLayout.
	attachedFilesPresenter visible: false.

	messagePresenters := IdentityDictionary new.
	scrollableMessages := SpPresenter new.
	self installMessagesLayout
]

{ #category : 'initialization' }
ChatPharoChatPresenter >> initializeWindow: aWindowPresenter [
	
	super initializeWindow: aWindowPresenter.
	
	aWindowPresenter
		title: 'Pharo chat';
		initialExtent: 800@500
]

{ #category : 'private' }
ChatPharoChatPresenter >> installMessagesLayout [
	"A fresh, empty transcript. It scrolls vertically only; see #scrollTranscriptToBottom."

	messagesLayout := SpBoxLayout newVertical.
	messagesScroll := SpScrollableLayout with: messagesLayout.
	scrollableMessages layout: messagesScroll
]

{ #category : 'initialization' }
ChatPharoChatPresenter >> messageText [
	"Returns the current text in the message input field"

	^ messageTextField text
]

{ #category : 'private' }
ChatPharoChatPresenter >> presenterForMessage: aMessage [
	"My own presenter for aMessage. A widget lives in one window only: sharing one presenter per
	 message made a popped-out chat steal the messages of its tab, which then went blank."

	^ messagePresenters at: aMessage ifAbsentPut: [ self instantiate: ChatPharoMessagePresenter on: aMessage ]
]

{ #category : 'private' }
ChatPharoChatPresenter >> refreshMessage: aMessage [
	"aMessage changed, typically its answer arrived: its own presenter redraws itself in place."

	(self presenterForMessage: aMessage) refresh.
	self scrollToLatestMessage
]

{ #category : 'initialization' }
ChatPharoChatPresenter >> reloadMessages [

	self hideThinking.
	self hideError.
	messagePresenters := IdentityDictionary new.
	self installMessagesLayout.
	model messages do: [ :each | self showMessage: each ].
	messageTextField text: ''.
	cancelButton visible: false.
	messageTextField enabled: true.
	messageTextField takeKeyboardFocus.
	self updateSubmitButtonState
]

{ #category : 'private' }
ChatPharoChatPresenter >> scrollToLatestMessage [
	"Keep the newest message in view. Without this an answer arrived below the fold and the user
	 saw the old half of the conversation. The transcript is laid out during the next UI cycle,
	 so the scroll position is set one cycle after that, when the new height is known."

	self defer: [ self defer: [ self scrollTranscriptToBottom ] ]
]

{ #category : 'private' }
ChatPharoChatPresenter >> scrollTranscriptToBottom [
	"Lay the transcript out first: the height of the newest message must be known before
	 the bottom can be reached. The transcript wraps its text, so it never scrolls sideways."

	messagesScroll withAdapterDo: [ :adapter |
		adapter widget hScrollbarShowNever.
		adapter widget scrollTarget fullBounds.
		adapter widget fullBounds ].
	messagesScroll scrollTo: 0 @ 1
]

{ #category : 'initialization' }
ChatPharoChatPresenter >> sendMessage [

	| text attachmentsCopy parser result commandResponse |
	text := (messageTextField text ifNil: [ '' ]) asString.
	text trimBoth ifEmpty: [
			ChatPharoLogger logFrontend: 'Send blocked - empty message' details: (Dictionary new
					 at: 'chatId' put: model identityHash;
					 yourself).
			^ self ].
	parser := ChatPharoCommandParser default.
	result := parser parse: text.

	result isCommand ifTrue: [ "Handle command execution"
			ChatPharoLogger logFrontend: 'Command detected' details: (Dictionary new
					 at: 'chatId' put: model identityHash;
					 at: 'command' put: result commandName;
					 yourself).
			messageTextField text: ''.
			self updateSubmitButtonState.
			commandResponse := result execute: model. 
			self showCommandResponse: commandResponse.
			^ self ].

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
	submitButton visible: false.
	cancelButton visible: true.
	messageTextField enabled: false.
	messageTextField text: ''.
	self clearAttachments.
	model sendMessage: text withAttachments: attachmentsCopy
]

{ #category : 'accessing - model' }
ChatPharoChatPresenter >> setModelBeforeInitialization: anObject [

	model := anObject
]

{ #category : 'private - chat events' }
ChatPharoChatPresenter >> showAnswerOf: aMessage [

	thinkingPresenter thinkingContent: (aMessage thinking ifNil: [ '' ]).
	thinkingPresenter updateTokenUsageFrom: aMessage.
	self hideThinking.
	cancelButton visible: false.
	submitButton visible: true.
	self refreshMessage: aMessage.
	messageTextField text: ''.
	self updateSubmitButtonState.
	messageTextField enabled: true.
	messageTextField takeKeyboardFocus.
	ChatPharoLogger logFrontend: 'Assistant message rendered' details: (Dictionary new
			 at: 'chatId' put: model identityHash;
			 at: 'assistantLabel' put: aMessage assistantLabel;
			 yourself)
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
	self showMessage: responseMessage.

	ChatPharoLogger logFrontend: 'Command response displayed' details: (Dictionary new
		at: 'chatId' put: model identityHash;
		at: 'response' put: aString;
		yourself)
]

{ #category : 'initialization' }
ChatPharoChatPresenter >> showError: aString [
	"The error bar has a fixed place under the transcript; it is shown and hidden, never moved."

	errorPresenter errorMessage: aString.
	errorPresenter whenDismissedDo: [ self hideError ].
	errorPresenter show
]

{ #category : 'private' }
ChatPharoChatPresenter >> showMessage: aMessage [
	"Append aMessage to the transcript. Its presenter sizes itself and resizes itself when the
	 answer arrives, so the transcript never has to remove and re-add a message."

	messagesLayout add: (self presenterForMessage: aMessage) expand: false.
	self scrollToLatestMessage
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

{ #category : 'private - chat events' }
ChatPharoChatPresenter >> showPendingMessage: aMessage [
	"The user sees their question at once, with the indicator that ChatPharo is working on it."

	self showMessage: aMessage.
	self showThinking
]

{ #category : 'private - chat events' }
ChatPharoChatPresenter >> showSendFailure: anErrorMessage [

	self hideThinking.
	cancelButton visible: false.
	self showError: anErrorMessage.
	self updateSubmitButtonState.
	messageTextField enabled: true.
	messageTextField takeKeyboardFocus.
	ChatPharoLogger logFrontend: 'Error displayed in transcript' details: (Dictionary new
			 at: 'chatId' put: model identityHash;
			 at: 'error' put: anErrorMessage;
			 yourself)
]

{ #category : 'initialization' }
ChatPharoChatPresenter >> showThinking [
	"The working indicator has a fixed place under the transcript; it is shown and hidden, never moved."

	thinkingPresenter phase: #thinking.
	thinkingPresenter startAnimation.
	thinkingPresenter show
]

{ #category : 'private - chat events' }
ChatPharoChatPresenter >> showToolExecution: aToolName [

	thinkingPresenter phase: #executing.
	thinkingPresenter addExecutedTool: aToolName.
	ChatPharoLogger logFrontend: 'Tool execution feedback shown' details: (Dictionary new
			 at: 'chatId' put: model identityHash;
			 at: 'toolName' put: (aToolName ifNil: [ 'unknown' ]);
			 yourself)
]

{ #category : 'layout' }
ChatPharoChatPresenter >> statusBarHeight [

	^ 40
]

{ #category : 'initialization' }
ChatPharoChatPresenter >> updateAttachedFilesDisplay [
	"Update the display of attached files"

	| fileRowPresenter |
	attachedFilesLayout := SpBoxLayout newVertical spacing: 2.
	attachedFilesPresenter layout: attachedFilesLayout.

	attachedFiles ifEmpty: [ 
    attachedFilesPresenter visible: false.
    	^ self ].
	attachedFilesPresenter visible: true.

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

{ #category : 'initialization' }
ChatPharoChatPresenter >> updateSubmitButtonState [
	"Enable submit only when the input has non-whitespace text"

	submitButton enabled: (messageTextField isEnabled and: [
		(messageTextField text ifNil: [ '' ]) asString trimBoth isNotEmpty ])
]
