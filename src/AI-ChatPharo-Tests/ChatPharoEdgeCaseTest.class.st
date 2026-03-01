Class {
	#name : 'ChatPharoEdgeCaseTest',
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
ChatPharoEdgeCaseTest >> setUp [

        super setUp.
        ChatPharoSettings default welcomeMessageEnabled: false.
        mockAgent := ChatPharoMockAgent new.
        chat := ChatPharoChat new agent: mockAgent
]

{ #category : 'running' }
ChatPharoEdgeCaseTest >> tearDown [

        ChatPharoSettings resetDefault.
        super tearDown
]

{ #category : 'running' }
ChatPharoEdgeCaseTest >> testAddAssistantMessageWithNilAnswerExportsPlaceholder [

	| json data |
	chat history addMessage: (ChatPharoHistoryMessage role: 'user' content: 'Hello' toolCalls: nil).
   chat addAssistantMessage: nil.
	json := chat exportAsJson.
	data := STONJSON fromString: json.
	self assert: data size equals: 1.
	self assert: (data first at: 'role') equals: 'user'.
	self assert: (data last at: 'content') equals: ''.

]

{ #category : 'tests' }
ChatPharoEdgeCaseTest >> testChatHistoryPromptPrefixWithoutMessagesIsEmptyString [

        self assert: chat historyPromptPrefix equals: ''
]

{ #category : 'running' }
ChatPharoEdgeCaseTest >> testClearCacheWhenEmptyLeavesCacheEmpty [

        chat clearCache.

        self assert: (chat instVarNamed: #cache) isEmpty
]

{ #category : 'tests' }
ChatPharoEdgeCaseTest >> testClearChatAfterExportResetsState [
        | historyInstance |
        chat sendMessage: 'clear export'.
        self waitForChatProcess.
        chat exportAsJson.
        chat clearChat.
        historyInstance := chat instVarNamed: #history.

        self assert: chat messages isEmpty.
        self assert: historyInstance messages isEmpty.
        self assert: (chat instVarNamed: #cache) isEmpty
]

{ #category : 'tests' }
ChatPharoEdgeCaseTest >> testExportAsJsonWithMultilineMessagesPreservesNewlines [
        | json data userText assistantText |
        userText := 'Line1' , String lf , 'Line2'.
        assistantText := 'Answer1' , String lf , 'Answer2'.
		  chat history addMessage: (ChatPharoHistoryMessage role: 'user' content: userText toolCalls: nil).
    	  chat history addMessage: (ChatPharoHistoryMessage role: 'assistant' content: assistantText toolCalls: nil).
    
        chat addUserMessage: userText.
        chat addAssistantMessage: assistantText.
        json := chat exportAsJson.
        data := STONJSON fromString: json.

        self assert: (data first at: 'content') equals: userText.
        self assert: (data last at: 'content') equals: assistantText.
]

{ #category : 'tests' }
ChatPharoEdgeCaseTest >> testExportAsJsonWithNilUserMessageExportsEmptyString [
        | json data |
 		  chat history addMessage: (ChatPharoHistoryMessage role: 'user' content: '' toolCalls: nil).
        chat addUserMessage: nil.
        json := chat exportAsJson.
        data := STONJSON fromString: json.

        self assert: data size equals: 1.
        self assert: (data first at: 'role') equals: 'user'.
        self assert: (data first at: 'content') equals: ''.
]

{ #category : 'running' }
ChatPharoEdgeCaseTest >> testExportAsJsonWithoutMessagesIsEmptyArray [

        | json |
        json := chat exportAsJson.

        self assert: json equals: '[]'
]

{ #category : 'tests' }
ChatPharoEdgeCaseTest >> testSendMessageAfterReplacingCallbackOnlyLatestBlockRuns [
        | counter |
        counter := 0.
        chat whenAnswerReceivedDo: [ :message | counter := counter + 10 ].
        chat whenAnswerReceivedDo: [ :message | counter := counter + 1 ].
        chat sendMessage: 'replace callback'.
        self waitForChatProcess.

        self assert: counter equals: 1
]

{ #category : 'tests' }
ChatPharoEdgeCaseTest >> testSendMessageWithEmojiPreservesAssistantLabe [
        chat sendMessage: 'Hello'.
        self waitForChatProcess.

        self assert: chat messages last content equals: 'Hello'.
        self assert: chat messages last assistantLabel equals: 'Assistant'.
        self assert: (chat messages last answer includesSubstring: 'Hello')
]

{ #category : 'tests' }
ChatPharoEdgeCaseTest >> testSendMessageWithEmptyStringProducesAnswer [
        chat sendMessage: ''.
        self waitForChatProcess.

        self assert: (chat messages last answer) equals: '<<MOCK-DEFAULT-REPLY to: >>'
]

{ #category : 'tests' }
ChatPharoEdgeCaseTest >> testSendMessageWithLongTextPreservesContentLength [

        | longText |
        longText := String new: 500 withAll: $a.
        chat sendMessage: longText.
        self waitForChatProcess.

        self assert: (chat messages last content size) equals: longText size
]

{ #category : 'tests' }
ChatPharoEdgeCaseTest >> testSendMessageWithLongUnicodeStringPreservesLength [
        | longText |
        longText := String new: 200 withAll: 'あ' first.
        chat sendMessage: longText.
        self waitForChatProcess.

        self assert: (chat messages last content size) equals: longText size
]

{ #category : 'tests' }
ChatPharoEdgeCaseTest >> testSendMessageWithToolExecutionInvokesCallback [
        | toolAgent triggered |
        toolAgent := ChatPharoToolMockAgent new.
        triggered := false.
        chat agent: toolAgent.
        chat whenToolExecutionDo: [ triggered := true ].
        chat sendMessage: 'tool please'.
        self waitForChatProcess.

        self assert: triggered
]

{ #category : 'tests' }
ChatPharoEdgeCaseTest >> testSendMessageWithTrailingWhitespacePreservesExactContent [
        chat sendMessage: 'text   '.
        self waitForChatProcess.

        self assert: chat messages last content equals: 'text   '
]

{ #category : 'tests' }
ChatPharoEdgeCaseTest >> testSendMessageWithUnicodeCharactersPreservesContentAndAnswer [
        | unicode |
        unicode := 'こんにちは'.
        chat sendMessage: unicode.
        self waitForChatProcess.

        self assert: chat messages last content equals: unicode.
        self assert: (chat messages last answer includesSubstring: unicode)
]

{ #category : 'tests' }
ChatPharoEdgeCaseTest >> testSendMessageWithWhitespaceOnlyPreservesContent [

        chat sendMessage: '   '.
        self waitForChatProcess.

        self assert: (chat messages last content) equals: '   '
]

{ #category : 'tests' }
ChatPharoEdgeCaseTest >> testWhenAnswerReceivedDoNilBlockStillDeliversResponse [

        chat whenAnswerReceivedDo: nil.
        chat sendMessage: 'ping'.
        self waitForChatProcess.

        self assert: chat messages size equals: 1.
        self assert: (chat messages last answer) equals: '<<MOCK-DEFAULT-REPLY to: ping>>'
]

{ #category : 'tests' }
ChatPharoEdgeCaseTest >> testWhenToolExecutionDoNilBlockIsSafe [

        | toolAgent |
        toolAgent := ChatPharoToolMockAgent new.
        chat agent: toolAgent.
        chat whenToolExecutionDo: nil.
        chat sendMessage: 'tool run'.
        self waitForChatProcess.

        self assert: chat messages size equals: 1
]

{ #category : 'running' }
ChatPharoEdgeCaseTest >> waitForChatProcess [

        [
                | process |
                process := chat instVarNamed: #promptProcess.
                process isNil or: [ process isTerminated ]
        ] whileFalse: [ (Delay forMilliseconds: 10) wait ]
]
