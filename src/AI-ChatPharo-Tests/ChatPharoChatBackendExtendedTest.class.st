Class {
	#name : 'ChatPharoChatBackendExtendedTest',
	#superclass : 'TestCase',
	#instVars : [
		'chat',
		'spyAgent'
	],
	#category : 'AI-ChatPharo-Tests-Spec',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Spec'
}

{ #category : 'running' }
ChatPharoChatBackendExtendedTest >> setUp [

    super setUp.
    ChatPharoSettings default welcomeMessageEnabled: false.
    chat := ChatPharoChat new.
    spyAgent := ChatPharoBackendSpyAgent new.
    chat agent: spyAgent.
    (chat instVarNamed: #history) clear.
    chat messages removeAll.
]

{ #category : 'running' }
ChatPharoChatBackendExtendedTest >> tearDown [

    ChatPharoSettings resetDefault.
    super tearDown
]

{ #category : 'running' }
ChatPharoChatBackendExtendedTest >> testAddAssistantMessageUpdatesHistoryAndMessage [

    | message |
    chat addUserMessage: 'hello'.
    chat addAssistantMessage: 'world'.
    message := chat messages last.
    self assert: message answer equals: 'world'.
    self assert: message assistantLabel equals: 'Assistant'.
]

{ #category : 'running' }
ChatPharoChatBackendExtendedTest >> testAddAssistantMessageUsesAssistantBotLabelForNullAgent [

    | nullAgent |
    nullAgent := ChatPharoNullAgent new.
    chat agent: nullAgent.
    chat addUserMessage: 'question'.
    chat addAssistantMessage: 'fallback'.
    self assert: chat messages last assistantLabel equals: 'Assistant bot'.
]

{ #category : 'running' }
ChatPharoChatBackendExtendedTest >> testAddAssistantMessageWithMultipleMessagesUpdatesLastOnly [

    chat addUserMessage: 'first'.
    chat addAssistantMessage: 'first-answer'.
    chat addUserMessage: 'second'.
    chat addAssistantMessage: 'second-answer'.
    self assert: chat messages size equals: 2.
    self assert: chat messages first answer equals: 'first-answer'.
    self assert: chat messages last answer equals: 'second-answer'.
]

{ #category : 'running' }
ChatPharoChatBackendExtendedTest >> testAddUserMessageAddsHistoryEntry [

    chat addUserMessage: 'hello'.
    self assert: chat messages size equals: 1.
    self assert: chat messages last content equals: 'hello'.
]

{ #category : 'running' }
ChatPharoChatBackendExtendedTest >> testAddUserMessageAddsMessageObject [

    chat addUserMessage: 'hi there'.
    self assert: chat messages size equals: 1.
    self assert: chat messages last content equals: 'hi there'.
]

{ #category : 'running' }
ChatPharoChatBackendExtendedTest >> testAddWelcomeMessageCreatesChatPharoEntry [

    | welcome history |
    chat addWelcomeMessage.
    welcome := chat messages last.
    history := chat instVarNamed: #history.
    self assert: welcome assistantLabel equals: 'ChatPharo'.
    self assert: (welcome answer beginsWith: 'Welcome to ChatPharo!').
    self assert: history messages last role equals: 'assistant'.
]

{ #category : 'running' }
ChatPharoChatBackendExtendedTest >> testAgentHistoryIsUpdatedBeforePrompt [

    chat sendMessage: 'history sync'.
    self waitForPromptProcess.
    self assert: spyAgent promptPrefixes notEmpty.
]

{ #category : 'running' }
ChatPharoChatBackendExtendedTest >> testAgentReturnsSpyAgentAfterInjection [

	| returned history |
	returned := chat agent.
	history := chat instVarNamed: #history.
	self assert: returned identicalTo: spyAgent.
	self assert: spyAgent history identicalTo: history
]

{ #category : 'running' }
ChatPharoChatBackendExtendedTest >> testClearCacheLeavesCacheEmpty [

    | cache |
    chat clearCache.
    cache := chat instVarNamed: #cache.
    self assert: cache isEmpty.
]

{ #category : 'running' }
ChatPharoChatBackendExtendedTest >> testClearChatClearsMessagesHistoryAndCache [

    | cache history |
    chat addUserMessage: 'hi'.
    chat addAssistantMessage: 'ok'.
    cache := chat instVarNamed: #cache.
    cache at: 'hi' put: 'ok'.
    history := chat instVarNamed: #history.
    chat instVarNamed: #promptProcess put: [ (Delay forMilliseconds: 1) wait ] fork.
    chat clearChat.

    self assert: chat messages isEmpty.
    self assert: history messages isEmpty.
    self assert: cache isEmpty.
]

{ #category : 'running' }
ChatPharoChatBackendExtendedTest >> testExportAsJsonHandlesNilContentAsEmptyString [

    | history json data |
    history := chat instVarNamed: #history.
    history addMessage: (ChatPharoHistoryMessage role: 'user' content: nil).
    json := chat exportAsJson.
    data := STONJSON fromString: json.
    self assert: (data first at: 'content') equals: ''.
]

{ #category : 'running' }
ChatPharoChatBackendExtendedTest >> testExportAsJsonIncludesToolResultMessages [

    | history toolCall json data |
    toolCall := ChatPharoHistorySaverToolCall
        id: 't-1'
        functionName: 'fn'
        arguments: '{}'
        content: 'result'.
    history := chat instVarNamed: #history.
    history addMessage: (ChatPharoHistorySaver role: 'assistant' content: nil toolCalls: { toolCall }).
    json := chat exportAsJson.
    data := STONJSON fromString: json.
    self assert: (((data first at: 'tool_calls') first at: 'function') at: 'name') equals: 'fn'.
]

{ #category : 'running' }
ChatPharoChatBackendExtendedTest >> testHistoryPromptPrefixMatchesHistory [

    | history |
    history := chat instVarNamed: #history.
    history addUser: 'hello'.
    self assert: chat historyPromptPrefix equals: history asPromptPrefix.
]

{ #category : 'running' }
ChatPharoChatBackendExtendedTest >> testInitializeCreatesEmptyCache [

    | cache |
    cache := chat instVarNamed: #cache.
    self assert: cache isEmpty.
]

{ #category : 'running' }
ChatPharoChatBackendExtendedTest >> testSendMessageCachesResponseForSamePrompt [

    | cache |
    chat sendMessage: 'cached prompt'.
    self waitForPromptProcess.
    cache := chat instVarNamed: #cache.
    self assert: (cache includesKey: 'cached prompt').
]

{ #category : 'running' }
ChatPharoChatBackendExtendedTest >> testSendMessagePreservesCacheAfterClearHistory [

    | cache |
    chat sendMessage: 'retain cache'.
    self waitForPromptProcess.
    chat clearChat.
    cache := chat instVarNamed: #cache.
    self assert: cache isEmpty.
]

{ #category : 'running' }
ChatPharoChatBackendExtendedTest >> testSendMessageStoresPromptInHistory [

    chat sendMessage: 'store me'.
    self waitForPromptProcess.
    self assert: chat messages first content equals: 'store me'.
]

{ #category : 'running' }
ChatPharoChatBackendExtendedTest >> testSendMessageUpdatesAnswerOnExistingMessage [

    chat sendMessage: 'update me'.
    self waitForPromptProcess.
    self assert: chat messages last answer equals: 'spy-response'.
]

{ #category : 'running' }
ChatPharoChatBackendExtendedTest >> testTriggerToolExecutionWithoutCallbackIsNoOp [

    self shouldnt: [ chat triggerToolExecution ] raise: Error.
]

{ #category : 'running' }
ChatPharoChatBackendExtendedTest >> testWhenAnswerReceivedCallbackReceivesFilledMessage [

    | received |
    received := nil.
    chat whenAnswerReceivedDo: [ :msg | received := msg ].
    chat sendMessage: 'notify'.
    self waitForPromptProcess.
    self assert: received answer equals: 'spy-response'.
    self assert: received content equals: 'notify'.
]

{ #category : 'running' }
ChatPharoChatBackendExtendedTest >> testWhenToolExecutionDoTriggersDuringSend [

    | triggered |
    triggered := false.
    chat whenToolExecutionDo: [ triggered := true ].
    spyAgent onToolExecution: [ ].
    chat sendMessage: 'tool'.
    self waitForPromptProcess.
    self assert: triggered.
]

{ #category : 'running' }
ChatPharoChatBackendExtendedTest >> waitForPromptProcess [

    | process |
    process := chat instVarNamed: #promptProcess.
    process ifNil: [ ^ self ].
    [ process isTerminated ] whileFalse: [ (Delay forMilliseconds: 10) wait ]
]
