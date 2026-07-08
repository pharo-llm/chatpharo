Class {
	#name : 'ChatPharoTest',
	#superclass : 'TestCase',
	#instVars : [
		'app',
		'mockApi'
	],
	#category : 'AI-ChatPharo-Tests-Spec',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Spec'
}

{ #category : 'running' }
ChatPharoTest >> setUp [

	super setUp.
	ChatPharoSettings default welcomeMessageEnabled: false.
	app := ChatPharo new.
	mockApi := ChatPharoMockAgent new.
	app settings instVarNamed: #agent put: mockApi
]

{ #category : 'running' }
ChatPharoTest >> tearDown [

	ChatPharoSettings resetDefault.
	super tearDown
]

{ #category : 'running' }
ChatPharoTest >> testAddNewChat [
	app newChat.
	self assert: app chats size equals: 1.
]

{ #category : 'running' }
ChatPharoTest >> testInitializeStartsEmpty [

	self assert: app chats isEmpty
]

{ #category : 'running' }
ChatPharoTest >> testNewChat [
	self assert: app chats isEmpty.
	app newChat.
	self assert: app chats size equals: 1.
	self assert: (app chats anyOne isKindOf: ChatPharoChat).
]

{ #category : 'running' }
ChatPharoTest >> testNewChatAddsChatWithMockApi [

	app newChat.
	self assert: app chats size equals: 1.
	self
		assert: (app chats first instVarNamed: #agent)
		equals: mockApi
]

{ #category : 'running' }
ChatPharoTest >> testNewChatStartsWithWelcomeMessage [

	app newChat.
	self assert: app chats first messages isEmpty
]

{ #category : 'running' }
ChatPharoTest >> testRemoveChatAt [ 

        app newChat.
        app newChat.
        self assert: app chats size equals: 2.
        app removeChatAt: 1.
        self assert: app chats size equals: 1
]

{ #category : 'running' }
ChatPharoTest >> testSetAndGetMessages [
	| chat message1 message |
	chat := ChatPharoChat new.
	message1 := ChatPharoMessage new content: 'Message 1'.
	message := ChatPharoMessage new content: 'Message '.
	chat messages: (OrderedCollection with: message1 with: message).
	self assert: chat messages size equals: 2.
	self assert: (chat messages includes: message1).
	self assert: (chat messages includes: message).
]

{ #category : 'running' }
ChatPharoTest >> testUseApiSwitchesAgent [

	| otherApi |
	otherApi := ChatPharoNullAgent new.
	app settings instVarNamed: #agent put: otherApi.
	self assert: app settings agent == otherApi
]

{ #category : 'running' }
ChatPharoTest >> testUseModel [
	| settings |
	settings := ChatPharoSettings new.
	settings useModel: 'TestModel'.
	self assert: settings agent model equals: 'TestModel'.
]
