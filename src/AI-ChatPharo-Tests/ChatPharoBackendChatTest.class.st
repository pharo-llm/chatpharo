Class {
	#name : 'ChatPharoBackendChatTest',
	#superclass : 'TestCase',
	#instVars : [
		'chat',
		'settings',
		'originalDefault',
		'originalLogging'
	],
	#category : 'AI-ChatPharo-Tests-History',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'History'
}

{ #category : 'running' }
ChatPharoBackendChatTest >> setUp [

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
ChatPharoBackendChatTest >> tearDown [
    chat ifNotNil: [
        (chat instVarNamed: #promptProcess) ifNotNil: [ :process | process terminate ] ].
    ChatPharoSettings setDefault: originalDefault.
    ChatPharoLogger loggingEnabled: originalLogging.
    super tearDown

]

{ #category : 'running' }
ChatPharoBackendChatTest >> testAddAssistantMessageAddsToHistoryAndUpdatesLastMessage [

    chat addUserMessage: 'Hi'.
    chat addAssistantMessage: 'There'.
    self assert: chat messages size equals: 1.
    self assert: chat messages last answer equals: 'There'.
    self assert: chat messages last assistantLabel equals: 'Assistant'.
]

{ #category : 'running' }
ChatPharoBackendChatTest >> testAddAssistantMessageUsesNullAgentLabel [

    chat agent: ChatPharoNullAgent new.
    chat addUserMessage: 'Hi'.
    chat addAssistantMessage: 'Welcome'.
    self assert: chat messages last assistantLabel equals: 'Assistant bot'
]

{ #category : 'running' }
ChatPharoBackendChatTest >> testAddUserMessageAddsHistoryAndMessages [

    chat addUserMessage: 'Hello'.
    self assert: chat messages size equals: 1.
    self assert: chat messages first content equals: 'Hello'.
]

{ #category : 'running' }
ChatPharoBackendChatTest >> testAddWelcomeMessageUsesChatPharoLabel [

    | welcomeChat |
    [
        ChatPharoSettings default instVarNamed: #welcomeMessageEnabled put: true.
        welcomeChat := ChatPharoChat new.
        self assert: welcomeChat messages size equals: 1.
        self assert: welcomeChat messages first assistantLabel equals: 'ChatPharo'.
        self assert: (welcomeChat messages first answer includesSubstring: 'Welcome to ChatPharo')
    ] ensure: [
        ChatPharoSettings default instVarNamed: #welcomeMessageEnabled put: false
    ]
]

{ #category : 'running' }
ChatPharoBackendChatTest >> testAgentAccessorInjectsHistoryIntoAgent [

    | agent |
    agent := ChatPharoBackendHistoryAwareAgent new.
    chat agent: agent.
    self assert: chat agent equals: agent.
    self assert: agent history identicalTo: (chat instVarNamed: #history)
]

{ #category : 'as yet unclassified' }
ChatPharoBackendChatTest >> testAgentReinjectsHistoryOnRepeatedAccess [

    | spy replacement |
    spy := ChatPharoBackendSpyAgent new.
    chat agent: spy.
    chat agent.
    replacement := ChatPharoHistory new.
    spy history: replacement.
    chat agent.
    self deny: spy history identicalTo: replacement.
    self assert: spy history identicalTo: (chat instVarNamed: #history)
]

{ #category : 'running' }
ChatPharoBackendChatTest >> testClearCacheDoesNotRemoveMessages [

    chat addUserMessage: 'Hi'.
    (chat instVarNamed: #cache) at: 'prompt' put: 'cached'.
    chat clearCache.
    self assert: chat messages size equals: 1.
    self assert: (chat instVarNamed: #cache) isEmpty
]

{ #category : 'running' }
ChatPharoBackendChatTest >> testExportAsJsonContainsUserAndAssistantEntries [

    | json data |
    chat history addMessage: (ChatPharoHistoryMessage role: 'user' content: 'Hi' toolCalls: nil).
    chat history addMessage: (ChatPharoHistoryMessage role: 'assistant' content: 'There' toolCalls: nil).
    json := chat exportAsJson.
    data := STONJSON fromString: json.
    self assert: data size equals: 2.
    self assert: ((data first) at: 'role') equals: 'user'.
    self assert: ((data second) at: 'role') equals: 'assistant'.
    self assert: ((data second) at: 'content') equals: 'There'.
]

{ #category : 'tests' }
ChatPharoBackendChatTest >> testExportAsJsonIncludesToolCalls [

    | toolCall data json |
    toolCall := ChatPharoHistorySaverToolCall
        id: 'tool-1'
        functionName: 'lookup'
        arguments: (Dictionary with: 'q' -> '42')
        content: 'result'.
    (chat instVarNamed: #history)
        addMessage: (ChatPharoHistoryMessage
            role: 'assistant'
            content: 'Using tool'
            toolCalls: { toolCall }).
    json := chat exportAsJson.
    data := STONJSON fromString: json.
    self assert: data size equals: 2.
    self assert: ((data first) at: 'tool_calls') size equals: 1.
    self assert: (((data first) at: 'tool_calls') first at: 'id') equals: 'tool-1'

]

{ #category : 'running' }
ChatPharoBackendChatTest >> testHistoryPromptPrefixMatchesHistory [

    | prefix |
    chat addUserMessage: 'Hi'.
    prefix := chat history.
    self assert: prefix equals: chat historyPromptPrefix.
    self assert: prefix equals: (chat instVarNamed: #history) asPromptPrefix
]

{ #category : 'running' }
ChatPharoBackendChatTest >> testInitializeWithWelcomeMessageAddsGreeting [

    | welcomeChat |
    [
        ChatPharoSettings default instVarNamed: #welcomeMessageEnabled put: true.
        welcomeChat := ChatPharoChat new.
        self assert: welcomeChat messages size equals: 1.
        self assert: (welcomeChat instVarNamed: #history) messages size equals: 1.
        self assert: (welcomeChat instVarNamed: #history) messages first role equals: 'assistant'.
        self assert: ((welcomeChat instVarNamed: #history) messages first content includesSubstring: 'Welcome to ChatPharo')
    ] ensure: [
        ChatPharoSettings default instVarNamed: #welcomeMessageEnabled put: false
    ]
]

{ #category : 'running' }
ChatPharoBackendChatTest >> testInitializeWithoutWelcomeMessageStartsEmpty [

    self assert: chat messages isEmpty.
    self assert: (chat instVarNamed: #history) messages isEmpty
]

{ #category : 'tests' }
ChatPharoBackendChatTest >> testSendMessageCachesNewResponse [

    | expected |
    expected := '<<MOCK-DEFAULT-REPLY to: Ping>>'.
    chat sendMessage: 'Ping'.
    self waitForPromptProcess.
    self assert: ((chat instVarNamed: #cache) at: 'Ping') equals: expected.
    self assert: chat messages last answer equals: expected
]

{ #category : 'tests' }
ChatPharoBackendChatTest >> testSendMessageInvokesOnAnswerCallback [

    | received |
    received := nil.
    chat instVarNamed: #onAnswerReceived put: [ :message | received := message answer ].
    chat sendMessage: 'Hello'.
    self waitForPromptProcess.
    self assert: received equals: '<<MOCK-DEFAULT-REPLY to: Hello>>'
]

{ #category : 'tests' }
ChatPharoBackendChatTest >> testSendMessagePassesPromptPrefixToAgent [

    | spy |
    spy := ChatPharoBackendSpyAgent new.
    spy response: 'done'.
    chat agent: spy.
    chat sendMessage: 'Question'.
    self waitForPromptProcess.
    self assert: spy promptPrefixes size equals: 1.
    self assert: (spy promptPrefixes first isEmpty 
        or: [ spy promptPrefixes first includesSubstring: 'Question' ]).
]

{ #category : 'tests' }
ChatPharoBackendChatTest >> testSendMessageTriggersToolExecutionWhenRequested [

    | spy executed |
    spy := ChatPharoBackendSpyAgent new.
    executed := false.
    chat agent: spy.
    chat instVarNamed: #onToolExecution put: [ executed := true ].
    spy response: 'done'.
    chat sendMessage: 'Run tool'.
    self waitForPromptProcess.
    self assert: executed.
    self assert: spy toolExecutionInvoked
]

{ #category : 'tests' }
ChatPharoBackendChatTest >> testSendMessageUsesCacheWhenEntryPresent [

    | cache |
    cache := chat instVarNamed: #cache.
    cache at: 'Cached prompt' put: 'cached response'.
    chat instVarNamed: #onAnswerReceived put: [ :msg | self assert: msg answer equals: 'cached response' ].
    chat sendMessage: 'Cached prompt'.
    self assert: chat messages last answer equals: 'cached response'.
    self assert: (chat instVarNamed: #promptProcess) isNil
]

{ #category : 'running' }
ChatPharoBackendChatTest >> testTriggerToolExecutionInvokesCallback [

    | triggered |
    triggered := false.
    chat instVarNamed: #onToolExecution put: [ triggered := true ].
    chat triggerToolExecution.
    self assert: triggered
]

{ #category : 'as yet unclassified' }
ChatPharoBackendChatTest >> waitForPromptProcess [

    | process | 
    process := chat instVarNamed: #promptProcess.
    process ifNil: [ ^ self ].
    [ process isTerminated ]
        whileFalse: [ (Delay forMilliseconds: 10) wait ]
]
