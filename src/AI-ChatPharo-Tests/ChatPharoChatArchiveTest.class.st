Class {
	#name : 'ChatPharoChatArchiveTest',
	#superclass : 'TestCase',
	#instVars : [
		'archive'
	],
	#category : 'AI-ChatPharo-Tests-Chat',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Chat'
}

{ #category : 'private' }
ChatPharoChatArchiveTest >> answeredChatIn: aSession [
	"A chat of aSession that went through one question and one answer."

	| chat |
	chat := aSession newChat.
	chat agent: (ChatPharoScriptedAgent answering: {
				 (ChatPharoScriptedCompletionClient toolReplyThinking: nil).
				 (ChatPharoScriptedCompletionClient reply: 'There are no packages.') }).
	chat sendMessage: 'list packages'.
	chat waitForPromptProcessDone.
	^ chat
]

{ #category : 'running' }
ChatPharoChatArchiveTest >> setUp [

	super setUp.
	ChatPharoSettings default welcomeMessageEnabled: false.
	archive := ChatPharoChatArchive directory: FileSystem memory root / 'chats'
]

{ #category : 'running' }
ChatPharoChatArchiveTest >> tearDown [

	ChatPharoSettings resetDefault.
	super tearDown
]

{ #category : 'tests' }
ChatPharoChatArchiveTest >> testAnsweredChatIsSavedWithoutBeingAsked [

	self answeredChatIn: (ChatPharo withArchive: archive).
	self assert: (archive directory filesMatching: '*.json') size equals: 1
]

{ #category : 'tests' }
ChatPharoChatArchiveTest >> testChatNobodyWroteInIsNotSaved [

	(ChatPharo withArchive: archive) newChat save.
	self deny: archive directory exists
]

{ #category : 'tests' }
ChatPharoChatArchiveTest >> testNewSessionRestoresTheConversationsOfThePreviousOne [
	"What happens when the window is closed, the image restarted or ChatPharo updated."

	| chat restored |
	chat := self answeredChatIn: (ChatPharo withArchive: archive).
	chat title: 'Package listing'.

	restored := (ChatPharo withArchive: archive) chats.

	self assert: restored size equals: 1.
	self assert: restored first title equals: 'Package listing'.
	self assert: restored first id equals: chat id.
	self assert: restored first messages first content equals: 'list packages'.
	self assert: restored first messages first answer equals: 'There are no packages.'.
	self assert: restored first agent notNil
]

{ #category : 'tests' }
ChatPharoChatArchiveTest >> testPlainSessionKeepsNothingOnDisk [

	self answeredChatIn: ChatPharo new.
	self deny: archive directory exists
]

{ #category : 'tests' }
ChatPharoChatArchiveTest >> testRemovedChatIsNotRestored [

	| session chat |
	session := ChatPharo withArchive: archive.
	chat := self answeredChatIn: session.
	session removeChat: chat.
	self assert: session chats isEmpty.
	self assert: (ChatPharo withArchive: archive) chats isEmpty
]

{ #category : 'tests' }
ChatPharoChatArchiveTest >> testRestoredChatGivesTheModelItsToolExchangesBack [

	| restored roles |
	self answeredChatIn: (ChatPharo withArchive: archive).
	restored := (ChatPharo withArchive: archive) chats first.
	roles := (Array streamContents: [ :stream | (restored instVarNamed: #history) putOpenAIChatMessagesOn: stream ]) collect: [ :each |
		         each at: 'role' ].
	self assert: roles equals: #( 'user' 'assistant' 'tool' 'assistant' )
]

{ #category : 'tests' }
ChatPharoChatArchiveTest >> testRestoredChatKeepsSavingItself [

	| restored |
	self answeredChatIn: (ChatPharo withArchive: archive).
	restored := (ChatPharo withArchive: archive) chats first.
	restored agent: (ChatPharoScriptedAgent answering: { (ChatPharoScriptedCompletionClient reply: 'More.') }).
	restored sendMessage: 'and then?'.
	restored waitForPromptProcessDone.
	self assert: (ChatPharo withArchive: archive) chats first messages size equals: 2
]

{ #category : 'tests' }
ChatPharoChatArchiveTest >> testUnreadableFileIsSkipped [

	self answeredChatIn: (ChatPharo withArchive: archive).
	(archive directory / 'broken.json') writeStreamDo: [ :stream | stream nextPutAll: '{ not json' ].
	self assert: (ChatPharo withArchive: archive) chats size equals: 1
]
