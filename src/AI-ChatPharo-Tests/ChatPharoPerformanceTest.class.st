Class {
	#name : 'ChatPharoPerformanceTest',
	#superclass : 'TestCase',
	#instVars : [
		'chat',
		'mockAgent'
	],
	#category : 'AI-ChatPharo-Tests-Security',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Security'
}

{ #category : 'running' }
ChatPharoPerformanceTest >> setUp [

        super setUp.
        ChatPharoSettings default welcomeMessageEnabled: false.
        mockAgent := ChatPharoMockAgent new.
        chat := ChatPharoChat new agent: mockAgent
]

{ #category : 'running' }
ChatPharoPerformanceTest >> tearDown [ 
        ChatPharoSettings resetDefault.
        super tearDown
]

{ #category : 'running' }
ChatPharoPerformanceTest >> testAgentHistorySharedWhenAgentIsChatPharoAgent [

        | nullAgent assignedAgent |
        nullAgent := ChatPharoNullAgent new.
        chat agent: nullAgent.
        assignedAgent := chat agent.

        self assert: assignedAgent history == (chat instVarNamed: #history)
]

{ #category : 'running' }
ChatPharoPerformanceTest >> testClearCacheAfterStressfulUsageLeavesHistoryIntact [

        | historyCount |
        chat sendMessage: 'first'.
        self waitForChatProcess.
        chat sendMessage: 'second'.
        self waitForChatProcess.
        historyCount := (chat instVarNamed: #history) messages size.

        chat clearCache.

        self assert: (chat instVarNamed: #history) messages size equals: historyCount
]

{ #category : 'running' }
ChatPharoPerformanceTest >> testClearCacheRemovesEntries [

        chat sendMessage: 'one'.
        self waitForChatProcess.
        chat sendMessage: 'two'.
        self waitForChatProcess.

        chat clearCache.

        self assert: (chat instVarNamed: #cache) isEmpty
]

{ #category : 'running' }
ChatPharoPerformanceTest >> testClearChatClearsCacheAndMessages [

        chat sendMessage: 'hello'.
        self waitForChatProcess.

        chat clearChat.

        self assert: (chat instVarNamed: #cache) isEmpty.
        self assert: chat messages isEmpty
]

{ #category : 'tests' }
ChatPharoPerformanceTest >> testMultipleDistinctMessagesPopulateCacheAccordingly [

        | cache |
        chat sendMessage: 'a'.
        self waitForChatProcess.
        cache := chat instVarNamed: #cache.
        self assert: cache size equals: 1.

        chat sendMessage: 'b'.
        self waitForChatProcess.
        self assert: cache size equals: 2.

        chat sendMessage: 'c'.
        self waitForChatProcess.
        self assert: cache size equals: 3
]

{ #category : 'tests' }
ChatPharoPerformanceTest >> testRepeatedPromptInOngoingConversationIsAskedAgain [
	"The same words mean something else once the conversation moved on: 'continue', 'yes', 'again'."

	| calls |
	chat sendMessage: 'cache-test'.
	self waitForChatProcess.
	calls := (mockAgent instVarNamed: #conversationHistory) size.

	chat sendMessage: 'cache-test'.
	self waitForChatProcess.

	self assert: (mockAgent instVarNamed: #conversationHistory) size equals: calls + 1
]

{ #category : 'tests' }
ChatPharoPerformanceTest >> testSendMessageCachesResponse [

        | cache |
        chat sendMessage: 'ping'.
        self waitForChatProcess.
        cache := chat instVarNamed: #cache.

        self assert: (cache at: 'ping') equals: '<<MOCK-DEFAULT-REPLY to: ping>>'
]

{ #category : 'running' }
ChatPharoPerformanceTest >> waitForChatProcess [

        [
                | process |
                process := chat instVarNamed: #promptProcess.
                process isNil or: [ process isTerminated ]
        ] whileFalse: [ (Delay forMilliseconds: 10) wait ]
]
