"
Provides centralized safety guidance and default setup behavior for ChatPharo.

This advisor class is responsible for:
- applying a curated, secure default configuration in progressive steps,
- presenting confirmation prompts before risky setting changes,
- warning users when enabling external APIs, and
- enforcing developer-only safeguards for sensitive operations.
"
Class {
	#name : 'ChatPharoSafetyAdvisor',
	#superclass : 'Object',
	#category : 'AI-ChatPharo-Safety',
	#package : 'AI-ChatPharo-Safety'
}

{ #category : 'settings' }
ChatPharoSafetyAdvisor class >> applyDefaultSettingsTo: aSettings [
	"Apply all recommended default settings to the given settings object.
	 Returns an OrderedCollection of step descriptions for progress tracking."

	| steps |
	steps := OrderedCollection new.

	"Step 1: Configure the recommended agent (Gemini)"
	steps add: [ :progressBlock |
		progressBlock value: 'Configuring AI agent...'.
		aSettings useApi: ChatPharoGeminiAgent.
		10 milliSeconds wait ].

	"Step 2: Enable all browser tools"
	steps add: [ :progressBlock |
		progressBlock value: 'Enabling browser tools...'.
		aSettings enableAllBrowserTools.
		10 milliSeconds wait ].

	"Step 3: Enable browser extension"
	steps add: [ :progressBlock |
		progressBlock value: 'Enabling browser extension...'.
		aSettings browserExtensionEnabled: true.
		10 milliSeconds wait ].

	"Step 4: Configure skills"
	steps add: [ :progressBlock |
		progressBlock value: 'Configuring skills...'.
		aSettings automaticSkillsEnabled: true.
		aSettings skillToolsEnabled: true.
		10 milliSeconds wait ].

	"Step 5: Enable ask and code features"
	steps add: [ :progressBlock |
		progressBlock value: 'Enabling code features...'.
		aSettings askFeatureEnabled: true.
		aSettings codeFeatureEnabled: true.
		10 milliSeconds wait ].

	"Step 6: Configure caching and feedback"
	steps add: [ :progressBlock |
		progressBlock value: 'Configuring caching...'.
		aSettings cacheEnabled: true.
		aSettings feedbackButtonsEnabled: false.
		10 milliSeconds wait ].

	"Step 7: Configure welcome message and logging"
	steps add: [ :progressBlock |
		progressBlock value: 'Configuring interface...'.
		aSettings welcomeMessageEnabled: true.
		aSettings loggingEnabled: true.
		10 milliSeconds wait ].

	"Step 8: Configure sandbox (safe defaults)"
	steps add: [ :progressBlock |
		progressBlock value: 'Configuring security sandbox...'.
		aSettings sandboxEnabled: true.
		aSettings sandboxRestrictFileSystem: true.
		aSettings sandboxRestrictNetwork: true.
		aSettings sandboxRestrictSystemAccess: true.
		aSettings sandboxTimeout: 5000.
		10 milliSeconds wait ].

	"Step 9: Set maximum iterations"
	steps add: [ :progressBlock |
		progressBlock value: 'Setting optimization parameters...'.
		aSettings maximumIterations: 3.
		10 milliSeconds wait ].

	"Step 10: Mark advisor defaults as configured"
	steps add: [ :progressBlock |
		progressBlock value: 'Finalizing configuration...'.
		aSettings advisorDefaultsConfigured: true.
		10 milliSeconds wait ].

	^ steps
]

{ #category : 'ethics' }
ChatPharoSafetyAdvisor class >> confirmEthicsSettingChangeOn: aPresenter [
	"Confirm that the user wants to change ethics settings, warning about context performance impact."

	^ aPresenter confirm: self ethicsSettingChangeMessage
]

{ #category : 'safety' }
ChatPharoSafetyAdvisor class >> confirmExternalApiUsageOn: aPresenter forAgent: anAgentClass [
	"Show a warning when the user selects an external API agent.
	Returns true if the user agrees to proceed, false otherwise.
	If the warning was previously dismissed by a verified developer, skip showing it."

	| settings |
	settings := ChatPharoSettings default.

	"Skip warning for non-external (local) agents"
	anAgentClass isExternalApi ifFalse: [ ^ true ].

	"Skip warning if previously dismissed by a verified developer"
	(settings externalApiWarningDismissed and: [ settings isDeveloper ])
		ifTrue: [ ^ true ].

	^ self showExternalApiWarningOn: aPresenter
]

{ #category : 'safety' }
ChatPharoSafetyAdvisor class >> confirmMaxIterationsOn: aPresenter [

    ^ aPresenter confirm: self maxIterationsMessage
]

{ #category : 'safety' }
ChatPharoSafetyAdvisor class >> confirmMessageLimitChangeOn: aPresenter [
	"Confirm that the user wants to change the message limit, warning about context performance impact."

	^ aPresenter confirm: self messageLimitChangeMessage
]

{ #category : 'safety' }
ChatPharoSafetyAdvisor class >> confirmPromptModificationOn: aPresenter [ 

    ^ aPresenter confirm: self promptChangeMessage
]

{ #category : 'safety' }
ChatPharoSafetyAdvisor class >> confirmToolDisableOn: aPresenter [ 

    ^ aPresenter confirm: self toolDisableMessage
]

{ #category : 'settings' }
ChatPharoSafetyAdvisor class >> defaultSettingsDescription [
	"Return a description of what the default settings include"

	^ String streamContents: [ :stream |
		stream
			nextPutAll: 'The Advisor recommends the following configuration:'; cr; cr;
			nextPutAll: '• AI Agent: Gemini (Google AI)'; cr;
			nextPutAll: '• All browser tools enabled'; cr;
			nextPutAll: '• Browser extension enabled'; cr;
			nextPutAll: '• Automatic skills detection enabled'; cr;
			nextPutAll: '• Code assistant features enabled'; cr;
			nextPutAll: '• Response caching enabled'; cr;
			nextPutAll: '• Security sandbox enabled'; cr;
			nextPutAll: '• Welcome messages enabled'; cr; cr;
			nextPutAll: 'These settings provide the best experience for most users.' ]
]

{ #category : 'settings' }
ChatPharoSafetyAdvisor class >> defaultsPromptMessage [
	"Message shown when asking user about default settings"

	^ 'Would you like to use the recommended settings proposed by the Advisor?
This will automatically configure ChatPharo with optimal settings including:
- AI agent selection
- Tool configurations
- Security settings
- Interface preferences
You can always customize these settings later.'
]

{ #category : 'ethics' }
ChatPharoSafetyAdvisor class >> ethicsSettingChangeMessage [

	^ 'Ethics settings can only be changed by developers.\nPlease verify your developer ID in the Personal tab first.'
]

{ #category : 'safety' }
ChatPharoSafetyAdvisor class >> externalApiWarningMessage [
	"Warning message shown when selecting an external API agent"

	^ 'WARNING: External API Provider
By selecting this agent, your data (including chat messages and code) will be sent to an external third-party provider. This data may be stored, processed, or retained by the provider according to their terms of service.
Please ensure you are not sharing sensitive, confidential, or proprietary information.
Do you agree to proceed?
(If you are a verified developer and do not want to see this warning again, please verify your Developer ID in the Personal settings tab.)'
]

{ #category : 'settings' }
ChatPharoSafetyAdvisor class >> isValidMessageLimit: aNumber [
	"A message limit must be a positive integer. Zero or negative values are
	 forbidden because they would silently disable all conversations."

	^ aNumber notNil
		and: [ aNumber isNumber
		and: [ aNumber >= 1 ] ]
]

{ #category : 'safety' }
ChatPharoSafetyAdvisor class >> maxIterationsMessage [

    ^ 'Maximum iterations must be at least 1.\nSet value to 1?'
]

{ #category : 'safety' }
ChatPharoSafetyAdvisor class >> messageLimitChangeMessage [ 

	^ 'Changing the message limit will impact context performance and memory usage.\nHigher limits may slow down responses and increase token consumption.\nAre you sure you want to change this setting?'
]

{ #category : 'settings' }
ChatPharoSafetyAdvisor class >> noRightToSetMessageLimitMessage: aNumber [

	^ 'You have no right to do that.', String cr,
	  'The Ethics Director forbids setting the message limit to ',
	  (aNumber ifNil: [ 'an empty value' ] ifNotNil: [ aNumber asString ]),
	  '.', String cr,
	  'A message limit of zero or less would disable all conversation,',
	  ' which violates the ethics mandate. The minimum allowed value is 1.'
]

{ #category : 'safety' }
ChatPharoSafetyAdvisor class >> promptChangeMessage [ 

    ^ 'For optimal performance we recommend you to not change the prompt.\nAre you sure you want to modify it?'
]

{ #category : 'settings' }
ChatPharoSafetyAdvisor class >> rejectMessageLimitOn: aPresenter for: aNumber [
	"Show a hard rejection when the user tries to set an invalid message limit
	 (e.g. zero). The Ethics Director denies this regardless of developer status."

	aPresenter alert: (self noRightToSetMessageLimitMessage: aNumber)
]

{ #category : 'safety' }
ChatPharoSafetyAdvisor class >> requireDeveloperFor: aBlock otherwiseOn: aPresenter [
	"Execute aBlock only if the current user is a developer. Otherwise show a warning."

	ChatPharoSettings default isDeveloper
		ifTrue: [ aBlock value ]
		ifFalse: [ aPresenter alert: self ethicsSettingChangeMessage ]
]

{ #category : 'safety' }
ChatPharoSafetyAdvisor class >> showExternalApiWarningOn: aPresenter [
	"Display the external API data warning dialog.
	If the user is a verified developer, offer to dismiss the warning permanently.
	Returns true if user agrees, false if user declines."

	| userAgreed settings |
	userAgreed := aPresenter confirm: self externalApiWarningMessage.

	userAgreed ifTrue: [
		settings := ChatPharoSettings default.
		(settings isDeveloper and: [ settings externalApiWarningDismissed not ]) ifTrue: [
			(aPresenter confirm: 'As a verified developer, would you like to stop showing this warning in the future?')
				ifTrue: [ settings externalApiWarningDismissed: true ] ] ].

	^ userAgreed
]

{ #category : 'safety' }
ChatPharoSafetyAdvisor class >> toolDisableMessage [ 

    ^ 'For optimal performance we recommend keeping all tools enabled.\nAre you sure you want to disable this tool?'
]

{ #category : 'safety' }
ChatPharoSafetyAdvisor class >> totalDefaultSteps [
	"Return the total number of steps for applying defaults"

	^ 10
]
