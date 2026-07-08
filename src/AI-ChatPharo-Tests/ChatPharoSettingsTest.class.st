Class {
	#name : 'ChatPharoSettingsTest',
	#superclass : 'TestCase',
	#instVars : [
		'settings',
		'mockApi'
	],
	#category : 'AI-ChatPharo-Tests-Settings',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Settings'
}

{ #category : 'running' }
ChatPharoSettingsTest >> setUp [

	super setUp.
	
	settings := ChatPharoSettings new.
	mockApi := ChatPharoMockAgent new.
	settings instVarNamed: #agent put: mockApi
]

{ #category : 'running' }
ChatPharoSettingsTest >> tearDown [

	ChatPharoSettings resetDefault.
	super tearDown
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testAskFeatureEnabledDefaultsTrue [

    self assert: settings askFeatureEnabled
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testAskFeatureEnabledToggle [

    settings askFeatureEnabled: false.
    self deny: settings askFeatureEnabled.
    settings askFeatureEnabled: true.
    self assert: settings askFeatureEnabled
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testAvailableApiChoicesReturnsAssociations [
	| choices |
	choices := settings availableApiChoices.
	self assert: (choices allSatisfy: [ :assoc | assoc key isString and: [ assoc value isClass ] ]).
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testAvailableApisIncludesDefaultAgents [

    self assert: (settings availableApis includesAll: {
            ChatPharoNullAgent.
            ChatPharoGeminiAgent.
            ChatPharoOllamaAgent.
            ChatPharoMistralAgent })
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testBrowserAutoTabAccessor [

    self assert: settings browserAutoTabEnabled.
    settings browserAutoTabEnabled: false.
    self deny: settings browserAutoTabEnabled

]

{ #category : 'tests' }
ChatPharoSettingsTest >> testBrowserExtensionEnabledAccessor [ 

    self deny: settings browserExtensionEnabled.
    settings browserExtensionEnabled: true.
    self assert: settings browserExtensionEnabled.
    settings browserExtensionEnabled: false.
    self deny: settings browserExtensionEnabled
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testBrowserToolsEnabledDefault [ 
        self deny: settings browserToolsEnabled isNil.
        self assert: settings browserToolsEnabled notEmpty
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testBrowserToolsEnabledSetterReplacesCollection [

    | tools |
    tools := OrderedCollection with: 'A' with: 'B'.
    settings browserToolsEnabled: tools.
    self assert: settings browserToolsEnabled identicalTo: tools
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testCacheEnabledDefaultIsTrue [

    self assert: settings cacheEnabled
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testCacheEnabledToggle [

    self assert: settings cacheEnabled.

    settings cacheEnabled: false.
    self deny: settings cacheEnabled.

    settings cacheEnabled: true.
    self assert: settings cacheEnabled.
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testCodeFeatureEnabledDefaultsTrue [

    self assert: settings codeFeatureEnabled
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testCodeFeatureEnabledToggle [

    settings codeFeatureEnabled: false.
    self deny: settings codeFeatureEnabled.
    settings codeFeatureEnabled: true.
    self assert: settings codeFeatureEnabled
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testDisableBrowserToolIgnoresUnknownTool [

    | snapshot |
    snapshot := settings browserToolsEnabled copy.
    settings disableBrowserTool: 'non-existent tool'.
    self assert: settings browserToolsEnabled equals: snapshot
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testEnableBrowserToolAddsMissingTool [

    settings browserToolsEnabled: OrderedCollection new.
    settings enableBrowserTool: 'NewTool'.
    self assert: (settings browserToolsEnabled includes: 'NewTool')
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testEnableBrowserToolDoesNotDuplicate [

    | name count |
    name := settings browserToolsEnabled anyOne.
    count := settings browserToolsEnabled occurrencesOf: name.
    settings enableBrowserTool: name.
    self assert: (settings browserToolsEnabled occurrencesOf: name) equals: count.
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testEnableBrowserToolResetsMaximumIterations [

    settings maximumIterations: 10.
    settings enableBrowserTool: settings browserToolsEnabled anyOne.
    self assert: settings maximumIterations equals: 3.
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testEnableDisableBrowserTool [ 

        | name |
        name := settings browserToolsEnabled anyOne.
        settings disableBrowserTool: name.
        self deny: (settings browserToolsEnabled includes: name).
        settings enableBrowserTool: name.
        self assert: (settings browserToolsEnabled includes: name)
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testFeedbackButtonsEnabledToggle [

    self deny: settings feedbackButtonsEnabled.
    settings feedbackButtonsEnabled: false.
    self deny: settings feedbackButtonsEnabled.
    settings feedbackButtonsEnabled: true.
    self assert: settings feedbackButtonsEnabled.
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testLoggingEnabledDefaultsTrue [

    self assert: settings loggingEnabled
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testLoggingEnabledToggleAlsoUpdatesLogger [

    | original |
    original := ChatPharoLogger loggingEnabled.
    settings loggingEnabled: false.
    self deny: settings loggingEnabled.
    self deny: ChatPharoLogger loggingEnabled.
    settings loggingEnabled: true.
    self assert: settings loggingEnabled.
    self assert: ChatPharoLogger loggingEnabled.
    ChatPharoLogger loggingEnabled: original
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testMaximumIterationsAccessor [ 

    settings maximumIterations: 8.
    self assert: settings maximumIterations equals: 8
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testMaximumIterationsLowerBound [ 

    settings maximumIterations: 0.
    self assert: settings maximumIterations equals: 1.

    settings maximumIterations: -3.
    self assert: settings maximumIterations equals: 1
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testModelsDelegation [
	self
		assert: settings models
		equals: (ChatPharoMockAgent modelNames).

]

{ #category : 'tests' }
ChatPharoSettingsTest >> testSwitchModelAfterAgentSwitch [ 

    settings useApi: ChatPharoMockAgent.
    settings useModel: 'mock-advanced'.

    self assert: settings agent model equals: 'mock-advanced'.
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testSwitchingAgentPreservesModel [ 

    settings useApi: ChatPharoMockAgent.
    settings useModel: 'mock-advanced'.
    self assert: settings agent model equals: 'mock-advanced'.
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testUseApiReplacesAgentSubclass [ 

    settings useApi: ChatPharoNullAgent.
    self assert: settings agent class equals: ChatPharoNullAgent.
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testUseModel [
	settings useModel: 'mock-advanced'.
	self assert: (mockApi instVarNamed: #currentModel) equals: 'mock-advanced'.
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testWelcomeMessageEnabledToggle [

    self deny: settings welcomeMessageEnabled.
    settings welcomeMessageEnabled: false.
    self deny: settings welcomeMessageEnabled.
    settings welcomeMessageEnabled: true.
    self assert: settings welcomeMessageEnabled.
]
