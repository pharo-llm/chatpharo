Class {
	#name : 'ChatPharoBackendChatExpandedTest',
	#superclass : 'TestCase',
	#instVars : [
		'chat',
		'settings',
		'originalDefault',
		'originalLogging'
	],
	#category : 'AI-ChatPharo-Tests-Spec',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Spec'
}

{ #category : 'running' }
ChatPharoBackendChatExpandedTest >> setUp [

    super setUp.
    originalDefault := ChatPharoSettings default.
    originalLogging := ChatPharoLogger loggingEnabled.
    settings := ChatPharoSettings new.
    settings instVarNamed: #welcomeMessageEnabled put: false.
    settings instVarNamed: #loggingEnabled put: false.
    ChatPharoSettings setDefault: settings.
    ChatPharoLogger loggingEnabled: false.
    chat := ChatPharoChat new.
    chat agent: ChatPharoMockAgent new
]

{ #category : 'running' }
ChatPharoBackendChatExpandedTest >> tearDown [

    chat ifNotNil: [
        (chat instVarNamed: #promptProcess) ifNotNil: [ :process | process terminate ] ].
    ChatPharoSettings setDefault: originalDefault.
    ChatPharoLogger loggingEnabled: originalLogging.
    super tearDown
]

{ #category : 'running' }
ChatPharoBackendChatExpandedTest >> testAddAssistantMessageDoesNotCreateAdditionalTranscriptEntries [

    chat addUserMessage: 'Question'.
    chat addAssistantMessage: 'Answer'.
    self assert: chat messages size equals: 1
]

{ #category : 'running' }
ChatPharoBackendChatExpandedTest >> testAddAssistantMessageUsesAssistantLabel [ 

    chat addUserMessage: 'Question'.
    chat addAssistantMessage: 'Answer'.
    self assert: chat messages last assistantLabel equals: 'Assistant'
]

{ #category : 'running' }
ChatPharoBackendChatExpandedTest >> testAddUserMessageCreatesChatPharoMessageInstance [

    chat addUserMessage: 'Hello'.
    self assert: (chat messages first isKindOf: ChatPharoMessage)
]

{ #category : 'running' }
ChatPharoBackendChatExpandedTest >> testAddUserMessageLeavesAnswerEmpty [

    chat addUserMessage: 'Hello'.
    self assert: chat messages first answer equals: ''
]

{ #category : 'running' }
ChatPharoBackendChatExpandedTest >> testAgentHistoryInjectedOnlyOnAccess [

    | spy |
    spy := ChatPharoBackendSpyAgent new.
    chat agent: spy.
    self assert: spy history isNil.
    chat agent.
    self assert: spy history identicalTo: (chat instVarNamed: #history)
]

{ #category : 'running' }
ChatPharoBackendChatExpandedTest >> testHistoryMethodIncludesUserAndAssistantEntries [

    chat history addMessage: (ChatPharoHistoryMessage role: 'user' content: 'Hi' toolCalls: nil).
    chat history addMessage: (ChatPharoHistoryMessage role: 'assistant' content: 'There' toolCalls: nil).
    self assert: (chat historyPromptPrefix includesSubstring: 'user: Hi').
    self assert: (chat historyPromptPrefix includesSubstring: 'assistant: There').
]

{ #category : 'running' }
ChatPharoBackendChatExpandedTest >> testInitializationCreatesEmptyCache [

    self assert: (chat instVarNamed: #cache) isEmpty
]

{ #category : 'running' }
ChatPharoBackendChatExpandedTest >> testMessagesAccessorReturnsOrderedCollection [

    self assert: chat messages class equals: OrderedCollection
]

{ #category : 'running' }
ChatPharoBackendChatExpandedTest >> testMessagesSetterReplacesCollection [

    | replacement |
    replacement := OrderedCollection with: ChatPharoMessage new.
    chat messages: replacement.
    self assert: chat messages identicalTo: replacement
]

{ #category : 'running' }
ChatPharoBackendChatExpandedTest >> testSendMessageAddsSingleTranscriptEntryPerPrompt [

    chat sendMessage: 'First'.
    self waitForPromptProcess.
    chat sendMessage: 'Second'.
    self waitForPromptProcess.
    self assert: chat messages size equals: 2
]

{ #category : 'running' }
ChatPharoBackendChatExpandedTest >> testSendMessageCachesIndividualPrompts [

    chat sendMessage: 'Cache me'.
    self waitForPromptProcess.
    chat sendMessage: 'Another'.
    self waitForPromptProcess.
    self assert: (chat instVarNamed: #cache) keys asSet = #('Cache me' 'Another') asSet
]

{ #category : 'running' }
ChatPharoBackendChatExpandedTest >> testSendMessageCachesNilResponses [
    | spy cache |
    spy := ChatPharoBackendSpyAgent new.
    spy response: nil.
    chat agent: spy.
    chat sendMessage: 'Nil please'.
    self waitForPromptProcess.

    cache := chat instVarNamed: #cache.

    self assert: (cache includesKey: 'Nil please').

]

{ #category : 'running' }
ChatPharoBackendChatExpandedTest >> testSendMessageInvokesAnswerCallbackForCachedResponse [

    | cacheResponses received |
    cacheResponses := chat instVarNamed: #cache.
    cacheResponses at: 'Cached' put: 'cached answer'.
    received := nil.
    chat whenAnswerReceivedDo: [ :message | received := message answer ].
    chat sendMessage: 'Cached'.
    self assert: received equals: 'cached answer'
]

{ #category : 'running' }
ChatPharoBackendChatExpandedTest >> testSendMessageInvokesAnswerCallbackUsingSetter [

    | received |
    received := nil.
    chat whenAnswerReceivedDo: [ :message | received := message answer ].
    chat sendMessage: 'Callback'.
    self waitForPromptProcess.
    self assert: received equals: '<<MOCK-DEFAULT-REPLY to: Callback>>'
]

{ #category : 'running' }
ChatPharoBackendChatExpandedTest >> testSendMessageRecordsHistoryEntriesForEachPrompt [

    chat sendMessage: 'One'.
    self waitForPromptProcess.
    chat sendMessage: 'Two'.
    self waitForPromptProcess.
    self assert: chat messages size equals: 2
]

{ #category : 'running' }
ChatPharoBackendChatExpandedTest >> testSendMessageUsesCurrentAgentForEachPrompt [

    | first second |
    first := ChatPharoBackendSpyAgent new.
    first response: 'first'.
    chat agent: first.
    chat sendMessage: 'Prompt'.
    self waitForPromptProcess.
    second := ChatPharoBackendSpyAgent new.
    second response: 'second'.
    chat agent: second.
    chat sendMessage: 'Prompt two'.
    self waitForPromptProcess.
    self assert: chat messages last answer equals: 'second'
]

{ #category : 'running' }
ChatPharoBackendChatExpandedTest >> testSendMessageWithSpyRecordsPromptPrefixForEachSend [

    | spy |
    spy := ChatPharoBackendSpyAgent new.
    spy response: 'done'.
    chat agent: spy.

    chat sendMessage: 'First question'.
    self waitForPromptProcess.

    chat sendMessage: 'Second question'.
    self waitForPromptProcess.

    self assert: spy promptPrefixes size equals: 2.


]

{ #category : 'running' }
ChatPharoBackendChatExpandedTest >> testSendMessageWithSpyStoresResponseInTranscript [

    | spy |
    spy := ChatPharoBackendSpyAgent new.
    spy response: 'custom'.
    chat agent: spy.
    chat sendMessage: 'Prompt'.
    self waitForPromptProcess.
    self assert: chat messages last answer equals: 'custom'
]

{ #category : 'running' }
ChatPharoBackendChatExpandedTest >> testTriggerToolExecutionWithoutCallbackIsNoOp [

    chat triggerToolExecution.
    self assert: true
]

{ #category : 'running' }
ChatPharoBackendChatExpandedTest >> testWhenAnswerReceivedDoStoresBlock [

    | block |
    block := [ :msg | msg ].
    chat whenAnswerReceivedDo: block.
    self assert: (chat instVarNamed: #onAnswerReceived) identicalTo: block
]

{ #category : 'running' }
ChatPharoBackendChatExpandedTest >> testWhenToolExecutionDoStoresBlock [

    | block |
    block := [ ].
    chat whenToolExecutionDo: block.
    self assert: (chat instVarNamed: #onToolExecution) identicalTo: block
]

{ #category : 'running' }
ChatPharoBackendChatExpandedTest >> testWhenToolExecutionDoTriggersForAgentRequests [

    | spy executed |
    spy := ChatPharoBackendSpyAgent new.
    spy response: 'done'.
    executed := false.
    chat agent: spy.
    chat whenToolExecutionDo: [ executed := true ].
    chat sendMessage: 'Run'.
    self waitForPromptProcess.
    self assert: executed.
    self assert: spy toolExecutionInvoked
]

{ #category : 'running' }
ChatPharoBackendChatExpandedTest >> waitForPromptProcess [

    | process |
    process := chat instVarNamed: #promptProcess.
    process ifNil: [ ^ self ].
    [ process isTerminated ] whileFalse: [ (Delay forMilliseconds: 10) wait ]
]
