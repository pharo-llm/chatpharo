"
Shell window that shows a toolbar and a notebook of chats. Lets the user create/delete/save chats and open the global settings dialog.
"
Class {
	#name : 'ChatPharoPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'messageTextField',
		'model',
		'notebook',
		'toolbar',
		'connectionStatusLabel',
		'multiversStatusLabel',
		'disclaimerLabel',
		'chatCounter',
		'connectionMonitorProcess',
		'chatsByPage'
	],
	#category : 'AI-ChatPharo-Spec-Core',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Core'
}

{ #category : 'adding' }
ChatPharoPresenter >> addNewChat [

	| chat |
	chat := model newChat.
	self addPageForChat: chat.
	ChatPharoLogger logFrontend: 'UI added new chat tab' details: (Dictionary new
			 at: 'title' put: chat title;
			 at: 'totalTabs' put: notebook pages size;
			 at: 'chatCounter' put: chatCounter;
			 yourself)
]

{ #category : 'adding' }
ChatPharoPresenter >> addPageForChat: aChat [
	"Show aChat in a tab of its own. The tab is bound to this very chat: a page that looked up
	 'the last chat' when it was drawn showed the wrong, empty conversation after another tab was added."

	| page chatPresenter |
	chatCounter := chatCounter + 1.
	aChat title ifNil: [ aChat title: 'Chat ' , chatCounter asString ].
	chatPresenter := aChat presenter.
	page := SpNotebookPage title: aChat title icon: (self iconNamed: #announcement) provider: [ chatPresenter ].
	page beCloseable.
	aChat whenTitleGeneratedDo: [ :title | self defer: [ page title: title ] ].
	chatsByPage at: page put: aChat.
	notebook addPage: page.
	notebook selectPage: page.
	^ page
]

{ #category : 'layout' }
ChatPharoPresenter >> closeChat: aPage [

	(notebook pages includes: aPage) ifFalse: [ ^ self ].
	notebook removePage: aPage.
	self forgetPage: aPage.
	notebook pages ifEmpty: [ self addNewChat ]
]

{ #category : 'layout' }
ChatPharoPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  add: toolbar expand: false;
		  add: notebook expand: true;
		  add: (SpBoxLayout newHorizontal
				   hAlignCenter;
				   add: disclaimerLabel expand: false;
				   yourself)
		  expand: false;
		  yourself
]

{ #category : 'adding' }
ChatPharoPresenter >> deleteAllChats [

	| removed |
	(self confirm: 'Are you sure you want to delete all chats?') ifFalse: [ ^ self ].
	removed := notebook pages size.
	chatsByPage removeAll.
	notebook pages copy do: [ :page | notebook removePage: page ].
	model removeAllChats.
	ChatPharoLogger logFrontend: 'UI removed all chat tabs' details: (Dictionary new
			 at: 'tabsRemoved' put: removed;
			 yourself).
	notebook pages ifEmpty: [ self addNewChat ]
]

{ #category : 'initialization' }
ChatPharoPresenter >> deleteChat: aPageTitle [

	| page |
	page := notebook pages detect: [ :each | each title = aPageTitle ] ifNone: [ ^ self ].
	(self confirm: 'Are you sure you want to delete this chat?') ifFalse: [ ^ self ].
	self closeChat: page
]

{ #category : 'initialization' }
ChatPharoPresenter >> deleteSelectedChat [

	notebook selectedPage ifNil: [ 
		
		
		ChatPharoLogger logFrontend: 'Delete chat requested without selection'
                    details: (Dictionary new
                            at: 'totalTabs' put: notebook pages size;
                            yourself).
^ self inform: 'No chat selected.' ].

	self deleteChat: notebook selectedPage title
]

{ #category : 'private' }
ChatPharoPresenter >> forgetPage: aPage [
	"The chat of a closed tab leaves the session. Safe to call twice for the same page."

	(chatsByPage removeKey: aPage ifAbsent: [ nil ]) ifNotNil: [ :chat | model removeChat: chat ]
]

{ #category : 'initialization' }
ChatPharoPresenter >> initializePresenters [

	"Opened without an application, I show a transient session of my own."
	model ifNil: [ model := ChatPharo new ].
	chatCounter := 0.
	chatsByPage := IdentityDictionary new.

	notebook := self newNotebook.
	notebook whenPageRemovedDo: [ :page |
		self forgetPage: page.
		notebook pages ifEmpty: [ self addNewChat ] ].
	toolbar := self newToolbar.
	disclaimerLabel := self newLabel
		                   label: 'ChatPharo may make mistakes. Check important info.';
		                   yourself.
	toolbar add: (SpToolbarButtonPresenter new
			 label: 'New Chat';
			 icon: (self iconNamed: #add);
			 help: 'Create a new chat';
			 action: [ self addNewChat ];
			 yourself).

	toolbar add: (SpToolbarButtonPresenter new
			 label: 'Delete All';
			 icon: (self iconNamed: #delete);
			 help: 'Delete all chats';
			 action: [ self deleteAllChats ];
			 yourself).


	toolbar add: (SpToolbarButtonPresenter new
			 label: 'Save Chat';
			 icon: (self iconNamed: #smallSave);
			 help: 'Save current chat';
			 action: [ self saveCurrentChat ];
			 yourself).

	toolbar add: (SpToolbarButtonPresenter new
			 label: 'Load Chat';
			 icon: (self iconNamed: #smallOpen);
			 help: 'Load chat from JSON file';
			 action: [ self loadChat ];
			 yourself).

	toolbar add: (SpToolbarButtonPresenter new
			 label: 'Settings';
			 icon: (self iconNamed: #smallConfiguration);
			 help: 'Open settings';
			 action: [ self openSettings ];
			 yourself).

	connectionStatusLabel := SpToolbarButtonPresenter new
		                         label: 'Checking connection...';
		                         enabled: false;
		                         action: [ ];
		                         yourself.

	toolbar add: connectionStatusLabel.

	multiversStatusLabel := SpToolbarButtonPresenter new
		                        label: '';
		                        icon: (self iconNamed: #branch);
		                        help: 'Multivers mode status';
		                        enabled: false;
		                        action: [ self openSettings ];
		                        yourself.

	toolbar add: (SpToolbarButtonPresenter new
			 label: 'Tutorial';
			 icon: (self iconNamed: #help);
			 help: 'Start interactive tutorial';
			 action: [ self openTutorial ];
			 yourself).

	toolbar add: (SpToolbarButtonPresenter new
			 label: 'Tasks';
			 icon: (self iconNamed: #smallProfile);
			 help: 'Open the Task Manager: plans proposed by ChatPharo and their progress';
			 action: [ self openTaskManager ];
			 yourself).

	toolbar add: multiversStatusLabel.
	self updateMultiversStatus.

	toolbar add: (SpToolbarButtonPresenter new
			 label: 'Refresh Connection';
			 icon: (self iconNamed: #refresh);
			 help: 'Manually check LLM connection status';
			 action: [ self updateConnectionStatusOnce ];
			 yourself).

	self updateConnectionStatus.
	ChatPharoLogger logFrontend: 'Main presenter initialized' details: (Dictionary new
			 at: 'initialTabs' put: notebook pages size;
			 yourself).
	self showSessionChats
]

{ #category : 'initialization' }
ChatPharoPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.

	aWindowPresenter
		title: 'ChatPharo';
		initialExtent: 800 @ 500.
		aWindowPresenter whenClosedDo: [ self stopConnectionStatusMonitor ]
]

{ #category : 'initialization' }
ChatPharoPresenter >> loadChat [
	"Load a chat from a JSON file into a new tab"

	| fileReference chat |
	fileReference := UIManager default
		                 chooseExistingFileReference: 'Load chat'
		                 extensions: #( 'json' )
		                 path: FileLocator home.
	fileReference ifNil: [ ^ self ].
	[
		chat := model newChat.
		chat title: fileReference basenameWithoutExtension.
		chat importFromJson: fileReference contents.
		self addPageForChat: chat.
		ChatPharoLogger logFrontend: 'Chat loaded from file' details: (Dictionary new
				 at: 'path' put: fileReference fullName;
				 at: 'chatTitle' put: chat title;
				 at: 'totalTabs' put: notebook pages size;
				 yourself) ]
		on: Error
		do: [ :ex |
			self inform: 'Failed to load chat: ' , ex messageText.
			ChatPharoLogger logFrontend: 'Chat load failed' details: (Dictionary new
					 at: 'path' put: fileReference fullName;
					 at: 'error' put: ex messageText;
					 yourself) ]
]

{ #category : 'initialization' }
ChatPharoPresenter >> notebook [

	^ notebook
]

{ #category : 'initialization' }
ChatPharoPresenter >> notebook: anObject [

	notebook := anObject
]

{ #category : 'initialization' }
ChatPharoPresenter >> openHelp [
	"Open the help presenter with context-aware assistance"

	| helpPresenter |
	helpPresenter := ChatPharoHelpPresenter new.
	helpPresenter currentContext: ''.
	helpPresenter chatPharo: model.
	helpPresenter open.
	ChatPharoLogger logFrontend: 'Help dialog opened' details: Dictionary new
]

{ #category : 'initialization' }
ChatPharoPresenter >> openSettings [

	| settingsWindow |
	settingsWindow := model settings presenter.
	settingsWindow chatPharo: model.
	settingsWindow open.
	        ChatPharoLogger logFrontend: 'Settings dialog opened'
                details: (Dictionary new
                        at: 'activeAgent' put: (ChatPharoLogger agentNameFor: model settings agent);
                        yourself)
]

{ #category : 'initialization' }
ChatPharoPresenter >> openTaskManager [

	ChatPharoTaskManagerPresenter new open
]

{ #category : 'initialization' }
ChatPharoPresenter >> openTutorial [
	"Launch the interactive tutorial system"

	[
		"Try to resume if available, otherwise start fresh"
		ChatPharoTutorial resume
	] on: Error do: [ :ex |
		"If resume fails, just start from beginning"
		ChatPharoTutorial start ].

	ChatPharoLogger logFrontend: 'Tutorial launched'
		details: (Dictionary new yourself)
]

{ #category : 'initialization' }
ChatPharoPresenter >> saveCurrentChat [

	| fileReference chat |
	chat := self selectedChat.
	chat ifNil: [ ^ self inform: 'No chat selected.' ].
	fileReference := UIManager default
		                 chooseForSaveFileReference: 'Save chat'
		                 extensions: #( 'json' )
		                 path: FileLocator home / ((chat title copyReplaceAll: ' ' with: '_') , '.json').
	fileReference ifNil: [ ^ self ].
	[
		fileReference
			ensureDelete;
			writeStreamDo: [ :stream | stream nextPutAll: chat exportAsJson ].
		ChatPharoLogger logFrontend: 'Chat exported to file' details: (Dictionary new
				 at: 'path' put: fileReference fullName;
				 at: 'chatTitle' put: chat title;
				 yourself) ]
		on: Error
		do: [ :ex |
			self inform: 'Failed to save chat: ' , ex messageText.
			ChatPharoLogger logFrontend: 'Chat save failed' details: (Dictionary new
					 at: 'path' put: fileReference fullName;
					 at: 'error' put: ex messageText;
					 yourself) ]
]

{ #category : 'accessing' }
ChatPharoPresenter >> selectedChat [
	"The chat of the selected tab, or nil when no tab is selected."

	^ notebook selectedPage ifNotNil: [ :page | chatsByPage at: page ifAbsent: [ nil ] ]
]

{ #category : 'initialization' }
ChatPharoPresenter >> sendMessage [

        ChatPharoLogger logFrontend: 'Send triggered from main presenter'
                details: (Dictionary new
                        at: 'text' put: messageTextField text;
                        at: 'selectedTab' put: (notebook selectedPage ifNotNil: [ :page | page title ] ifNil: [ 'None' ]);
                        yourself).
	model sendMessage: messageTextField text
]

{ #category : 'accessing - model' }
ChatPharoPresenter >> setModelBeforeInitialization: anObject [

	model := anObject
]

{ #category : 'private' }
ChatPharoPresenter >> showSessionChats [
	"One tab per chat of the session: the restored conversations, or a first empty chat."

	model chats
		ifEmpty: [ self addNewChat ]
		ifNotEmpty: [ :chats | chats do: [ :each | self addPageForChat: each ] ]
]

{ #category : 'initialization' }
ChatPharoPresenter >> stopConnectionStatusMonitor [

	connectionMonitorProcess ifNotNil: [ :p |
		p isTerminated ifFalse: [ p terminate ].
		connectionMonitorProcess := nil ]
]

{ #category : 'status' }
ChatPharoPresenter >> updateConnectionStatus [

self stopConnectionStatusMonitor.

		ChatPharoLogger
			logFrontend: 'Started connection status monitor'
			details: (Dictionary new
			at: 'intervalSeconds' put: 10;
			yourself).
	connectionMonitorProcess := [
		[ connectionMonitorProcess notNil ] whileTrue: [
			UIManager default defer: [
				connectionMonitorProcess ifNotNil: [
					self updateConnectionStatusOnce.
					self updateMultiversStatus ] ].
			(Delay forSeconds: 10) wait ] ] newProcess
		priority: Processor userBackgroundPriority;
		name: 'ChatPharo connection monitor';
		yourself.
	connectionMonitorProcess resume
]

{ #category : 'status' }
ChatPharoPresenter >> updateConnectionStatusOnce [

	| agent statusText |
		agent := model
		ifNotNil: [ model activeAgent ifNil: [ model settings agent ] ]
		ifNil: [ ChatPharoSettings default agent ].

	statusText := (agent notNil and: [ agent class isReachable ])
		              ifTrue: [ 'Connected' ]
		              ifFalse: [ 'Disconnected' ].

	connectionStatusLabel
		label: statusText;
		help: (statusText = 'Connected'
				 ifTrue: [ 'Connected to backend (e.g., Ollama)' ]
				 ifFalse: [ 'No connection to backend' ]);
		enabled: false.
	ChatPharoLogger logFrontend: 'Connection status updated'
                details: (Dictionary new
                        at: 'status' put: statusText;
                        at: 'agent' put: (ChatPharoLogger agentNameFor: agent);
                        yourself)
]

{ #category : 'initialization' }
ChatPharoPresenter >> updateMultiversStatus [
	"Update the multivers status indicator in the toolbar"

	| multivers statusText helpText |
	multivers := ChatPharoSettings default multivers.

	(multivers notNil and: [ multivers canExecute ])
		ifTrue: [
			statusText := 'Multivers (' , multivers stepsCount asString , ')'.
			helpText := 'Multivers mode ACTIVE with ' , multivers stepsCount asString , ' agents in chain. Click to configure.' ]
		ifFalse: [
			statusText := 'Multivers Off'.
			helpText := 'Multivers mode disabled. Click to configure.' ].

	multiversStatusLabel
		label: statusText;
		help: helpText;
		enabled: true
]
