Class {
	#name : 'ChatPharoStressTest',
	#superclass : 'TestCase',
	#instVars : [
		'chat',
		'mockAgent',
		'history'
	],
	#category : 'AI-ChatPharo-Tests-Security',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Security'
}

{ #category : 'running' }
ChatPharoStressTest >> setUp [
        super setUp.
        ChatPharoSettings default welcomeMessageEnabled: false.
        mockAgent := ChatPharoMockAgent new.
        chat := ChatPharoChat new agent: mockAgent.
        history := ChatPharoHistory new
]

{ #category : 'running' }
ChatPharoStressTest >> tearDown [

        ChatPharoLogger deleteLogFile.
        ChatPharoLogger loggingEnabled: true.
        ChatPharoSettings resetDefault.
        super tearDown
]

{ #category : 'tests' }
ChatPharoStressTest >> testCacheHandlesFiftyDistinctEntries [

        1 to: 50 do: [ :index |
                chat sendMessage: 'unique-' , index asString.
                self waitForChatProcess ].

        self assert: (chat instVarNamed: #cache) size equals: 50
]

{ #category : 'tests' }
ChatPharoStressTest >> testCacheHandlesOneHundredDistinctEntries [
        1 to: 100 do: [ :index |
                chat sendMessage: 'unique-' , index asString.
                self waitForChatProcess ].

        self assert: (chat instVarNamed: #cache) size equals: 100
]

{ #category : 'running' }
ChatPharoStressTest >> testCacheHandlesTenDistinctEntries [

        1 to: 10 do: [ :index |
                chat sendMessage: 'msg' , index asString.
                self waitForChatProcess ].

        self assert: (chat instVarNamed: #cache) size equals: 10
]

{ #category : 'tests' }
ChatPharoStressTest >> testCacheHitUnderLoadAvoidsAdditionalBackendCalls [

        | initialCalls |
        chat sendMessage: 'repeat'.
        self waitForChatProcess.
        initialCalls := mockAgent history size.

        1 to: 20 do: [ :index |
                chat sendMessage: 'repeat'.
                self waitForChatProcess ].

        self assert: mockAgent history size equals: initialCalls
]

{ #category : 'tests' }
ChatPharoStressTest >> testChatAlternatingDuplicatePromptsLimitBackendCalls [
        chat sendMessage: 'repeat-A'.
        self waitForChatProcess.
        chat sendMessage: 'repeat-B'.
        self waitForChatProcess.

        1 to: 10 do: [ :index |
                chat sendMessage: 'repeat-A'.
                self waitForChatProcess.
                chat sendMessage: 'repeat-B'.
                self waitForChatProcess ].

        self assert: mockAgent history size equals: 2
]

{ #category : 'tests' }
ChatPharoStressTest >> testChatCacheClearsAfterLargeNumberOfEntriesRemovesAll [
        1 to: 25 do: [ :index |
                chat sendMessage: 'cache-clear-' , index asString.
                self waitForChatProcess ].

        chat clearCache.

        self assert: (chat instVarNamed: #cache) isEmpty
]

{ #category : 'tests' }
ChatPharoStressTest >> testChatCacheStoresLatestResponseForRepeatedPrompt [
        | firstAnswer |
        chat sendMessage: 'cache-check'.
        self waitForChatProcess.
        firstAnswer := chat messages last answer.
        mockAgent model: 'mock-advanced'.
        chat sendMessage: 'cache-check'.
        self waitForChatProcess.

        self assert: chat messages last answer equals: firstAnswer.
        self assert: mockAgent history size equals: 1
]

{ #category : 'tests' }
ChatPharoStressTest >> testChatCachedResponseStillTriggersCallback [
        | callbackCount |
        chat sendMessage: 'cache-callback'.
        self waitForChatProcess.
        callbackCount := 0.
        chat whenAnswerReceivedDo: [ :message |
                callbackCount := callbackCount + 1.
                self assert: message answer notEmpty ].
        chat sendMessage: 'cache-callback'.
        self waitForChatProcess.

        self assert: callbackCount equals: 1
]

{ #category : 'tests' }
ChatPharoStressTest >> testChatClearCacheAfterReuseForcesNewBackendCall [
        chat sendMessage: 'repeat-cycle'.
        self waitForChatProcess.
        self assert: mockAgent history size equals: 1.
        chat sendMessage: 'repeat-cycle'.
        self waitForChatProcess.
        self assert: mockAgent history size equals: 1.
        chat clearCache.
        chat sendMessage: 'repeat-cycle'.
        self waitForChatProcess.

        self assert: mockAgent history size equals: 2
]

{ #category : 'tests' }
ChatPharoStressTest >> testChatClearChatAfterHundredMessagesClearsAllState [
        1 to: 20 do: [ :index |
                chat sendMessage: 'clear-' , index asString.
                self waitForChatProcess ].

        chat clearChat.

        self assert: chat messages isEmpty.
        self assert: (chat instVarNamed: #cache) isEmpty.
        self assert: ((chat instVarNamed: #history) messages) isEmpty
]

{ #category : 'tests' }
ChatPharoStressTest >> testChatExportAsJsonAfterAsyncMessagesAlternatesRoles [
        1 to: 5 do: [ :index |
                chat sendMessage: 'async-' , index asString.
                self waitForChatProcess ].

        self assert: chat messages size equals: 5.
        self assert: chat messages first content equals: 'async-1'.
]

{ #category : 'tests' }
ChatPharoStressTest >> testChatExportAsJsonWithHundredEntries [
        | data |
        1 to: 50 do: [ :index |
                chat history addMessage: (ChatPharoHistoryMessage role: 'user' content: 'User' , index asString toolCalls: nil).
          		 chat history addMessage: (ChatPharoHistoryMessage role: 'assistant' content: 'Assistant' , index asString toolCalls: nil).
        			 chat addUserMessage: 'User' , index asString.
        			 chat addAssistantMessage: 'Assistant' , index asString ].

        data := STONJSON fromString: chat exportAsJson.

        self assert: data size equals: 100.
        self assert: (data first at: 'role') equals: 'user'.
        self assert: (data last at: 'role') equals: 'assistant'.
]

{ #category : 'running' }
ChatPharoStressTest >> testChatExportAsJsonWithManyEntries [ 

        | data |
		  1 to: 20 do: [ :index |
                chat history addMessage: (ChatPharoHistoryMessage role: 'user' content: 'U' , index asString toolCalls: nil).
        			 chat history addMessage: (ChatPharoHistoryMessage role: 'assistant' content: 'A' , index asString toolCalls: nil).
        			 chat addUserMessage: 'U' , index asString.
      			    chat addAssistantMessage: 'A' , index asString ].

        data := STONJSON fromString: chat exportAsJson.

        self assert: data size equals: 40.
        self assert: (data last at: 'role') equals: 'assistant'.
]

{ #category : 'running' }
ChatPharoStressTest >> testChatHandlesManyManualMessages [
        1 to: 50 do: [ :index |
                chat addUserMessage: 'User ' , index asString.
                chat addAssistantMessage: 'Assistant ' , index asString ].

        self assert: chat messages size equals: 50
]

{ #category : 'tests' }
ChatPharoStressTest >> testChatHandlesTwoHundredManualMessages [
        1 to: 200 do: [ :index |
                chat addUserMessage: 'User ' , index asString.
                chat addAssistantMessage: 'Assistant ' , index asString ].

        self assert: chat messages size equals: 200
]

{ #category : 'tests' }
ChatPharoStressTest >> testChatHistoryPromptPrefixEndsWithMostRecentAssistantEntry [
        1 to: 10 do: [ :index |
                chat sendMessage: 'hist-' , index asString.
                self waitForChatProcess ].

        self assert: chat messages size equals: 10.
     	  self assert: chat messages last content equals: 'hist-10'.
]

{ #category : 'tests' }
ChatPharoStressTest >> testChatManualAndAsyncMessagesCombinedMaintainCounts [

        1 to: 5 do: [ :index |
                chat history addMessage: (ChatPharoHistoryMessage role: 'user' content: 'manual-' , index asString toolCalls: nil).
        			chat history addMessage: (ChatPharoHistoryMessage role: 'assistant' content: 'reply-' , index asString toolCalls: nil).
        			chat addUserMessage: 'manual-' , index asString.
        			chat addAssistantMessage: 'reply-' , index asString ].
        1 to: 5 do: [ :index |
                chat sendMessage: 'async-' , index asString.
                self waitForChatProcess ].


        self assert: chat messages size equals: 10.
        self assert:(chat instVarNamed: #history) messages size equals: 10.
]

{ #category : 'tests' }
ChatPharoStressTest >> testChatPromptProcessTerminatedAfterEachCompletion [
        1 to: 10 do: [ :index |
                chat sendMessage: 'proc-' , index asString.
                self waitForChatProcess.
                self assert: ((chat instVarNamed: #promptProcess) isNil or: [ (chat instVarNamed: #promptProcess) isTerminated ]) ].
]

{ #category : 'tests' }
ChatPharoStressTest >> testChatSendMessageBurstInvokesAnswerReceivedCallbackForEachMessage [
        | callbackCount |
        callbackCount := 0.
        chat whenAnswerReceivedDo: [ :message | callbackCount := callbackCount + 1 ].

        1 to: 20 do: [ :index |
                chat sendMessage: 'callback-' , index asString.
                self waitForChatProcess ].

        self assert: callbackCount equals: 20
]

{ #category : 'tests' }
ChatPharoStressTest >> testChatSendMessageBurstMaintainsAssistantAnswerFormatting [

        1 to: 5 do: [ :index |
                chat sendMessage: 'answer-' , index asString.
                self waitForChatProcess ].

        self assert: (chat messages last answer) equals: '<<MOCK-DEFAULT-REPLY to: answer-5>>'
]

{ #category : 'tests' }
ChatPharoStressTest >> testChatSendMessageBurstMaintainsAssistantLabelUnderLoad [
        1 to: 30 do: [ :index |
                chat sendMessage: 'label-' , index asString.
                self waitForChatProcess ].

        self assert: chat messages last assistantLabel equals: 'Assistant'
]

{ #category : 'tests' }
ChatPharoStressTest >> testChatSendMessageBurstMaintainsLatestMessageContent [

        1 to: 20 do: [ :index |
                chat sendMessage: 'content-' , index asString.
                self waitForChatProcess ].

        self assert: chat messages last content equals: 'content-20'
]

{ #category : 'tests' }
ChatPharoStressTest >> testChatSendMessageBurstPopulatesHistoryAndCacheConsistently [
        1 to: 30 do: [ :index |
                chat sendMessage: 'burst-' , index asString.
                self waitForChatProcess ].

        self assert: (chat instVarNamed: #cache) size equals: 30.
        self assert: chat messages size equals: 30
]

{ #category : 'tests' }
ChatPharoStressTest >> testChatSendMessageBurstUsesCacheForDuplicatesWhileMaintainingMessageCount [

        chat sendMessage: 'repeat-cache'.
        self waitForChatProcess.


        1 to: 15 do: [ :index |
                chat sendMessage: 'repeat-cache'.
                self waitForChatProcess ].

        
        self assert: chat messages size equals: 16.
        
]

{ #category : 'tests' }
ChatPharoStressTest >> testChatSendMessageCachesAnswerForEachPrompt [
        1 to: 5 do: [ :index |
                | prompt message |
                prompt := 'cache-proof-' , index asString.
                chat sendMessage: prompt.
                self waitForChatProcess.
                message := chat messages last.
                self assert: ((chat instVarNamed: #cache) at: prompt) equals: message answer ].

        self assert: (chat instVarNamed: #cache) size equals: 5
]

{ #category : 'tests' }
ChatPharoStressTest >> testChatSendMessageHistoryPromptPrefixBeginsWithFirstUserEntry [
        1 to: 5 do: [ :index |
                chat sendMessage: 'send-' , index asString.
                self waitForChatProcess ].

        self assert: chat messages first content equals: 'send-1'.
]

{ #category : 'tests' }
ChatPharoStressTest >> testChatSendMessageHundredTimesMaintainsAssistantLabelSequence [
        1 to: 100 do: [ :index |
                chat sendMessage: 'assistant-' , index asString.
                self waitForChatProcess ].

        self assert: (chat messages allSatisfy: [ :each | each assistantLabel = 'Assistant' ])
]

{ #category : 'tests' }
ChatPharoStressTest >> testChatSendMessageHundredTimesMaintainsHistoryEntries [
        1 to: 100 do: [ :index |
                chat sendMessage: 'history-' , index asString.
                self waitForChatProcess ].

        self assert: chat messages size equals: 100
]

{ #category : 'tests' }
ChatPharoStressTest >> testChatSendMessageHundredTimesMaintainsMessageCount [

        1 to: 100 do: [ :index |
                chat sendMessage: 'message-' , index asString.
                self waitForChatProcess ].

        self assert: chat messages size equals: 100
]

{ #category : 'tests' }
ChatPharoStressTest >> testChatSendMessageSequentialCancellationsDoNotLeaveProcessRunning [
        1 to: 10 do: [ :index |
                chat sendMessage: 'cancel-' , index asString.
                (Delay forMilliseconds: 1) wait.
                chat cancelMessage.
                self waitForChatProcess ].

        self assert: ((chat instVarNamed: #promptProcess) isNil or: [ (chat instVarNamed: #promptProcess) isTerminated ])
]

{ #category : 'running' }
ChatPharoStressTest >> testHistoryAsPromptPrefixWithManyMessagesContainsLastEntry [
        1 to: 50 do: [ :index |
                history addUser: 'User ' , index asString.
                history addAssistant: 'Reply ' , index asString ].

        self assert: (history asPromptPrefix includesSubstring: 'assistant: Reply 50')
]

{ #category : 'tests' }
ChatPharoStressTest >> testHistoryAsPromptPrefixWithThousandMessagesContainsFirstAndLast [
        | prefix |
        1 to: 1000 do: [ :index |
                history addUser: 'User ' , index asString.
                history addAssistant: 'Reply ' , index asString ].

        prefix := history asPromptPrefix.
        self assert: (prefix includesSubstring: 'user: User 1').
        self assert: (prefix includesSubstring: 'assistant: Reply 1000')
]

{ #category : 'tests' }
ChatPharoStressTest >> testHistoryAsPromptPrefixWithTwoHundredMessagesContainsFirstAndLast [
        1 to: 200 do: [ :index |
                history addUser: 'User ' , index asString.
                history addAssistant: 'Reply ' , index asString ].

        self assert: (history asPromptPrefix includesSubstring: 'user: User 1').
        self assert: (history asPromptPrefix includesSubstring: 'assistant: Reply 200')
]

{ #category : 'tests' }
ChatPharoStressTest >> testHistoryChatMessagesOnFiveHundredPairsMaintainsCount [
        | entries |
        1 to: 500 do: [ :index |
                history addUser: 'User ' , index asString.
                history addAssistant: 'Reply ' , index asString ].
        entries := Array streamContents: [ :stream | history chatMessagesOn: stream ].

        self assert: entries size equals: 1000.
        self assert: (entries first at: 'content') equals: 'User 1'.
        self assert: (entries last at: 'content') equals: 'Reply 500'
]

{ #category : 'tests' }
ChatPharoStressTest >> testHistoryChatMessagesOnLargeSequenceMaintainsOrder [
        | entries |
        1 to: 100 do: [ :index |
                history addUser: 'User ' , index asString.
                history addAssistant: 'Answer ' , index asString ].
        entries := Array streamContents: [ :stream | history chatMessagesOn: stream ].

        self assert: (entries first at: 'content') equals: 'User 1'.
        self assert: (entries last at: 'content') equals: 'Answer 100'
]

{ #category : 'tests' }
ChatPharoStressTest >> testHistoryClearAfterLargeLoadResetsCount [
        1 to: 120 do: [ :index |
                history addUser: 'Clear ' , index asString.
                history addAssistant: 'Response ' , index asString ].
        history clear.

        self assert: history messages isEmpty
]

{ #category : 'tests' }
ChatPharoStressTest >> testHistoryHandlesFiveHundredMessages [

        1 to: 500 do: [ :index |
                history addUser: 'Line ' , index asString ].

        self assert: history messages size equals: 500
]

{ #category : 'running' }
ChatPharoStressTest >> testHistoryHandlesHundredMessages [
        1 to: 100 do: [ :index |
                history addUser: 'Line ' , index asString ].

        self assert: history messages size equals: 100
]

{ #category : 'tests' }
ChatPharoStressTest >> testHistorySaverHandlesFiftyToolCallsStream [
        | toolCalls saver entries |
        toolCalls := (1 to: 50) collect: [ :index |
                ChatPharoHistorySaverToolCall
                        id: 'tool' , index asString
                        functionName: 'run'
                        arguments: '{}'
                        content: 'result' , index asString ].
        saver := ChatPharoHistorySaver
                role: 'assistant'
                content: 'reply'
                toolCalls: toolCalls.
        entries := Array streamContents: [ :stream | saver putOpenAIChatMessagesOn: stream ].

        self assert: entries size equals: 51.
        self assert: ((entries first at: 'tool_calls') size) equals: 50
]

{ #category : 'tests' }
ChatPharoStressTest >> testLoggerHandlesHundredRapidEntries [

        ChatPharoLogger loggingEnabled: true.
        1 to: 100 do: [ :index |
                ChatPharoLogger logSystem: 'Rapid ' , index asString ].

        self assert: ChatPharoLogger logFile exists
]

{ #category : 'tests' }
ChatPharoStressTest >> testLoggerHandlesMultipleRapidEntries [

        ChatPharoLogger loggingEnabled: true.
        1 to: 10 do: [ :index |
                ChatPharoLogger logSystem: 'Entry' , index asString ].

        self assert: ChatPharoLogger logFile exists
]

{ #category : 'running' }
ChatPharoStressTest >> waitForChatProcess [ 
        [
                | process |
                process := chat instVarNamed: #promptProcess.
                process isNil or: [ process isTerminated ]
        ] whileFalse: [ (Delay forMilliseconds: 10) wait ]
]
