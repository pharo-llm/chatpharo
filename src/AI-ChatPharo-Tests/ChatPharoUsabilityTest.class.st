Class {
	#name : 'ChatPharoUsabilityTest',
	#superclass : 'TestCase',
	#instVars : [
		'settings'
	],
	#category : 'AI-ChatPharo-Tests-Security',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Security'
}

{ #category : 'running' }
ChatPharoUsabilityTest >> setUp [
        super setUp.
        settings := ChatPharoSettings new
]

{ #category : 'running' }
ChatPharoUsabilityTest >> tearDown [
        ChatPharoSettings resetDefault.
        super tearDown
]

{ #category : 'running' }
ChatPharoUsabilityTest >> testChatAddAssistantMessageForRegularAgentUsesAssistantLabel [
        | chat |
        ChatPharoSettings default welcomeMessageEnabled: false.
        chat := ChatPharoChat new agent: ChatPharoMockAgent new.
        chat addUserMessage: 'Hello'.
        chat addAssistantMessage: 'Hi there'.

        self assert: chat messages last assistantLabel equals: 'Assistant'.
        self assert: chat messages last answer equals: 'Hi there'
]

{ #category : 'running' }
ChatPharoUsabilityTest >> testChatAddAssistantMessageUpdatesHistory [
        | chat |
        ChatPharoSettings default welcomeMessageEnabled: false.
        chat := ChatPharoChat new agent: ChatPharoMockAgent new.
        chat addUserMessage: 'Ping'.
        chat addAssistantMessage: 'Pong'.

        self assert: chat messages size equals: 1.
        self assert: chat messages last answer equals: 'Pong'.
]

{ #category : 'running' }
ChatPharoUsabilityTest >> testChatAddUserMessageAppendsToHistory [
        | chat |
        ChatPharoSettings default welcomeMessageEnabled: false.
        chat := ChatPharoChat new agent: ChatPharoMockAgent new.
        chat addUserMessage: 'How are you?'.

        self assert: chat messages size equals: 1.
        self assert: chat messages last content equals: 'How are you?'
]

{ #category : 'running' }
ChatPharoUsabilityTest >> testChatAddWelcomeMessageSetsFriendlyLabel [

        | chat |
        ChatPharoSettings default welcomeMessageEnabled: false.
        chat := ChatPharoChat new agent: ChatPharoMockAgent new.
        chat addUserMessage: 'start'.
        chat addAssistantMessage: 'reply'.
        chat addWelcomeMessage.

        self assert: chat messages last assistantLabel equals: 'ChatPharo'.
        self assert: (chat messages last answer includesSubstring: 'Welcome to ChatPharo')
]

{ #category : 'running' }
ChatPharoUsabilityTest >> testChatClearChatRemovesMessagesHistoryAndCache [
        | chat cache history |
        ChatPharoSettings default welcomeMessageEnabled: false.
        chat := ChatPharoChat new agent: ChatPharoMockAgent new.
        chat sendMessage: 'clear me'.
        self waitForChatProcess: chat.
        chat clearChat.
        cache := chat instVarNamed: #cache.
        history := chat instVarNamed: #history.

        self assert: chat messages isEmpty.
        self assert: cache isEmpty.
        self assert: history messages isEmpty
]

{ #category : 'running' }
ChatPharoUsabilityTest >> testChatClearChatTerminatesPromptProcess [
        | chat process |
        ChatPharoSettings default welcomeMessageEnabled: false.
        chat := ChatPharoChat new agent: ChatPharoMockAgent new.
        chat sendMessage: 'cancel soon'.
        (Delay forMilliseconds: 1) wait.
        chat clearChat.
        process := chat instVarNamed: #promptProcess.

        self assert: (process isNil or: [ process isTerminated ])
]

{ #category : 'running' }
ChatPharoUsabilityTest >> testChatInitializationAddsWelcomeMessageToHistory [
        | chat history |
        ChatPharoSettings default welcomeMessageEnabled: true.
        chat := ChatPharoChat new agent: ChatPharoMockAgent new.
        history := chat instVarNamed: #history.

        self assert: history messages size equals: 1.
        self assert: (history messages first role) equals: 'assistant'.
        self assert: ((history messages first content)
                includesSubstring: 'Welcome to ChatPharo')
]

{ #category : 'running' }
ChatPharoUsabilityTest >> testChatMessagePresenterIsReused [

        | message presenter |
        message := ChatPharoMessage new.
        presenter := message presenter.

        self assert: presenter == message presenter
]

{ #category : 'running' }
ChatPharoUsabilityTest >> testChatMessageStartsWithEmptyStrings [
        | message |
        message := ChatPharoMessage new.

        self assert: message content isEmpty.
        self assert: message answer isEmpty
]

{ #category : 'running' }
ChatPharoUsabilityTest >> testChatSendMessageTriggersAnswerReceivedCallback [
        | chat captured |
        captured := nil.
        ChatPharoSettings default welcomeMessageEnabled: false.
        chat := ChatPharoChat new agent: ChatPharoMockAgent new.
        chat whenAnswerReceivedDo: [ :message | captured := message ].
        chat sendMessage: 'callback please'.
        self waitForChatProcess: chat.

        self assert: captured equals: chat messages last.
        self assert: captured content equals: 'callback please'
]

{ #category : 'running' }
ChatPharoUsabilityTest >> testChatSendMessageTwiceMaintainsOrder [
        | chat |
        ChatPharoSettings default welcomeMessageEnabled: false.
        chat := ChatPharoChat new agent: ChatPharoMockAgent new.
        chat sendMessage: 'first'.
        self waitForChatProcess: chat.
        chat sendMessage: 'second'.
        self waitForChatProcess: chat.

        self assert: chat messages size equals: 2.
        self assert: chat messages first content equals: 'first'.
        self assert: chat messages last content equals: 'second'
]

{ #category : 'running' }
ChatPharoUsabilityTest >> testChatWithNullAgentUsesAssistantBotLabel [
        | chat |
        ChatPharoSettings default welcomeMessageEnabled: false.
        chat := ChatPharoChat new agent: ChatPharoNullAgent new.
        chat sendMessage: 'hello'.
        self waitForChatProcess: chat.

        self assert: chat messages size equals: 1.
        self assert: chat messages last assistantLabel equals: 'Assistant bot'.
        self assert: (chat messages last answer includesSubstring: 'No backend is configured')
]

{ #category : 'running' }
ChatPharoUsabilityTest >> testChatWithWelcomeDisabledStartsEmpty [
        | chat |
        ChatPharoSettings default welcomeMessageEnabled: false.
        chat := ChatPharoChat new agent: ChatPharoMockAgent new.

        self assert: chat messages isEmpty
]

{ #category : 'running' }
ChatPharoUsabilityTest >> testSettingsAskFeatureEnabledByDefault [
        self assert: settings askFeatureEnabled
]

{ #category : 'running' }
ChatPharoUsabilityTest >> testSettingsAvailableApiChoicesExposeDisplayNames [
        | choices nullChoice |
        choices := settings availableApiChoices.
        self deny: choices isEmpty.
        nullChoice := choices detect: [ :assoc | assoc key = 'None (offline)' ].

        self assert: nullChoice value equals: ChatPharoNullAgent.
        self assert: (choices collect: [ :assoc | assoc key ]) asSet size equals: choices size
]

{ #category : 'running' }
ChatPharoUsabilityTest >> testSettingsBrowserAutoTabEnabledByDefault [

        self assert: settings browserAutoTabEnabled
]

{ #category : 'running' }
ChatPharoUsabilityTest >> testSettingsBrowserToolDisableIsIdempotent [
        | tool |
        tool := settings browserToolsEnabled first.
        settings disableBrowserTool: tool.
        settings disableBrowserTool: tool.

        self deny: (settings browserToolsEnabled includes: tool)
]

{ #category : 'running' }
ChatPharoUsabilityTest >> testSettingsBrowserToolEnableReaddsRemovedTool [
        | tool |
        tool := settings browserToolsEnabled first.
        settings disableBrowserTool: tool.
        self deny: (settings browserToolsEnabled includes: tool).
        settings enableBrowserTool: tool.

        self assert: (settings browserToolsEnabled includes: tool)
]

{ #category : 'running' }
ChatPharoUsabilityTest >> testSettingsBrowserToolsEnabledProvideNames [
        self assert: (settings browserToolsEnabled allSatisfy: [ :each |
                each isString and: [ each notEmpty ] ])
]

{ #category : 'running' }
ChatPharoUsabilityTest >> testSettingsCacheEnabledToggleUpdatesValue [
        self assert: settings cacheEnabled.
        settings cacheEnabled: false.
        self deny: settings cacheEnabled.
        settings cacheEnabled: true.
        self assert: settings cacheEnabled
]

{ #category : 'running' }
ChatPharoUsabilityTest >> testSettingsCodeFeatureEnabledByDefault [

        self assert: settings codeFeatureEnabled
]

{ #category : 'running' }
ChatPharoUsabilityTest >> testSettingsDefaultMaximumIterationsIsThree [
        self assert: settings maximumIterations equals: 3
]

{ #category : 'running' }
ChatPharoUsabilityTest >> testSettingsEnableBrowserToolAvoidsDuplicates [
        | tool initialSize |
        tool := settings browserToolsEnabled first.
        initialSize := settings browserToolsEnabled size.
        settings enableBrowserTool: tool.

        self assert: settings browserToolsEnabled size equals: initialSize
]

{ #category : 'running' }
ChatPharoUsabilityTest >> testSettingsMaximumIterationsClampedToAtLeastOne [
        settings maximumIterations: 0.
        self assert: settings maximumIterations equals: 1
]

{ #category : 'running' }
ChatPharoUsabilityTest >> testSettingsUseModelUpdatesAgentModel [
        settings useModel: 'custom-model'.
        self assert: settings agent model equals: 'custom-model'
]

{ #category : 'running' }
ChatPharoUsabilityTest >> waitForChatProcess: aChat [
        [
                | process |
                process := aChat instVarNamed: #promptProcess.
                process isNil or: [ process isTerminated ]
        ] whileFalse: [ (Delay forMilliseconds: 10) wait ]
]
