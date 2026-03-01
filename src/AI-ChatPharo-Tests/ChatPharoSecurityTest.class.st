Class {
	#name : 'ChatPharoSecurityTest',
	#superclass : 'TestCase',
	#category : 'AI-ChatPharo-Tests-Security',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Security'
}

{ #category : 'tests' }
ChatPharoSecurityTest >> setUp [

        super setUp.
        ChatPharoLogger loggingEnabled: true.
        ChatPharoLogger deleteLogFile
]

{ #category : 'tests' }
ChatPharoSecurityTest >> tearDown [ 
        ChatPharoLogger loggingEnabled: true.
        ChatPharoLogger deleteLogFile.
        super tearDown
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testAgentNameForNilReturnsNone [
        self assert: (ChatPharoLogger agentNameFor: nil) equals: 'None'
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testAgentNameUsesDisplayNameWhenProvided [
        | agentName |
        agentName := ChatPharoLogger agentNameFor: ChatPharoNullAgent new.

        self assert: agentName equals: ChatPharoNullAgent displayName
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testChatAddAssistantMessageUsesAssistantBotLabelWhenNullAgent [
        | chat |
        chat := ChatPharoChat new agent: ChatPharoNullAgent new.
        chat messages removeAll.
        (chat instVarNamed: #history) clear.
        chat addUserMessage: 'Hi'.
        chat addAssistantMessage: 'Hello'.

        self assert: chat messages last assistantLabel equals: 'Assistant bot'
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testChatAddAssistantMessageUsesAssistantLabelForRealAgents [
        | chat |
        chat := ChatPharoChat new agent: ChatPharoMockAgent new.
        chat messages removeAll.
        (chat instVarNamed: #history) clear.
        chat addUserMessage: 'Hi'.
        chat addAssistantMessage: 'Hello'.

        self assert: chat messages last assistantLabel equals: 'Assistant'
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testChatAddAssistantMessageWritesAuditLogEntry [
        | chat contents |
        chat := ChatPharoChat new agent: ChatPharoMockAgent new.
        chat messages removeAll.
        (chat instVarNamed: #history) clear.
        chat addUserMessage: 'Hi'.
        chat addAssistantMessage: 'Hello there'.
        contents := ChatPharoLogger logFile readStreamDo: [ :stream | stream contents ].

        self assert: (contents includesSubstring: 'Assistant response recorded').
        self assert: (contents includesSubstring: 'Hello there')
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testChatClearCacheRemovesAllEntries [

        | chat cache |
        chat := ChatPharoChat new agent: ChatPharoMockAgent new.
        cache := chat instVarNamed: #cache.
        cache at: 'question' put: 'answer'.
        chat clearCache.

        self assert: cache isEmpty
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testChatExportAsJsonIncludesToolCallMetadata [
        | chat history call json data |
        chat := ChatPharoChat new.
        chat messages removeAll.
        history := chat instVarNamed: #history.
        history clear.
        call := ChatPharoHistorySaverToolCall
                id: 'tool'
                functionName: 'run'
                arguments: '{}'
                content: 'result'.
        history addMessage: (ChatPharoHistoryMessage
                role: 'assistant'
                content: 'reply'
                toolCalls: { call }).
        json := chat exportAsJson.
        data := STONJSON fromString: json.

        self assert: ((data first at: 'tool_calls') first at: 'id') equals: 'tool'
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testChatExportAsJsonReplacesNilAssistantContentWithEmptyString [
        | chat json data |
        chat := ChatPharoChat new.
        chat messages removeAll.
        (chat instVarNamed: #history) clear.
        chat history addMessage: (ChatPharoHistoryMessage role: 'user' content: 'User message' toolCalls: nil).
    	  chat history addMessage: (ChatPharoHistoryMessage role: 'assistant' content: '' toolCalls: nil).
    	  chat addUserMessage: 'User message'.
        chat addAssistantMessage: nil.
        json := chat exportAsJson.
        data := STONJSON fromString: json.

        self assert: (data second at: 'content') equals: ''.
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testHistoryMessageChatMessagesOnIncludesToolCallEntries [

        | call message entries |
        call := ChatPharoHistorySaverToolCall
                id: 'tool'
                functionName: 'run'
                arguments: '{}'
                content: 'done'.
        message := ChatPharoHistoryMessage
                role: 'assistant'
                content: 'reply'
                toolCalls: { call }.
        entries := Array streamContents: [ :stream |
                message chatMessagesOn: stream ].

        self assert: entries size equals: 2.
        self assert: ((entries first at: 'tool_calls') first at: 'id') equals: 'tool'.
        self assert: (entries second at: 'role') equals: 'tool'
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testHistoryMessageChatMessagesOnOmitsNilContentKey [

        | message entries |
        message := ChatPharoHistoryMessage role: 'assistant' content: nil.
        entries := Array streamContents: [ :stream |
                message chatMessagesOn: stream ].

        self deny: ((entries first) includesKey: 'content')
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testHistoryMessageChatMessagesOnPreservesRawToolCallDictionaries [
        | tool message entries |
        tool := Dictionary with: 'custom' -> 'value'.
        message := ChatPharoHistoryMessage
                role: 'assistant'
                content: 'reply'
                toolCalls: { tool }.
        entries := Array streamContents: [ :stream |
                message chatMessagesOn: stream ].

        self assert: entries size equals: 1.
self assert: ((entries first at: 'tool_calls') first at: 'custom') equals: 'value'
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testHistoryMessageHistoryStringOnOmitsNilLiteral [
        | message output |
        message := ChatPharoHistoryMessage role: 'assistant' content: nil.
        output := String streamContents: [ :stream | message historyStringOn: stream ].

        self assert: (output includesSubstring: 'assistant: ').
        self deny: (output includesSubstring: 'nil')
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testHistoryMessagePutOpenAIChatMessagesOnMatchesChatMessagesOn [
        | message chatEntries saverEntries |
        message := ChatPharoHistoryMessage role: 'user' content: 'hi'.
        chatEntries := Array streamContents: [ :stream | message chatMessagesOn: stream ].
        saverEntries := Array streamContents: [ :stream | message putOpenAIChatMessagesOn: stream ].

        self assert: chatEntries equals: saverEntries
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testHistorySaverHistoryStringOnWithNilContentOmitsNil [
        | saver output |
        saver := ChatPharoHistorySaver role: 'assistant' content: nil.
        output := String streamContents: [ :stream | saver historyStringOn: stream ].

        self assert: (output includesSubstring: 'assistant: ').
        self deny: (output includesSubstring: 'nil')
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testHistorySaverPutOpenAIChatMessagesOnAddsToolMessages [
        | call saver entries |
        call := ChatPharoHistorySaverToolCall
                id: 'tool'
                functionName: 'run'
                arguments: '{}'
                content: 'result'.
        saver := ChatPharoHistorySaver
                role: 'assistant'
                content: 'reply'
                toolCalls: { call }.
        entries := Array streamContents: [ :stream | saver putOpenAIChatMessagesOn: stream ].

        self assert: entries size equals: 2.
        self assert: ((entries first at: 'tool_calls') first at: 'id') equals: 'tool'.
        self assert: (entries second at: 'content') equals: 'result'
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testHistorySaverPutOpenAIChatMessagesOnWithMultipleToolCallsSerializesAll [

        | call1 call2 saver entries |
        call1 := ChatPharoHistorySaverToolCall
                id: 'tool1'
                functionName: 'run'
                arguments: '{}'
                content: 'one'.
        call2 := ChatPharoHistorySaverToolCall
                id: 'tool2'
                functionName: 'run'
                arguments: '{}'
                content: 'two'.
        saver := ChatPharoHistorySaver
                role: 'assistant'
                content: 'reply'
                toolCalls: { call1. call2 }.
        entries := Array streamContents: [ :stream | saver putOpenAIChatMessagesOn: stream ].

        self assert: ((entries first at: 'tool_calls') size) equals: 2.
        self assert: (entries second at: 'role') equals: 'tool'.
        self assert: (entries third at: 'role') equals: 'tool'
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testHistorySaverPutOpenAIChatMessagesOnWithNilContentUsesPlaceholders [

        | call saver entries |
        call := ChatPharoHistorySaverToolCall
                id: 'tool'
                functionName: 'fn'
                arguments: nil
                content: nil.
        saver := ChatPharoHistorySaver
                role: 'assistant'
                content: nil
                toolCalls: { call }.
        entries := Array streamContents: [ :stream |
                saver putOpenAIChatMessagesOn: stream ].

        self assert: (entries first at: 'content') equals: '[No assistant response]'.
        self assert: (entries second at: 'content') equals: '[No tool result]'
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testHistorySaverPutOpenAIChatMessagesOnWithoutToolCallsProducesSingleEntry [
        | saver entries |
        saver := ChatPharoHistorySaver role: 'assistant' content: 'reply'.
        entries := Array streamContents: [ :stream | saver putOpenAIChatMessagesOn: stream ].

        self assert: entries size equals: 1.
        self deny: ((entries first) includesKey: 'tool_calls')
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testHistorySaverToolCallOpenAIChatToolCallEncodesDictionaryArguments [
        | call dict payload |
        call := ChatPharoHistorySaverToolCall
                id: 't1'
                functionName: 'fn'
                arguments: (Dictionary new at: 'a' put: 1; at: 'b' put: 2; yourself)
                content: 'ok'.
        dict := call openAIChatToolCall.
        payload := STONJSON fromString: (dict at: 'function' at: 'arguments').

        self assert: (payload at: 'a') equals: 1.
        self assert: (payload at: 'b') equals: 2
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testHistorySaverToolCallOpenAIChatToolCallIncludesFunctionType [

        | call dict |
        call := ChatPharoHistorySaverToolCall
                id: 'tool'
                functionName: 'run'
                arguments: '{}'
                content: 'ok'.
        dict := call openAIChatToolCall.

        self assert: (dict at: 'type') equals: 'function'.
        self assert: (dict at: 'id') equals: 'tool'
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testHistorySaverToolCallOpenAIChatToolCallPreservesStringArguments [
        | call dict |
        call := ChatPharoHistorySaverToolCall
                id: 't2'
                functionName: 'fn'
                arguments: '{"count":1}'
                content: 'ok'.
        dict := call openAIChatToolCall.

        self assert: (dict at: 'function' at: 'arguments') equals: '{"count":1}'
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testHistorySaverToolCallOpenAIChatToolMessageWithContentPreservesText [
        | call message |
        call := ChatPharoHistorySaverToolCall
                id: 'tool'
                functionName: 'fn'
                arguments: '{}'
                content: 'safe'.
        message := call openAIChatToolMessage.

        self assert: (message at: 'content') equals: 'safe'
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testHistorySaverToolCallOpenAIChatToolMessageWithNilContentUsesPlaceholder [
        | call message |
        call := ChatPharoHistorySaverToolCall
                id: 'tool'
                functionName: 'fn'
                arguments: '{}'
                content: nil.
        message := call openAIChatToolMessage.

        self assert: (message at: 'content') equals: '[No tool result]'
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testHistorySaverToolCallWithNilArgumentsProducesEmptyJsonString [

        | call dict |
        call := ChatPharoHistorySaverToolCall
                id: '1'
                functionName: 'fn'
                arguments: nil
                content: 'result'.
        dict := call openAIChatToolCall.

        self assert: (dict at: 'function' at: 'arguments') equals: '{}'
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testLogBackendWritesCategorizedEntry [ 
        | contents |
        ChatPharoLogger logBackend: 'Backend entry'.
        contents := ChatPharoLogger logFile readStreamDo: [ :stream | stream contents ].

        self assert: (contents includesSubstring: '[BACKEND]').
        self assert: (contents includesSubstring: 'Backend entry')
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testLogCategoryWithCollectionDetailsWritesEachEntry [
        | contents |
        ChatPharoLogger logCategory: 'audit' description: 'Collection details' details: #('alpha' 'beta' 'gamma').
        contents := ChatPharoLogger logFile readStreamDo: [ :stream | stream contents ].

        self assert: (contents includesSubstring: '- alpha').
        self assert: (contents includesSubstring: '- beta').
        self assert: (contents includesSubstring: '- gamma')
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testLogCategoryWithScalarDetailsWritesSingleLine [
        | contents |
        ChatPharoLogger logCategory: 'audit' description: 'Scalar details' details: 'sensitive'.
        contents := ChatPharoLogger logFile readStreamDo: [ :stream | stream contents ].

        self assert: (contents includesSubstring: 'Details:').
        self assert: (contents includesSubstring: 'sensitive')
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testLogFileCreatedInsideChatpharoDirectory [
        ChatPharoLogger logSystem: 'create path'.

        self assert: ChatPharoLogger logFile parent basename equals: 'chatpharo'
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testLogFrontendWritesCategorizedEntry [
        | contents |
        ChatPharoLogger logFrontend: 'Frontend entry'.
        contents := ChatPharoLogger logFile readStreamDo: [ :stream | stream contents ].

        self assert: (contents includesSubstring: '[FRONTEND]').
        self assert: (contents includesSubstring: 'Frontend entry')
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testLogSystemWritesCategorizedEntry [

        | contents |
        ChatPharoLogger logSystem: 'System entry'.
        contents := ChatPharoLogger logFile readStreamDo: [ :stream | stream contents ].

        self assert: (contents includesSubstring: '[SYSTEM]').
        self assert: (contents includesSubstring: 'System entry')
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testLoggerAgentNameForObjectWithoutDisplayNameUsesClassName [

        | agentName |
        agentName := ChatPharoLogger agentNameFor: Object new.

        self assert: agentName equals: 'Object'
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testLoggerStringifyNilReturnsNilString [

        self assert: (ChatPharoLogger stringify: nil) equals: 'nil'
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testLoggingDisabledDeletesExistingLogFile [
        ChatPharoLogger logBackend: 'create entry'.
        self assert: ChatPharoLogger logFile exists.

        ChatPharoLogger loggingEnabled: false.

        self deny: ChatPharoLogger logFile exists.
        ChatPharoLogger loggingEnabled: true
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testLoggingDisabledPreventsBackendLogging [
        ChatPharoLogger loggingEnabled: false.
        ChatPharoLogger deleteLogFile.

        ChatPharoLogger logBackend: 'Should not be written'.

        self deny: ChatPharoLogger logFile exists.
        ChatPharoLogger loggingEnabled: true
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testLoggingDisabledPreventsFrontendLogCreation [

        ChatPharoLogger loggingEnabled: false.
        ChatPharoLogger deleteLogFile.

        ChatPharoLogger logFrontend: 'sensitive event'.

        self deny: ChatPharoLogger logFile exists.
        ChatPharoLogger loggingEnabled: true
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testLoggingDisabledPreventsSystemLogging [

        ChatPharoLogger loggingEnabled: false.
        ChatPharoLogger deleteLogFile.

        ChatPharoLogger logSystem: 'Should not be written'.

        self deny: ChatPharoLogger logFile exists.
        ChatPharoLogger loggingEnabled: true
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testLoggingReenabledAllowsLoggingAgain [
        | contents |
        ChatPharoLogger loggingEnabled: false.
        ChatPharoLogger deleteLogFile.
        ChatPharoLogger logBackend: 'suppressed'.
        self deny: ChatPharoLogger logFile exists.

        ChatPharoLogger loggingEnabled: true.
        ChatPharoLogger logBackend: 'restored entry'.
        contents := ChatPharoLogger logFile readStreamDo: [ :stream | stream contents ].

        self assert: (contents includesSubstring: 'restored entry')
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testSettingsDefaultAgentIsNullAgent [

        self assert: ChatPharoSettings default agent class equals: ChatPharoNullAgent
]

{ #category : 'tests' }
ChatPharoSecurityTest >> testStringifyHandlesDictionaryObjects [
        | dict result |
        dict := Dictionary new at: 'key' put: 'value'; yourself.
        result := ChatPharoLogger stringify: dict.

        self assert: (result includesSubstring: 'Dictionary').
        self assert: (result includesSubstring: 'key')
]
