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
		'chatCounter'
	],
	#category : 'AI-ChatPharo-Spec-Core',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Core'
}

{ #category : 'adding' }
ChatPharoPresenter >> addNewChat [
	| newPage chatName |
	chatCounter := chatCounter + 1.
	chatName := 'Chat ' , chatCounter asString.
	model newChat.
	newPage := SpNotebookPage 
		title: chatName 
		icon: (self iconNamed: #announcement) 
		provider: [ model chats last presenter ].
	notebook addPage: newPage.
	notebook selectPage: newPage.
	ChatPharoLogger logFrontend: 'UI added new chat tab'
		details: (Dictionary new
			at: 'title' put: chatName;
			at: 'totalTabs' put: notebook pages size;
			at: 'chatCounter' put: chatCounter;
			yourself)
]

{ #category : 'layout' }
ChatPharoPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  add: toolbar expand: false;
		  add: notebook;
		  add: (SpBoxLayout newHorizontal
		            hAlignCenter;
		            add: disclaimerLabel expand: false;
		            yourself) expand: false;
		  yourself
]

{ #category : 'adding' }
ChatPharoPresenter >> deleteAllChats [

	| removed |
	(self confirm: 'Are you sure you want to delete all chats?') ifFalse: [ ^ self ].
	removed := notebook pages size.
	notebook pages copy do: [ :page | notebook removePage: page ].
	model removeAllChats.
	ChatPharoLogger logFrontend: 'UI removed all chat tabs'
            details: (Dictionary new
                    at: 'tabsRemoved' put: removed;
                    yourself)
]

{ #category : 'initialization' }
ChatPharoPresenter >> deleteChat: aPageTitle [

	| pageToDelete pageIndex |
	pageToDelete := notebook pages detect: [ :page | page title = aPageTitle ] ifNone: [ ^ self ].

	(self confirm: 'Are you sure you want to delete this chat?') ifFalse: [ ^ self ].
	pageIndex := notebook pages indexOf: pageToDelete ifAbsent: [ ^ self ].
	notebook removePage: pageToDelete.
	model removeChatAt: pageIndex.
	ChatPharoLogger logFrontend: 'UI removed chat tab'
                details: (Dictionary new
                        at: 'title' put: aPageTitle;
                        at: 'index' put: pageIndex;
                        at: 'remainingTabs' put: notebook pages size;
                        yourself)
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

{ #category : 'initialization' }
ChatPharoPresenter >> initializePresenters [
	chatCounter := 0.
	
	notebook := self newNotebook.
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
			 label: 'Delete Chat';
			 icon: (self iconNamed: #delete);
			 help: 'Delete the selected chat';
			 action: [ self deleteSelectedChat ];
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
			 label: 'Help';
			 icon: (self iconNamed: #smallQuestion);
			 help: 'Get help with ChatPharo - context-aware assistance';
			 action: [ self openHelp ];
			 yourself).

	toolbar add: (SpToolbarButtonPresenter new
			 label: 'Tutorial';
			 icon: (self iconNamed: #help);
			 help: 'Start interactive tutorial';
			 action: [ self openTutorial ];
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
	notebook pages ifEmpty: [ self addNewChat ].
]

{ #category : 'initialization' }
ChatPharoPresenter >> initializeWindow: aWindowPresenter [
	
	super initializeWindow: aWindowPresenter.
	
	aWindowPresenter
		title: 'ChatPharo';
		initialExtent: 800@500
]

{ #category : 'initialization' }
ChatPharoPresenter >> loadChat [
	"Load a chat from a JSON file into a new tab"

	| fileReference jsonData newPage chatName |
	fileReference := UIManager default
		chooseExistingFileReference: 'Load chat'
		extensions: #( 'json' )
		path: FileLocator home.

	fileReference ifNil: [ ^ self ].

	[
		jsonData := fileReference readStream contents.
		fileReference readStream close.

		"Create a new chat and import the JSON"
		chatName := fileReference basenameWithoutExtension.
		model newChat.
		model chats last importFromJson: jsonData.

		"Add the new page to notebook"
		newPage := SpNotebookPage
			title: chatName
			icon: (self iconNamed: #announcement)
			provider: [ model chats last presenter ].
		notebook addPage: newPage.
		notebook selectPage: newPage.

		ChatPharoLogger logFrontend: 'Chat loaded from file'
			details: (Dictionary new
				at: 'path' put: fileReference fullName;
				at: 'chatTitle' put: chatName;
				at: 'totalTabs' put: notebook pages size;
				yourself)
	] on: Error do: [ :ex |
		self inform: 'Failed to load chat: ', ex messageText.
		ChatPharoLogger logFrontend: 'Chat load failed'
			details: (Dictionary new
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

	| currentChatPresenter currentText helpPresenter |
	"Get the current chat context if available"
	currentChatPresenter := notebook selectedPage
		ifNotNil: [ :page | page presenterProvider value ]
		ifNil: [ nil ].

	currentText := currentChatPresenter
		ifNotNil: [ currentChatPresenter messageText ]
		ifNil: [ '' ].

	"Create and open help presenter with context"
	helpPresenter := ChatPharoHelpPresenter new.
	helpPresenter currentContext: currentText.
	helpPresenter chatPharo: model.
	helpPresenter open.

	ChatPharoLogger logFrontend: 'Help dialog opened'
		details: (Dictionary new
			at: 'hasContext' put: currentText isNotEmpty;
			yourself)
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
	| fileReference jsonData currentChat defaultFilename |
	notebook selectedPage ifNil: [
		^ self inform: 'No chat selected.' ].
	currentChat := notebook selectedPage presenterProvider value.
	jsonData := currentChat exportAsJson.
	
	"Generate unique default filename using chat title and counter"
	defaultFilename := (notebook selectedPage title copyReplaceAll: ' ' with: '_'), '.json'.
	
	fileReference := UIManager default
		chooseForSaveFileReference: 'Save chat'
		extensions: #( 'json' )
		path: FileLocator home / defaultFilename.
	fileReference ifNil: [ ^ self ].
	[
		fileReference writeStreamDo: [ :stream |
			stream nextPutAll: jsonData ].
		ChatPharoLogger logFrontend: 'Chat exported to file'
			details: (Dictionary new
				at: 'path' put: fileReference fullName;
				at: 'chatTitle' put: notebook selectedPage title;
				yourself)
	] on: Error do: [ :ex |
		self inform: 'Failed to save chat: ', ex messageText.
		ChatPharoLogger logFrontend: 'Chat save failed'
			details: (Dictionary new
				at: 'path' put: fileReference fullName;
				at: 'error' put: ex messageText;
				yourself) ]
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

{ #category : 'status' }
ChatPharoPresenter >> updateConnectionStatus [

	[
	ChatPharoLogger logFrontend: 'Started connection status monitor'
                details: (Dictionary new
                        at: 'intervalSeconds' put: 10;
                        yourself).
		[
			self updateConnectionStatusOnce.
			self updateMultiversStatus.
			(Delay forSeconds: 10) wait ] repeat ] forkAt: Processor userBackgroundPriority
]

{ #category : 'status' }
ChatPharoPresenter >> updateConnectionStatusOnce [

	| agent statusText |
	agent := model activeAgent ifNil: [ model settings agent ].

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
