Class {
	#name : 'ChatPharoSessionPresenterTest',
	#superclass : 'TestCase',
	#instVars : [
		'session',
		'presenter'
	],
	#category : 'AI-ChatPharo-Tests-Chat',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Chat'
}

{ #category : 'running' }
ChatPharoSessionPresenterTest >> setUp [

	super setUp.
	ChatPharoSettings default welcomeMessageEnabled: false.
	session := ChatPharo new.
	session newChat title: 'First'.
	session newChat title: 'Second'.
	presenter := ChatPharoPresenter on: session
]

{ #category : 'running' }
ChatPharoSessionPresenterTest >> tearDown [

	presenter stopConnectionStatusMonitor.
	ChatPharoSettings resetDefault.
	super tearDown
]

{ #category : 'tests' }
ChatPharoSessionPresenterTest >> testClosingATabRemovesItsOwnChat [

	presenter closeChat: presenter notebook pages first.
	self assert: (session chats collect: [ :each | each title ]) asArray equals: #( 'Second' )
]

{ #category : 'tests' }
ChatPharoSessionPresenterTest >> testClosingTheLastTabOpensAFreshChat [

	presenter notebook pages copy do: [ :each | presenter closeChat: each ].
	self assert: presenter notebook pages size equals: 1.
	self assert: session chats size equals: 1
]

{ #category : 'tests' }
ChatPharoSessionPresenterTest >> testEachTabShowsItsOwnChat [
	"Tabs used to look up 'the last chat' when drawn, so every tab could show the newest, empty conversation."

	| pages |
	pages := presenter notebook pages.
	presenter notebook selectPage: pages first.
	self assert: presenter selectedChat identicalTo: session chats first.
	presenter notebook selectPage: pages second.
	self assert: presenter selectedChat identicalTo: session chats second
]

{ #category : 'tests' }
ChatPharoSessionPresenterTest >> testOpeningShowsOneTabPerExistingChat [

	self assert: (presenter notebook pages collect: [ :each | each title ]) asArray equals: #( 'First' 'Second' )
]

{ #category : 'tests' }
ChatPharoSessionPresenterTest >> testOpeningTwiceShowsTheSameWindow [

	| window |
	[
		window := session open.
		self assert: session open identicalTo: window ] ensure: [
		SystemAnnouncer uniqueInstance unsubscribe: session.
		session window ifNotNil: [ :each | each close ] ]
]

{ #category : 'tests' }
ChatPharoSessionPresenterTest >> testTwoViewsOfAChatDoNotShareMessageWidgets [
	"Popping a chat out used to move the message widgets to the new window and blank the tab."

	| chat first second |
	chat := session chats first.
	chat messages add: (ChatPharoMessage new
			 content: 'hi';
			 answer: 'hello';
			 yourself).
	first := chat presenter.
	second := chat presenter.
	self deny: (first presenterForMessage: chat messages first) identicalTo: (second presenterForMessage: chat messages first)
]

{ #category : 'tests' }
ChatPharoSessionPresenterTest >> testWindowIsKeptWhenAnUnrelatedPackageWasLoaded [

	| window |
	[
		window := session open.
		session codeWasLoaded.
		self currentWorld doOneCycle.
		self assert: session window identicalTo: window.
		self assert: window isOpen ] ensure: [
		SystemAnnouncer uniqueInstance unsubscribe: session.
		session window ifNotNil: [ :each | each close ] ]
]

{ #category : 'tests' }
ChatPharoSessionPresenterTest >> testWindowIsRebuiltWhenChatPharoCodeWasUpdated [
	"After a pull, the window that was open is made of widgets built by the old code."

	| stale |
	[
		stale := session open.
		session instVarNamed: #windowCodeFingerprint put: -1.
		session codeWasLoaded.
		self currentWorld doOneCycle.
		self deny: session window identicalTo: stale.
		self assert: session window isOpen.
		self deny: stale isOpen.
		self assert: session chats size equals: 2 ] ensure: [
		SystemAnnouncer uniqueInstance unsubscribe: session.
		session window ifNotNil: [ :window | window close ] ]
]
