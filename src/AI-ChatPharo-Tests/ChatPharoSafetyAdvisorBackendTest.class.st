Class {
	#name : 'ChatPharoSafetyAdvisorBackendTest',
	#superclass : 'TestCase',
	#instVars : [
		'presenter'
	],
	#category : 'AI-ChatPharo-Tests-Security',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Security'
}

{ #category : 'running' }
ChatPharoSafetyAdvisorBackendTest >> setUp [

    super setUp.
    presenter := ChatPharoSafetyAdvisorPresenterStub new.
]

{ #category : 'tests' }
ChatPharoSafetyAdvisorBackendTest >> testConfirmEthicsSettingChangeDelegatesToPresenter [

	ChatPharoSafetyAdvisor confirmEthicsSettingChangeOn: presenter.
	self assert: presenter messages first equals: ChatPharoSafetyAdvisor ethicsSettingChangeMessage.
]

{ #category : 'running' }
ChatPharoSafetyAdvisorBackendTest >> testConfirmMaxIterationsDelegatesToPresenter [

    ChatPharoSafetyAdvisor confirmMaxIterationsOn: presenter.
    self assert: presenter messages first equals: ChatPharoSafetyAdvisor maxIterationsMessage.
]

{ #category : 'running' }
ChatPharoSafetyAdvisorBackendTest >> testConfirmMaxIterationsRespectsPresenterAnswer [

    presenter nextAnswer: false.
    self deny: (ChatPharoSafetyAdvisor confirmMaxIterationsOn: presenter).
]

{ #category : 'tests' }
ChatPharoSafetyAdvisorBackendTest >> testConfirmMessageLimitChangeDelegatesToPresenter [

	ChatPharoSafetyAdvisor confirmMessageLimitChangeOn: presenter.
	self assert: presenter messages first equals: ChatPharoSafetyAdvisor messageLimitChangeMessage.
]

{ #category : 'running' }
ChatPharoSafetyAdvisorBackendTest >> testConfirmPromptModificationDelegatesToPresenter [

    ChatPharoSafetyAdvisor confirmPromptModificationOn: presenter.
    self assert: presenter messages first equals: ChatPharoSafetyAdvisor promptChangeMessage.
]

{ #category : 'running' }
ChatPharoSafetyAdvisorBackendTest >> testConfirmToolDisableDelegatesToPresenter [

    ChatPharoSafetyAdvisor confirmToolDisableOn: presenter.
    self assert: presenter messages first equals: ChatPharoSafetyAdvisor toolDisableMessage.
]

{ #category : 'tests' }
ChatPharoSafetyAdvisorBackendTest >> testDefaultsApplyUpdatesSettings [

	| settings steps |
	settings := ChatPharoSafetyAdvisorSettingsStub new.
	steps := ChatPharoSafetyAdvisor applyDefaultSettingsTo: settings.
	steps do: [ :step | step value: [ :message | message ] ].
	self assert: settings useApiClass equals: ChatPharoGeminiAgent.
	self assert: settings allowAllBrowserTools.
	self assert: settings browserExtensionEnabled.
	self assert: settings automaticSkillsEnabled.
	self assert: settings skillToolsEnabled.
	self assert: settings askFeatureEnabled.
	self assert: settings codeFeatureEnabled.
	self assert: settings cacheEnabled.
	self deny: settings feedbackButtonsEnabled.
	self assert: settings welcomeMessageEnabled.
	self assert: settings loggingEnabled.
	self assert: settings sandboxEnabled.
	self assert: settings sandboxRestrictFileSystem.
	self assert: settings sandboxRestrictNetwork.
	self assert: settings sandboxRestrictSystemAccess.
	self assert: settings sandboxTimeout equals: 5000.
	self assert: settings maximumIterations equals: 3.
	self assert: settings advisorDefaultsConfigured.
]

{ #category : 'tests' }
ChatPharoSafetyAdvisorBackendTest >> testDefaultsStepCountMatchesTotal [

	| settings steps |
	settings := ChatPharoSafetyAdvisorSettingsStub new.
	steps := ChatPharoSafetyAdvisor applyDefaultSettingsTo: settings.
	self assert: steps size equals: ChatPharoSafetyAdvisor totalDefaultSteps.
]

{ #category : 'running' }
ChatPharoSafetyAdvisorBackendTest >> testMaxIterationsMessageMatchesExpectedText [

    self assert: (ChatPharoSafetyAdvisor maxIterationsMessage includesSubstring: 'Maximum iterations').
]

{ #category : 'running' }
ChatPharoSafetyAdvisorBackendTest >> testPromptChangeMessageIncludesRecommendation [

    self assert: (ChatPharoSafetyAdvisor promptChangeMessage includesSubstring: 'optimal performance').
]

{ #category : 'tests' }
ChatPharoSafetyAdvisorBackendTest >> testRequireDeveloperAllowsDeveloper [

	| previousValue wasExecuted |
	previousValue := ChatPharoSettings default isDeveloper.
	wasExecuted := false.
	[
		ChatPharoSettings default isDeveloper: true.
		ChatPharoSafetyAdvisor
			requireDeveloperFor: [ wasExecuted := true ]
			otherwiseOn: presenter.
		self assert: wasExecuted.
		self assert: presenter alerts isEmpty.
	] ensure: [ ChatPharoSettings default isDeveloper: previousValue ].
]

{ #category : 'tests' }
ChatPharoSafetyAdvisorBackendTest >> testRequireDeveloperBlocksNonDeveloper [

	| previousValue wasExecuted |
	previousValue := ChatPharoSettings default isDeveloper.
	wasExecuted := false.
	[
		ChatPharoSettings default isDeveloper: false.
		ChatPharoSafetyAdvisor
			requireDeveloperFor: [ wasExecuted := true ]
			otherwiseOn: presenter.
		self deny: wasExecuted.
		self assert: presenter alerts first equals: ChatPharoSafetyAdvisor ethicsSettingChangeMessage.
	] ensure: [ ChatPharoSettings default isDeveloper: previousValue ].
]

{ #category : 'running' }
ChatPharoSafetyAdvisorBackendTest >> testToolDisableMessageIncludesWarning [

    self assert: (ChatPharoSafetyAdvisor toolDisableMessage includesSubstring: 'keeping all tools enabled').
]
