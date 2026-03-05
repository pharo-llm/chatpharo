Class {
	#name : 'ChatPharoSettingsBackendTest',
	#superclass : 'TestCase',
	#instVars : [
		'settings'
	],
	#category : 'AI-ChatPharo-Tests-Spec',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Spec'
}

{ #category : 'running' }
ChatPharoSettingsBackendTest >> setUp [

    super setUp.
    ChatPharoSettings resetDefault.
    ChatPharoLogger loggingEnabled: true.
    ChatPharoLogger deleteLogFile.
    ChatPharoSettings settingsDirectory exists
        ifTrue: [ ChatPharoSettings settingsDirectory ensureDeleteAll ].
    settings := ChatPharoSettings new.
    ChatPharoSettings setDefault: settings.
    ChatPharoLogger deleteLogFile.
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> tearDown [

    ChatPharoLogger deleteLogFile.
    ChatPharoLogger logDirectory exists
        ifTrue: [ ChatPharoLogger logDirectory ensureDeleteAll ].
    ChatPharoSettings settingsDirectory exists
        ifTrue: [ ChatPharoSettings settingsDirectory ensureDeleteAll ].
    ChatPharoSettings resetDefault.
    super tearDown.

]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testAskFeatureEnabledDefaultsToTrue [

    self assert: settings askFeatureEnabled.
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testAskFeatureEnabledSetterUpdatesFlag [

    settings askFeatureEnabled: false.
    self deny: settings askFeatureEnabled.
    settings askFeatureEnabled: true.
    self assert: settings askFeatureEnabled.
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testAvailableApiChoicesUseDisplayNamesAsKeys [

    | choices |
    choices := settings availableApiChoices.
    self deny: choices isEmpty.
    choices do: [ :assoc |
        self assert: assoc key equals: assoc value displayName ].
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testAvailableApisIncludesGeminiAgent [

    self assert: (settings availableApis includes: ChatPharoGeminiAgent).
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testAvailableApisIncludesNullAgent [

    self assert: (settings availableApis includes: ChatPharoNullAgent).
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testAvailableApisIncludesOllamaAgent [

    self assert: (settings availableApis includes: ChatPharoOllamaAgent).
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testBrowserAutoTabEnabledDefaultsToTrue [

    self assert: settings browserAutoTabEnabled.
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testBrowserAutoTabEnabledSetterUpdatesFlag [

    settings browserAutoTabEnabled: false.
    self deny: settings browserAutoTabEnabled.
    settings browserAutoTabEnabled: true.
    self assert: settings browserAutoTabEnabled.
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testBrowserExtensionDisabledByDefault [

    self deny: settings browserExtensionEnabled.
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testBrowserExtensionSetterUpdatesFlag [

    settings browserExtensionEnabled: true.
    self assert: settings browserExtensionEnabled.
    settings browserExtensionEnabled: false.
    self deny: settings browserExtensionEnabled.
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testBrowserToolsEnabledInitialisedFromEnvironment [

    | environmentTools |
    environmentTools := ChatPharoBrowserEnvironment new tools collect: [ :tool | tool name ].
    self assert: settings browserToolsEnabled asArray equals: environmentTools asArray.
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testBrowserToolsEnabledSetterReplacesCollection [

    | newTools |
    newTools := OrderedCollection with: 'one' with: 'two'.
    settings browserToolsEnabled: newTools.
    self assert: settings browserToolsEnabled asArray equals: #('one' 'two').
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testCacheEnabledDefaultsToTrue [

    self assert: settings cacheEnabled.
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testCacheEnabledSetterUpdatesFlag [

    settings cacheEnabled: false.
    self deny: settings cacheEnabled.
    settings cacheEnabled: true.
    self assert: settings cacheEnabled.
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testCodeFeatureEnabledDefaultsToTrue [

    self assert: settings codeFeatureEnabled.
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testCodeFeatureEnabledSetterUpdatesFlag [

    settings codeFeatureEnabled: false.
    self deny: settings codeFeatureEnabled.
    settings codeFeatureEnabled: true.
    self assert: settings codeFeatureEnabled.
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testDefaultAgentIsNullAgent [

    self assert: settings agent class equals: ChatPharoNullAgent.
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testDisableBrowserToolRemovesEntry [

    | tool |
    tool := settings browserToolsEnabled first.
    settings disableBrowserTool: tool.
    self deny: (settings browserToolsEnabled includes: tool).
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testEnableBrowserToolAddsPreviouslyRemovedTool [

    | tool |
    tool := settings browserToolsEnabled first.
    settings disableBrowserTool: tool.
    settings enableBrowserTool: tool.
    self assert: (settings browserToolsEnabled includes: tool).
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testEnableBrowserToolDoesNotDuplicateEntries [

    | tool originalSize |
    tool := settings browserToolsEnabled first.
    originalSize := settings browserToolsEnabled size.
    settings enableBrowserTool: tool.
    self assert: settings browserToolsEnabled size equals: originalSize.
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testFeedbackButtonsEnabledDefaultsToFalse [

    self deny: settings feedbackButtonsEnabled.
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testFeedbackButtonsEnabledSetterUpdatesFlag [

    settings feedbackButtonsEnabled: false.
    self deny: settings feedbackButtonsEnabled.
    settings feedbackButtonsEnabled: true.
    self assert: settings feedbackButtonsEnabled.
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testInitializeLogsSystemEntry [

    | contents |
    ChatPharoLogger deleteLogFile.
    settings := ChatPharoSettings new.
    contents := ChatPharoLogger logFile readStreamDo: [ :stream | stream contents ].
    self assert: (contents includesSubstring: 'Settings initialized').
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testLoggingEnabledDefaultsToTrue [

    self assert: settings loggingEnabled.
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testLoggingEnabledSetterTogglesFlag [

    settings loggingEnabled: false.
    self deny: settings loggingEnabled.
    settings loggingEnabled: true.
    self assert: settings loggingEnabled.
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testMaximumIterationsClampedToMinimumOfOne [

    settings maximumIterations: 0.
    self assert: settings maximumIterations equals: 1.
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testMaximumIterationsSetterPersistsValue [

    settings maximumIterations: 17.
    self assert: settings maximumIterations equals: 17.
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testModelsReflectAgentModelNames [

    self assert: settings models equals: ChatPharoNullAgent modelNames.
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testUseApiSwitchesAgentClass [

    settings useApi: ChatPharoGeminiAgent.
    self assert: settings agent class equals: ChatPharoGeminiAgent.
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testUseModelUpdatesAgentModel [

    settings useModel: 'custom-model'.
    self assert: settings agent model equals: 'custom-model'.
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testWelcomeMessageEnabledDefaultsToTrue [

    self deny: settings welcomeMessageEnabled.
]

{ #category : 'running' }
ChatPharoSettingsBackendTest >> testWelcomeMessageEnabledSetterUpdatesFlag [

    settings welcomeMessageEnabled: false.
    self deny: settings welcomeMessageEnabled.
    settings welcomeMessageEnabled: true.
    self assert: settings welcomeMessageEnabled.
]
