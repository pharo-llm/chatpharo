"
User-editable configuration.

* Knows the currently selected `agent`.
* Produces the list of **available API choices** by returning associations `displayName -> class`.
* Delegates model selection (`useModel:`) and agent swapping (`useApi:`) to the agent it owns.
* **Why** – separates persistent/user-configurable concerns from transient chat state.


```smalltalk
(ChatPharoSettings new
	useModel: 'codellama:7b';
	ollamaApi)
		getResponseForPrompt: 'Bonjour'.

```
"
Class {
	#name : 'ChatPharoSettings',
	#superclass : 'Object',
	#instVars : [
		'agent',
		'browserExtensionEnabled',
		'debuggerExtensionEnabled',
		'icebergExtensionEnabled',
		'commitMessageTemplate',
		'icebergSystemPrompt',
		'debuggerSystemPrompt',
		'browserToolsEnabled',
		'maximumIterations',
		'browserAutoTabEnabled',
		'cacheEnabled',
		'feedbackButtonsEnabled',
		'welcomeMessageEnabled',
		'loggingEnabled',
		'askFeatureEnabled',
		'codeFeatureEnabled',
		'skillsEnabled',
		'automaticSkillsEnabled',
		'skillToolsEnabled',
		'skillFilePaths',
		'isConfigured',
		'isDeveloper',
		'developerId',
		'userName',
		'userOrganization',
		'ethicsDirector',
		'ethicsDirectorEnabled',
		'ethicsMandate',
		'cognitiveLoadBudget',
		'tokenBudget',
		'timeBudgetMinutes',
		'multivers',
		'sandboxEnabled',
		'sandboxRestrictFileSystem',
		'sandboxRestrictNetwork',
		'sandboxRestrictSystemAccess',
		'sandboxTimeout',
		'userLevel',
		'tutorialCompleted',
		'wantsTutorial',
		'customTools',
		'advisorDefaultsConfigured',
		'memory',
		'memoryEnabled',
		'memoryRetentionDays',
		'memoryMaxItems',
		'memoryAutoSummarize',
		'mcpEnabled',
		'mcpRegistry',
		'externalApiWarningDismissed',
		'dynamicChatNamingEnabled',
		'confirmBeforeMutatingTools',
		'retryEnabled',
		'retryMaxAttempts',
		'retryBaseDelay',
		'retryMaxDelay',
		'metadataEnabled'
	],
	#classInstVars : [
		'Default'
	],
	#category : 'AI-ChatPharo',
	#package : 'AI-ChatPharo'
}

{ #category : 'accessing' }
ChatPharoSettings class >> default [

	Default ifNil: [ self setDefault: self loadOrNew ].
	^ Default
]

{ #category : 'accessing' }
ChatPharoSettings class >> legacySettingsFileReference [

        ^ FileLocator imageDirectory / 'chatpharo-settings.ston'
]

{ #category : 'accessing' }
ChatPharoSettings class >> loadOrNew [

	| path |
	self migrateLegacySettingsIfNecessary.
	path := self settingsFileReference.
	path exists ifFalse: [ ^ self new ].

	^ path readStreamDo: [ :file |
			  [
				  | settings |
				  settings := STON fromStream: file.
				  settings browserExtensionEnabled ifNil: [
					  settings browserExtensionEnabled: false ].
				  settings debuggerExtensionEnabled ifNil: [
					  settings debuggerExtensionEnabled: false ].

				  settings icebergExtensionEnabled ifNil: [
					  settings icebergExtensionEnabled: false ].
				  settings commitMessageTemplate ifNil: [
					  settings commitMessageTemplate:
						  settings defaultCommitMessageTemplate ].
				  settings icebergSystemPrompt ifNil: [
					  settings icebergSystemPrompt:
						  settings defaultIcebergSystemPrompt ].
				  settings debuggerSystemPrompt ifNil: [
					  settings debuggerSystemPrompt:
						  settings defaultDebuggerSystemPrompt ].
				  settings browserAutoTabEnabled ifNil: [
					  settings browserAutoTabEnabled: true ].
				  settings browserToolsEnabled ifNil: [
						  settings browserToolsEnabled:
							  settings defaultBrowserToolsEnabled ].
				  settings maximumIterations.
				  settings cacheEnabled ifNil: [ settings cacheEnabled: true ].
				  settings feedbackButtonsEnabled ifNil: [
					  settings feedbackButtonsEnabled: false ].
				  settings welcomeMessageEnabled ifNil: [
					  settings welcomeMessageEnabled: false ].
				  settings loggingEnabled.
				  settings askFeatureEnabled ifNil: [
					  settings askFeatureEnabled: true ].
				  settings codeFeatureEnabled ifNil: [
					  settings codeFeatureEnabled: true ].
				  settings skillsEnabled ifNil: [
					  settings skillsEnabled: OrderedCollection new ].
				  settings automaticSkillsEnabled ifNil: [
					  settings automaticSkillsEnabled: true ].
				  settings skillToolsEnabled ifNil: [
					  settings skillToolsEnabled: true ].
				  settings skillFilePaths ifNil: [
					  settings skillFilePaths: OrderedCollection new ].
				  settings askFeatureEnabled ifNil: [
					  settings askFeatureEnabled: true ].
				  settings codeFeatureEnabled ifNil: [
					  settings codeFeatureEnabled: true ].
				  settings isConfigured ifNil: [
					  settings privateSetIsConfigured: false ].
				  settings isDeveloper ifNil: [
					  settings privateSetIsDeveloper: false ].
				  settings developerId ifNil: [
					  settings privateSetDeveloperId: '' ].
				  settings userName ifNil: [ settings privateSetUserName: '' ].
				  settings userOrganization ifNil: [
					  settings privateSetUserOrganization: '' ].
				  settings ethicsDirector ifNil: [
					  settings privateSetEthicsDirector: ChatPharoEthicsDirector new ].
				  (settings instVarNamed: 'ethicsDirectorEnabled') ifNotNil: [
					  :value | settings ethicsDirector enabled: value ].
				  (settings instVarNamed: 'ethicsMandate') ifNotNil: [ :value |
					  settings ethicsDirector mandate: value ].
				  (settings instVarNamed: 'cognitiveLoadBudget') ifNotNil: [
					  :value | settings ethicsDirector cognitiveLoadBudget: value ].
				  (settings instVarNamed: 'tokenBudget') ifNotNil: [ :value |
					  settings ethicsDirector tokenBudget: value ].
				  (settings instVarNamed: 'timeBudgetMinutes') ifNotNil: [ :value |
					  settings ethicsDirector timeBudgetMinutes: value ].
				  settings ethicsDirector messageLimit ifNil: [
					  settings ethicsDirector messageLimit: 50 ].
				  settings multivers ifNil: [
					   (Smalltalk at: #ChatPharoMultivers ifAbsent: [ nil ])
						  ifNotNil: [ :cls | settings multivers: cls new ] ].
				  settings userLevel ifNil: [
					  settings privateSetUserLevel: 'beginner' ].
				  settings tutorialCompleted ifNil: [
					  settings privateSetTutorialCompleted: false ].
				  settings wantsTutorial ifNil: [
					  settings privateSetWantsTutorial: false ].
				  settings advisorDefaultsConfigured ifNil: [
					  settings privateSetAdvisorDefaultsConfigured: false ].
				  settings memoryEnabled ifNil: [
					  settings privateSetMemoryEnabled: true ].
				  settings memoryRetentionDays ifNil: [
					  settings privateSetMemoryRetentionDays: 30 ].
				  settings memoryMaxItems ifNil: [
					  settings privateSetMemoryMaxItems: 1000 ].
				  settings memoryAutoSummarize ifNil: [
					  settings privateSetMemoryAutoSummarize: true ].
				  settings mcpEnabled ifNil: [
					  settings privateSetMcpEnabled: false ].
				  settings mcpRegistry ifNil: [
					   (Smalltalk at: #ChatPharoMCPRegistry ifAbsent: [ nil ])
						  ifNotNil: [ :cls | settings privateSetMcpRegistry: cls new ] ].
				  settings externalApiWarningDismissed ifNil: [
					  settings privateSetExternalApiWarningDismissed: false ].
				  settings confirmBeforeMutatingTools ifNil: [
					  settings privateSetConfirmBeforeMutatingTools: true ].
				 settings retryEnabled ifNil: [
					  settings privateSetRetryEnabled: true ].
				  settings retryMaxAttempts ifNil: [
					  settings privateSetRetryMaxAttempts: 3 ].
				  settings retryBaseDelay ifNil: [
					  settings privateSetRetryBaseDelay: 2 ].
				  settings retryMaxDelay ifNil: [
					  settings privateSetRetryMaxDelay: 30 ].
				  settings metadataEnabled ifNil: [
					  settings privateSetMetadataEnabled: true ].
				  ^ settings ]
				  on: Error
				  do: [ ^ self new ] ]
]

{ #category : 'accessing' }
ChatPharoSettings class >> migrateLegacySettingsIfNecessary [

        | legacyPath newPath |
        newPath := self settingsFileReference.
        newPath exists ifTrue: [ ^ self ].
        legacyPath := self legacySettingsFileReference.
        legacyPath exists ifFalse: [ ^ self ].
        newPath parent ensureCreateDirectory.
        [ legacyPath moveTo: newPath ]
                on: Error
                do: [ legacyPath readStreamDo: [ :input |
                                newPath writeStreamDo: [ :output |
                                        output nextPutAll: input contents ] ].
                        legacyPath deleteIfAbsent: [ ] ]
]

{ #category : 'accessing' }
ChatPharoSettings class >> resetDefault [

	<script>
	| path directory |
	Default := nil.
	path := self settingsFileReference.
	path deleteIfAbsent: [ ].
	directory := path parent.
        (directory exists and: [ directory isDirectory and: [ directory children isEmpty ]])
                ifTrue: [ directory delete ].
        self legacySettingsFileReference deleteIfAbsent: [ ].
	^ self
]

{ #category : 'accessing' }
ChatPharoSettings class >> saveDefault [

| path |
        path := self settingsFileReference.
        path parent ensureCreateDirectory.
        path deleteIfAbsent: [ ].
        path writeStreamDo: [ :stream |
                STON put: self default onStream: stream ].
        self legacySettingsFileReference deleteIfAbsent: [ ].
        ^ self
]

{ #category : 'accessing' }
ChatPharoSettings class >> setDefault: aSettings [

	Default := aSettings.
	ChatPharoLogger loggingEnabled: aSettings loggingEnabled.
        ^ Default
]

{ #category : 'accessing' }
ChatPharoSettings class >> settingsDirectory [

	^ FileLocator imageDirectory / 'chatpharo'
]

{ #category : 'accessing' }
ChatPharoSettings class >> settingsFileReference [

        ^ self settingsDirectory / 'chatpharo-settings.ston'
]

{ #category : 'custom tools' }
ChatPharoSettings >> addCustomTool: aCustomTool [

	(customTools anySatisfy: [ :t | t name = aCustomTool name ]) ifTrue: [ self error: 'A tool with this name already exists' ].
	customTools add: aCustomTool.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'Custom tool added' details: (Dictionary new
			 at: 'tool' put: aCustomTool name;
			 yourself)
]

{ #category : 'skills' }
ChatPharoSettings >> addSkillFilePath: aPathString [

	| path |
	path := aPathString asString.
	path isEmpty ifTrue: [ ^ self ].
	self skillFilePaths.
	(skillFilePaths includes: path) ifTrue: [ ^ self ].
	skillFilePaths add: path.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'Skill file added'
		details: (Dictionary new
			at: 'path' put: path;
			yourself)
]

{ #category : 'advisor' }
ChatPharoSettings >> advisorDefaultsConfigured [

	^ advisorDefaultsConfigured ifNil: [ advisorDefaultsConfigured := false ]
]

{ #category : 'advisor' }
ChatPharoSettings >> advisorDefaultsConfigured: aBoolean [

	advisorDefaultsConfigured := aBoolean.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logSystem: 'Advisor defaults configuration status updated' details: (Dictionary new
			 at: 'advisorDefaultsConfigured' put: aBoolean;
			 yourself)
]

{ #category : 'initialization' }
ChatPharoSettings >> agent [

	^ agent
]

{ #category : 'extensions' }
ChatPharoSettings >> allBrowserToolsEnabled [
	| allToolNames |
	allToolNames := ChatPharoBrowserEnvironment new tools collect: [ :t | t name ].
	^ allToolNames allSatisfy: [ :name | browserToolsEnabled includes: name ]
]

{ #category : 'accessing' }
ChatPharoSettings >> askFeatureEnabled [

        ^ askFeatureEnabled ifNil: [ askFeatureEnabled := true ]
]

{ #category : 'accessing' }
ChatPharoSettings >> askFeatureEnabled: aBoolean [ 
        askFeatureEnabled := aBoolean.
        self class setDefault: self.
        self class saveDefault.
        ChatPharoLogger logFrontend: 'Ask feature toggled'
                details: (Dictionary new
                        at: 'enabled' put: aBoolean;
                        yourself)
]

{ #category : 'custom tools' }
ChatPharoSettings >> assertCustomToolNameAvailable: toolName excluding: excludedTool [

	(self customTools anySatisfy: [ :tool | tool ~~ excludedTool and: [ tool name = toolName ] ]) ifTrue: [
		self error: 'A tool with this name already exists' ].
	((ChatPharoBrowserEnvironment new tools collect: [ :tool | tool name ]) includes: toolName) ifTrue: [
		self error: 'A tool with this name already exists' ]
]

{ #category : 'skills' }
ChatPharoSettings >> automaticSkillsEnabled [

	^ automaticSkillsEnabled ifNil: [ automaticSkillsEnabled := true ]
]

{ #category : 'skills' }
ChatPharoSettings >> automaticSkillsEnabled: aBoolean [

	automaticSkillsEnabled := aBoolean.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'Automatic skills toggled'
		details: (Dictionary new
			at: 'enabled' put: aBoolean;
			yourself)
]

{ #category : 'initialization' }
ChatPharoSettings >> availableApiChoices [

	^ (self availableApis collect: [ :cls | cls displayName -> cls ])
		  asOrderedCollection
]

{ #category : 'initialization' }
ChatPharoSettings >> availableApis [

	"TODO: thos agents must be declare from the agent subclasses"
	^ {
		  ChatPharoNullAgent.
		  ChatPharoGeminiAgent.
		  ChatPharoOllamaAgent.
		  ChatPharoPharoInferAgent.
		  ChatPharoLMStudioAgent.
		  ChatPharoMistralAgent.
		  ChatPharoClaudeAgent.
		  ChatPharoDeepSeekAgent.
		  ChatPharoOpenAIAgent.
		  ChatPharoOpenRouterAgent.
		  ChatPharoGroqAgent }
]

{ #category : 'initialization' }
ChatPharoSettings >> availableUserLevels [

	^ #( 'beginner' 'intermediate' 'advanced' )
]

{ #category : 'initialization' }
ChatPharoSettings >> browserAutoTabEnabled [ 

        ^ browserAutoTabEnabled
]

{ #category : 'initialization' }
ChatPharoSettings >> browserAutoTabEnabled: aBoolean [

        browserAutoTabEnabled := aBoolean.
        self class setDefault: self.
        self class saveDefault.
        ChatPharoLogger logFrontend: 'Browser auto-tab toggled'
                details: (Dictionary new
                        at: 'enabled' put: aBoolean;
                        yourself)
]

{ #category : 'initialization' }
ChatPharoSettings >> browserExtensionEnabled [ 

        ^ browserExtensionEnabled
]

{ #category : 'initialization' }
ChatPharoSettings >> browserExtensionEnabled: aBoolean [

	        browserExtensionEnabled := aBoolean.
                self class setDefault: self.
        self class saveDefault.
        ChatPharoLogger logFrontend: 'Browser extension toggled'
                details: (Dictionary new
                        at: 'enabled' put: aBoolean;
                        yourself)

]

{ #category : 'initialization' }
ChatPharoSettings >> browserToolsEnabled [

        ^ browserToolsEnabled
]

{ #category : 'initialization' }
ChatPharoSettings >> browserToolsEnabled: aCollection [

	browserToolsEnabled := aCollection.
	self class setDefault: self.
	self class saveDefault.
	        ChatPharoLogger logFrontend: 'Browser tools selection updated'
                details: (Dictionary new
                        at: 'tools' put: aCollection asArray printString;
                        yourself)
]

{ #category : 'accessing' }
ChatPharoSettings >> cacheEnabled [
    ^ cacheEnabled ifNil: [ false ]
]

{ #category : 'accessing' }
ChatPharoSettings >> cacheEnabled: aBoolean [

	cacheEnabled := aBoolean.
	self class setDefault: self.
	self class saveDefault.
	    ChatPharoLogger logFrontend: 'Response cache toggled'
            details: (Dictionary new
                    at: 'enabled' put: aBoolean;
                    yourself)
]

{ #category : 'accessing' }
ChatPharoSettings >> codeFeatureEnabled [

        ^ codeFeatureEnabled ifNil: [ codeFeatureEnabled := true ]
]

{ #category : 'accessing' }
ChatPharoSettings >> codeFeatureEnabled: aBoolean [
        codeFeatureEnabled := aBoolean.
        self class setDefault: self.
        self class saveDefault.
        ChatPharoLogger logFrontend: 'Code feature toggled'
                details: (Dictionary new
                        at: 'enabled' put: aBoolean;
                        yourself)
]

{ #category : 'ethics' }
ChatPharoSettings >> cognitiveLoadBudget [

	^ self ethicsDirector cognitiveLoadBudget
]

{ #category : 'ethics' }
ChatPharoSettings >> cognitiveLoadBudget: aNumber [

	self ethicsDirector cognitiveLoadBudget: aNumber.
	self class setDefault: self.
	self class saveDefault
]

{ #category : 'accessing' }
ChatPharoSettings >> commitMessageTemplate [

	^ commitMessageTemplate ifNil: [ commitMessageTemplate := self defaultCommitMessageTemplate ]
]

{ #category : 'accessing' }
ChatPharoSettings >> commitMessageTemplate: aString [

	commitMessageTemplate := aString.
	self class setDefault: self.
	self class saveDefault
]

{ #category : 'safety' }
ChatPharoSettings >> confirmBeforeMutatingTools [

	^ confirmBeforeMutatingTools ifNil: [ confirmBeforeMutatingTools := true ]
]

{ #category : 'safety' }
ChatPharoSettings >> confirmBeforeMutatingTools: aBoolean [
	confirmBeforeMutatingTools := aBoolean.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logSystem: 'Tool confirmation gate toggled' details: (Dictionary new
			 at: 'enabled' put: aBoolean;
			 yourself)
]

{ #category : 'retry' }
ChatPharoSettings >> createRetryHandler [
	"Create a configured retry handler based on current settings"
	
	| handler |
	handler := ChatPharoRetryHandler new.
	handler maxAttempts: self retryMaxAttempts.
	handler baseDelay: self retryBaseDelay.
	handler maxDelay: self retryMaxDelay.
	^ handler
]

{ #category : 'custom tools' }
ChatPharoSettings >> customTools [

	^ customTools ifNil: [ customTools := OrderedCollection new ]
]

{ #category : 'custom tools' }
ChatPharoSettings >> customTools: aCollection [

	customTools := aCollection.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'Custom tools updated'
		details: (Dictionary new
			at: 'count' put: aCollection size;
			yourself)
]

{ #category : 'custom tools' }
ChatPharoSettings >> customToolsAsClients [

	^ (self customTools select: [ :tool | tool enabled ]) collect: [ :tool | tool asChatPharoClient ]
]

{ #category : 'extensions' }
ChatPharoSettings >> debuggerExtensionEnabled [

	^ debuggerExtensionEnabled ifNil: [ debuggerExtensionEnabled := false ]
]

{ #category : 'extensions' }
ChatPharoSettings >> debuggerExtensionEnabled: aBoolean [

	debuggerExtensionEnabled := aBoolean.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'Debugger extension toggled'
		details: (Dictionary new
			at: 'enabled' put: aBoolean;
			yourself)
]

{ #category : 'extensions' }
ChatPharoSettings >> debuggerSystemPrompt [

	^ debuggerSystemPrompt ifNil: [ debuggerSystemPrompt := self defaultDebuggerSystemPrompt ]
]

{ #category : 'extensions' }
ChatPharoSettings >> debuggerSystemPrompt: aString [

	debuggerSystemPrompt := aString.
	self class setDefault: self.
	self class saveDefault
]

{ #category : 'advisor' }
ChatPharoSettings >> defaultBrowserToolsEnabled [

	^ ((ChatPharoBrowserEnvironment new tools collect: [ :tool |
		    tool name ]) reject: [ :toolName | toolName = 'finder_search' ])
		  asOrderedCollection
]

{ #category : 'accessing' }
ChatPharoSettings >> defaultCommitMessageTemplate [

	"TODO: the default commit message templare must be define from the UI"
	^ '# Please enter the commit message for your changes.
# Lines starting with # will be ignored, and an empty message aborts the commit.
# On branch main, Fixes #
#Please use one of those
#feat:
#fix:
#refactor:
#chore:
#comment:'
]

{ #category : 'extensions' }
ChatPharoSettings >> defaultDebuggerSystemPrompt [

	"TODO: the debugfger system prompt must be declare from the UI"
	^ 'You are a Pharo debugging assistant. Explain the selected method and suggest likely root causes and concrete next debugging steps.'
]

{ #category : 'extensions' }
ChatPharoSettings >> defaultIcebergSystemPrompt [


	"TODO: this must be in the UI"
	^ String streamContents: [ :stream |
			  stream
				  << 'You are a Pharo developer generating an Iceberg commit message based on a diff.';
				  << String lf;
				  << 'Follow this commit template format and return ONLY the final commit message line:';
				  << String lf;
				  << '{{commitTemplate}}';
				  << String lf;
				  << 'Pick one prefix (feat:, fix:, refactor:, chore:, comment:) and write an imperative concise message.' ]
]

{ #category : 'developer' }
ChatPharoSettings >> developerId [

	^ developerId ifNil: [ developerId := '' ]
]

{ #category : 'developer' }
ChatPharoSettings >> developerId: aString [

	developerId := aString.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logSystem: 'Developer ID updated'
		details: (Dictionary new
			at: 'developerId' put: (aString ifEmpty: [ 'empty' ] ifNotEmpty: [ 'set' ]);
			yourself)
]

{ #category : 'extensions' }
ChatPharoSettings >> disableAllBrowserTools [

	browserToolsEnabled := OrderedCollection new.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'All browser tools disabled' details: Dictionary new
]

{ #category : 'initialization' }
ChatPharoSettings >> disableBrowserTool: toolName [

        browserToolsEnabled remove: toolName ifAbsent: [ ].
        self class setDefault: self.
        self class saveDefault.
        ChatPharoLogger logFrontend: 'Browser tool disabled'
                details: (Dictionary new
                        at: 'tool' put: toolName;
                        at: 'remainingTools' put: browserToolsEnabled asArray printString;
                        yourself)

]

{ #category : 'initialization' }
ChatPharoSettings >> disableSkill: skillName [

	skillsEnabled remove: skillName ifAbsent: [ ].
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'Skill disabled' details: (Dictionary new
			 at: 'skill' put: skillName;
			 at: 'remainingSkills' put: skillsEnabled asArray printString;
			 yourself)
]

{ #category : 'accessing' }
ChatPharoSettings >> dynamicChatNamingEnabled [
	^ dynamicChatNamingEnabled ifNil: [ false ]
]

{ #category : 'accessing' }
ChatPharoSettings >> dynamicChatNamingEnabled: aBoolean [

	dynamicChatNamingEnabled := aBoolean.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'Dynamic chat naming enabled' details: (Dictionary new
			 at: 'enabled' put: aBoolean;
			 yourself)
]

{ #category : 'extensions' }
ChatPharoSettings >> enableAllBrowserTools [

	browserToolsEnabled := (ChatPharoBrowserEnvironment new tools collect: [ :t | t name ]) asOrderedCollection.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'All browser tools enabled' details: (Dictionary new
			 at: 'tools' put: browserToolsEnabled asArray printString;
			 yourself)
]

{ #category : 'initialization' }
ChatPharoSettings >> enableBrowserTool: toolName [
        (browserToolsEnabled includes: toolName) ifFalse: [
                browserToolsEnabled add: toolName ].
        self class setDefault: self.
        self class saveDefault.
maximumIterations := 3.
        ChatPharoLogger logFrontend: 'Browser tool enabled'
                details: (Dictionary new
                        at: 'tool' put: toolName;
                        at: 'tools' put: browserToolsEnabled asArray printString;
                        yourself)
]

{ #category : 'initialization' }
ChatPharoSettings >> enableSkill: skillName [

	(skillsEnabled includes: skillName) ifFalse: [ skillsEnabled add: skillName ].
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'Skill enabled' details: (Dictionary new
			 at: 'skill' put: skillName;
			 at: 'skills' put: skillsEnabled asArray printString;
			 yourself)
]

{ #category : 'ethics' }
ChatPharoSettings >> ethicsDirector [

	^ ethicsDirector ifNil: [ ethicsDirector := ChatPharoEthicsDirector new ]
]

{ #category : 'ethics' }
ChatPharoSettings >> ethicsDirector: aDirector [

	ethicsDirector := aDirector.
	self class setDefault: self.
	self class saveDefault
]

{ #category : 'ethics' }
ChatPharoSettings >> ethicsDirectorEnabled [

	^ self ethicsDirector enabled
]

{ #category : 'ethics' }
ChatPharoSettings >> ethicsDirectorEnabled: aBoolean [

	self ethicsDirector enabled: aBoolean.
	self class setDefault: self.
	self class saveDefault
]

{ #category : 'ethics' }
ChatPharoSettings >> ethicsMandate [

	^ self ethicsDirector mandate
]

{ #category : 'ethics' }
ChatPharoSettings >> ethicsMandate: aString [

	self ethicsDirector mandate: aString.
	self class setDefault: self.
	self class saveDefault
]

{ #category : 'safety' }
ChatPharoSettings >> externalApiWarningDismissed [

	^ externalApiWarningDismissed ifNil: [ externalApiWarningDismissed := false ]
]

{ #category : 'safety' }
ChatPharoSettings >> externalApiWarningDismissed: aBoolean [

	externalApiWarningDismissed := aBoolean.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'External API warning dismissed status updated' details: (Dictionary new
			 at: 'dismissed' put: aBoolean;
			 yourself)
]

{ #category : 'accessing' }
ChatPharoSettings >> feedbackButtonsEnabled [
	^ feedbackButtonsEnabled ifNil: [ false ]
]

{ #category : 'accessing' }
ChatPharoSettings >> feedbackButtonsEnabled: aBoolean [

        feedbackButtonsEnabled := aBoolean.
        self class setDefault: self.
        self class saveDefault.
        ChatPharoLogger logFrontend: 'Feedback buttons toggled'
                details: (Dictionary new
                        at: 'enabled' put: aBoolean;
                        yourself)
]

{ #category : 'initialization' }
ChatPharoSettings >> icebergExtensionEnabled [

	^ icebergExtensionEnabled ifNil: [ icebergExtensionEnabled := false ]
]

{ #category : 'initialization' }
ChatPharoSettings >> icebergExtensionEnabled: aBoolean [

	icebergExtensionEnabled := aBoolean.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'Iceberg extension toggled'
		details: (Dictionary new
			at: 'enabled' put: aBoolean;
			yourself)
]

{ #category : 'initialization' }
ChatPharoSettings >> icebergSystemPrompt [

	^ icebergSystemPrompt ifNil: [ icebergSystemPrompt := self defaultIcebergSystemPrompt ]
]

{ #category : 'initialization' }
ChatPharoSettings >> icebergSystemPrompt: aString [

	icebergSystemPrompt := aString.
	self class setDefault: self.
	self class saveDefault
]

{ #category : 'initialization' }
ChatPharoSettings >> initialize [

	super initialize.
	agent := ChatPharoNullAgent new.
	browserExtensionEnabled := false.
	debuggerExtensionEnabled := false.
	icebergExtensionEnabled := false.
	commitMessageTemplate := self defaultCommitMessageTemplate.
	icebergSystemPrompt := self defaultIcebergSystemPrompt.
	debuggerSystemPrompt := self defaultDebuggerSystemPrompt.
	browserAutoTabEnabled := true.
	cacheEnabled := true.
	feedbackButtonsEnabled := false.
	welcomeMessageEnabled := false.
	loggingEnabled := true.
	askFeatureEnabled := true.
	codeFeatureEnabled := true.
	ethicsDirector := ChatPharoEthicsDirector new.
	browserToolsEnabled := self defaultBrowserToolsEnabled.
	maximumIterations := 3.
	skillsEnabled := OrderedCollection new.
	automaticSkillsEnabled := true.
	skillToolsEnabled := true.
	skillFilePaths := OrderedCollection new.
	userLevel := 'beginner'.
	tutorialCompleted := false.
	wantsTutorial := false.
	multivers := ChatPharoMultivers new.
	customTools := OrderedCollection new.
	memoryEnabled := true.
	memoryEnabled := true.
	memoryRetentionDays := 30.
	memoryMaxItems := 1000.
	memoryAutoSummarize := true.
	mcpEnabled := false.
	mcpRegistry := ChatPharoMCPRegistry new.
	confirmBeforeMutatingTools := true.
	retryEnabled := true.
	retryMaxAttempts := 3.
	retryBaseDelay := 2.
	retryMaxDelay := 30.
	metadataEnabled := true.
	ChatPharoLogger loggingEnabled: true.
	ChatPharoLogger
		logSystem: 'Settings initialized'
		details: (Dictionary new
				 at: 'defaultAgent' put: (ChatPharoLogger agentNameFor: agent);
				 yourself)
]

{ #category : 'initialization' }
ChatPharoSettings >> isConfigured [

	^ isConfigured ifNil: [ isConfigured := false ]
]

{ #category : 'initialization' }
ChatPharoSettings >> isConfigured: aBoolean [

	isConfigured := aBoolean.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logSystem: 'Configuration status updated'
		details: (Dictionary new
			at: 'isConfigured' put: aBoolean;
			yourself)
]

{ #category : 'initialization' }
ChatPharoSettings >> isDeveloper [

	^ isDeveloper ifNil: [ isDeveloper := false ]
]

{ #category : 'initialization' }
ChatPharoSettings >> isDeveloper: aBoolean [

	isDeveloper := aBoolean.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logSystem: 'Developer status updated'
		details: (Dictionary new
			at: 'isDeveloper' put: aBoolean;
			yourself)
]

{ #category : 'ethics' }
ChatPharoSettings >> lastRequestDurationSeconds [

	^ self ethicsDirector lastRequestDurationSeconds
]

{ #category : 'ethics' }
ChatPharoSettings >> lastRequestDurationSeconds: aNumber [

	self ethicsDirector lastRequestDurationSeconds: aNumber
]

{ #category : 'initialization' }
ChatPharoSettings >> loggingEnabled [

    ^ loggingEnabled ifNil: [ loggingEnabled := true ]
]

{ #category : 'initialization' }
ChatPharoSettings >> loggingEnabled: aBoolean [

    loggingEnabled = aBoolean ifTrue: [ ^ loggingEnabled ].
    loggingEnabled := aBoolean.
    self class setDefault: self.
    self class saveDefault
]

{ #category : 'initialization' }
ChatPharoSettings >> maximumIterations [ 

        ^ maximumIterations
]

{ #category : 'initialization' }
ChatPharoSettings >> maximumIterations: aNumber [

        maximumIterations := aNumber max: 1.
        self class setDefault: self.
        self class saveDefault.
        ChatPharoLogger logFrontend: 'Maximum iterations updated'
                details: (Dictionary new
                        at: 'value' put: maximumIterations;
                        yourself)
]

{ #category : 'mcp' }
ChatPharoSettings >> mcpEnabled [

	^ mcpEnabled ifNil: [ mcpEnabled := false ]
]

{ #category : 'mcp' }
ChatPharoSettings >> mcpEnabled: aBoolean [

	| wasEnabled registry |
	wasEnabled := self mcpEnabled.
	mcpEnabled := aBoolean.
	self class setDefault: self.
	self class saveDefault.
	registry := self mcpRegistry.
	registry ifNotNil: [
			(wasEnabled not and: [ aBoolean ]) ifTrue: [ registry connectAll ].
			(wasEnabled and: [ aBoolean not ]) ifTrue: [ registry disconnectAll ] ].

	ChatPharoLogger logFrontend: 'MCP support toggled' details: (Dictionary new
			 at: 'enabled' put: aBoolean;
			 yourself)
]

{ #category : 'mcp' }
ChatPharoSettings >> mcpRegistry [

	| registryClass |
	registryClass := Smalltalk at: #ChatPharoMCPRegistry ifAbsent: [ ^ nil ].
	^ mcpRegistry ifNil: [ mcpRegistry := registryClass new ]
]

{ #category : 'mcp' }
ChatPharoSettings >> mcpRegistry: aRegistry [

	mcpRegistry := aRegistry.
	self class setDefault: self.
	self class saveDefault
]

{ #category : 'mcp' }
ChatPharoSettings >> mcpToolsAsClients [

	self mcpEnabled ifFalse: [ ^ OrderedCollection new ].
	^ self mcpRegistry ifNil: [ OrderedCollection new ] ifNotNil: [ :registry | registry allToolsAsClients ]
]

{ #category : 'memory' }
ChatPharoSettings >> memory [

	^ memory
]

{ #category : 'memory' }
ChatPharoSettings >> memory: aMemory [

	memory := aMemory
]

{ #category : 'memory' }
ChatPharoSettings >> memoryAutoSummarize [

	^ memoryAutoSummarize ifNil: [ memoryAutoSummarize := true ]
]

{ #category : 'memory' }
ChatPharoSettings >> memoryAutoSummarize: aBoolean [

	memoryAutoSummarize := aBoolean.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'Memory auto-summarize toggled'
		details: (Dictionary new
				 at: 'enabled' put: aBoolean;
				 yourself)
]

{ #category : 'memory' }
ChatPharoSettings >> memoryEnabled [

	^ memoryEnabled ifNil: [ memoryEnabled := true ]
]

{ #category : 'memory' }
ChatPharoSettings >> memoryEnabled: aBoolean [

	memoryEnabled := aBoolean.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'Memory tracking toggled'
		details: (Dictionary new
				 at: 'enabled' put: aBoolean;
				 yourself)
]

{ #category : 'memory' }
ChatPharoSettings >> memoryMaxItems [
	^ memoryMaxItems ifNil: [ memoryMaxItems := 1000 ]
]

{ #category : 'memory' }
ChatPharoSettings >> memoryMaxItems: aNumber [

	memoryMaxItems := aNumber.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'Memory max items updated'
		details: (Dictionary new
				 at: 'value' put: aNumber;
				 yourself)
]

{ #category : 'memory' }
ChatPharoSettings >> memoryRetentionDays [
	
	"TODO: is this really necessary ?"
	^ memoryRetentionDays ifNil: [ memoryRetentionDays := 30 ]
]

{ #category : 'memory' }
ChatPharoSettings >> memoryRetentionDays: aNumber [

	memoryRetentionDays := aNumber.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'Memory retention days updated'
		details: (Dictionary new
				 at: 'value' put: aNumber;
				 yourself)
]

{ #category : 'ethics' }
ChatPharoSettings >> messageLimit [

	^ self ethicsDirector messageLimit
]

{ #category : 'ethics' }
ChatPharoSettings >> messageLimit: aNumber [

	self ethicsDirector messageLimit: aNumber.
	self class setDefault: self.
	self class saveDefault
]

{ #category : 'initialization' }
ChatPharoSettings >> models [

	^ agent class modelNames
]

{ #category : 'initialization' }
ChatPharoSettings >> multivers [

| multiversClass |
	multiversClass := Smalltalk at: #ChatPharoMultivers ifAbsent: [ ^ nil ].
	^ multivers ifNil: [ multivers := multiversClass new ]
]

{ #category : 'initialization' }
ChatPharoSettings >> multivers: aMultivers [

	multivers := aMultivers.
	self class setDefault: self.
	self class saveDefault.
	aMultivers ifNil: [ ^ self ].
	ChatPharoLogger
		logFrontend: 'Multivers configuration updated'
		details: (Dictionary new
				 at: 'enabled' put: aMultivers enabled;
				 at: 'stepsCount' put: aMultivers stepsCount;
				 yourself)
]

{ #category : 'initialization' }
ChatPharoSettings >> multiversEnabled [

	^ self multivers
		ifNil: [ false ]
		ifNotNil: [ :m | m enabled ]
]

{ #category : 'initialization' }
ChatPharoSettings >> multiversEnabled: aBoolean [
self multivers ifNil: [ ^ self ].
	self multivers enabled: aBoolean.
	self class setDefault: self.
	self class saveDefault
]

{ #category : 'private' }
ChatPharoSettings >> newConfiguredSandbox [

	| sandbox |
	sandbox := ChatPharoSandbox new.
	sandbox timeout: self sandboxTimeout.
	sandbox restrictFileSystem: self sandboxRestrictFileSystem.
	sandbox restrictNetwork: self sandboxRestrictNetwork.
	sandbox restrictSystemAccess: self sandboxRestrictSystemAccess.
	^ sandbox
]

{ #category : 'initialization' }
ChatPharoSettings >> presenter [

	^  ChatPharoSettingsPresenter on: self
]

{ #category : 'private' }
ChatPharoSettings >> privateSetAdvisorDefaultsConfigured: aBoolean [

	advisorDefaultsConfigured := aBoolean
]

{ #category : 'private' }
ChatPharoSettings >> privateSetCognitiveLoadBudget: aNumber [

	cognitiveLoadBudget := aNumber
]

{ #category : 'private' }
ChatPharoSettings >> privateSetConfirmBeforeMutatingTools: aBoolean [

	confirmBeforeMutatingTools := aBoolean
]

{ #category : 'private' }
ChatPharoSettings >> privateSetDeveloperId: aString [
	developerId := aString
]

{ #category : 'private' }
ChatPharoSettings >> privateSetEthicsDirector: aDirector [
	ethicsDirector := aDirector
]

{ #category : 'private' }
ChatPharoSettings >> privateSetEthicsDirectorEnabled: aBoolean [
	ethicsDirectorEnabled := aBoolean
]

{ #category : 'private' }
ChatPharoSettings >> privateSetEthicsMandate: aString [

	ethicsMandate := aString
]

{ #category : 'private' }
ChatPharoSettings >> privateSetExternalApiWarningDismissed: aBoolean [

	externalApiWarningDismissed := aBoolean
]

{ #category : 'private' }
ChatPharoSettings >> privateSetIsConfigured: aBoolean [

	isConfigured := aBoolean
]

{ #category : 'private' }
ChatPharoSettings >> privateSetIsDeveloper: aBoolean [

	isDeveloper := aBoolean
]

{ #category : 'private' }
ChatPharoSettings >> privateSetMcpEnabled: aBoolean [

	mcpEnabled := aBoolean
]

{ #category : 'private' }
ChatPharoSettings >> privateSetMcpRegistry: aRegistry [

	mcpRegistry := aRegistry
]

{ #category : 'private' }
ChatPharoSettings >> privateSetMemoryAutoSummarize: aBoolean [
	memoryAutoSummarize := aBoolean
]

{ #category : 'private' }
ChatPharoSettings >> privateSetMemoryEnabled: aBoolean [

	memoryEnabled := aBoolean
]

{ #category : 'private' }
ChatPharoSettings >> privateSetMemoryMaxItems: aNumber [

	memoryMaxItems := aNumber
]

{ #category : 'private' }
ChatPharoSettings >> privateSetMemoryRetentionDays: aNumber [

	memoryRetentionDays := aNumber
]

{ #category : 'private' }
ChatPharoSettings >> privateSetMessageLimit: aNumber [

	aNumber ifNil: [ ^ self ethicsDirector messageLimit: 50 ].
	(aNumber isNumber and: [ aNumber < 1 ])
		ifTrue: [ ^ self ethicsDirector messageLimit: 1 ].

	self ethicsDirector messageLimit: aNumber
]

{ #category : 'private' }
ChatPharoSettings >> privateSetRetryBaseDelay: aNumber [
	retryBaseDelay := aNumber
]

{ #category : 'private' }
ChatPharoSettings >> privateSetRetryEnabled: aBoolean [
	retryEnabled := aBoolean
]

{ #category : 'private' }
ChatPharoSettings >> privateSetRetryMaxAttempts: anInteger [
	retryMaxAttempts := anInteger
]

{ #category : 'private' }
ChatPharoSettings >> privateSetRetryMaxDelay: aNumber [
	retryMaxDelay := aNumber
]

{ #category : 'private' }
ChatPharoSettings >> privateSetMetadataEnabled: aBoolean [
	metadataEnabled := aBoolean
]

{ #category : 'private' }
ChatPharoSettings >> privateSetSandboxEnabled: aBoolean [

	sandboxEnabled := aBoolean
]

{ #category : 'private' }
ChatPharoSettings >> privateSetSandboxRestrictFileSystem: aBoolean [

	sandboxRestrictFileSystem := aBoolean
]

{ #category : 'private' }
ChatPharoSettings >> privateSetSandboxRestrictNetwork: aBoolean [

	sandboxRestrictNetwork := aBoolean
]

{ #category : 'private' }
ChatPharoSettings >> privateSetSandboxRestrictSystemAccess: aBoolean [

	sandboxRestrictSystemAccess := aBoolean
]

{ #category : 'private' }
ChatPharoSettings >> privateSetSandboxTimeout: anInteger [

	sandboxTimeout := anInteger
]

{ #category : 'private' }
ChatPharoSettings >> privateSetTimeBudgetMinutes: aNumber [

	timeBudgetMinutes := aNumber
]

{ #category : 'private' }
ChatPharoSettings >> privateSetTokenBudget: aNumber [

	tokenBudget := aNumber
]

{ #category : 'initialization' }
ChatPharoSettings >> privateSetTutorialCompleted: aBoolean [

	tutorialCompleted := aBoolean
]

{ #category : 'initialization' }
ChatPharoSettings >> privateSetUserLevel: aString [

	userLevel := aString
]

{ #category : 'private' }
ChatPharoSettings >> privateSetUserName: aString [

	userName := aString
]

{ #category : 'private' }
ChatPharoSettings >> privateSetUserOrganization: aString [

	userOrganization := aString
]

{ #category : 'initialization' }
ChatPharoSettings >> privateSetWantsTutorial: aBoolean [

	wantsTutorial := aBoolean
]

{ #category : 'custom tools' }
ChatPharoSettings >> removeCustomTool: aCustomTool [

	customTools remove: aCustomTool ifAbsent: [ ].
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'Custom tool removed' details: (Dictionary new
			 at: 'tool' put: aCustomTool name;
			 yourself)
]

{ #category : 'skills' }
ChatPharoSettings >> removeSkillFilePath: aPathString [

	self skillFilePaths.
	(skillFilePaths includes: aPathString asString) ifFalse: [ ^ self ].
	skillFilePaths remove: aPathString asString ifAbsent: [ ].
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'Skill file removed'
		details: (Dictionary new
			at: 'path' put: aPathString asString;
			yourself)
]

{ #category : 'custom tools' }
ChatPharoSettings >> replaceCustomTool: oldTool with: newTool [

	| index |
	self assertCustomToolNameAvailable: newTool name excluding: oldTool.
	index := self customTools indexOf: oldTool ifAbsent: [ nil ].
	index ifNil: [ customTools add: newTool ] ifNotNil: [ customTools at: index put: newTool ].
	self class setDefault: self.
	self class saveDefault
]

{ #category : 'extensions' }
ChatPharoSettings >> requestTimeoutSeconds [

	^ self ethicsDirector requestTimeoutSeconds
]

{ #category : 'ethics' }
ChatPharoSettings >> requestTimeoutSeconds: anInteger [

	self ethicsDirector requestTimeoutSeconds: anInteger.
	self class setDefault: self.
	self class saveDefault
]

{ #category : 'retry' }
ChatPharoSettings >> retryBaseDelay [
	"Base delay in seconds before first retry"
	
	^ retryBaseDelay ifNil: [ retryBaseDelay := 2 ]
]

{ #category : 'retry' }
ChatPharoSettings >> retryBaseDelay: aNumber [
	"Set base delay in seconds before first retry"
	
	retryBaseDelay := aNumber max: 0.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'Retry base delay updated'
		details: (Dictionary new
			at: 'value' put: retryBaseDelay;
			yourself)
]

{ #category : 'retry' }
ChatPharoSettings >> retryEnabled [
	"Whether automatic retry is enabled for API calls"
	
	^ retryEnabled ifNil: [ retryEnabled := true ]
]

{ #category : 'retry' }
ChatPharoSettings >> retryEnabled: aBoolean [
	"Enable or disable automatic retry for API calls"
	
	retryEnabled := aBoolean.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'Automatic retry toggled'
		details: (Dictionary new
			at: 'enabled' put: aBoolean;
			yourself)
]

{ #category : 'retry' }
ChatPharoSettings >> retryMaxAttempts [
	"Maximum number of retry attempts (including initial attempt)"
	
	^ retryMaxAttempts ifNil: [ retryMaxAttempts := 3 ]
]

{ #category : 'retry' }
ChatPharoSettings >> retryMaxAttempts: anInteger [
	"Set maximum number of retry attempts (must be at least 1)"
	
	retryMaxAttempts := anInteger max: 1.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'Retry max attempts updated'
		details: (Dictionary new
			at: 'value' put: retryMaxAttempts;
			yourself)
]

{ #category : 'retry' }
ChatPharoSettings >> retryMaxDelay [
	"Maximum delay in seconds between retries"
	
	^ retryMaxDelay ifNil: [ retryMaxDelay := 30 ]
]

{ #category : 'retry' }
ChatPharoSettings >> retryMaxDelay: aNumber [
	"Set maximum delay in seconds between retries"
	
	retryMaxDelay := aNumber max: 0.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'Retry max delay updated'
		details: (Dictionary new
			at: 'value' put: retryMaxDelay;
			yourself)
]

{ #category : 'metadata' }
ChatPharoSettings >> metadataEnabled [
	"Whether to send metadata (version, platform, etc.) to the AI model"
	
	^ metadataEnabled ifNil: [ metadataEnabled := true ]
]

{ #category : 'metadata' }
ChatPharoSettings >> metadataEnabled: aBoolean [
	"Enable or disable sending metadata to the AI model"
	
	metadataEnabled := aBoolean.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'Metadata toggled'
		details: (Dictionary new
			at: 'enabled' put: aBoolean;
			yourself)
]

{ #category : 'metadata' }
ChatPharoSettings >> metadataString [
	"Build a metadata string with version and platform info for the AI model"
	
	| stream |
	stream := String new writeStream.
	stream nextPutAll: '## ChatPharo Environment'.
	stream cr.
	stream nextPutAll: '- ChatPharo version: '.
	stream nextPutAll: self chatPharoVersion.
	stream cr.
	stream nextPutAll: '- Pharo version: '.
	stream nextPutAll: SystemVersion current asString.
	stream cr.
	stream nextPutAll: '- Platform: '.
	stream nextPutAll: OSPlatform current name.
	stream cr.
	stream nextPutAll: '- Locale: '.
	stream nextPutAll: Locale current asString.
	stream cr.
	stream nextPutAll: '- Timestamp: '.
	stream nextPutAll: DateAndTime now asString.
	^ stream contents
]

{ #category : 'metadata' }
ChatPharoSettings >> chatPharoVersion [
	"Return the current ChatPharo version string"
	
	^ '1.0.0'
]

{ #category : 'private' }
ChatPharoSettings >> sandboxEnabled [

	^ sandboxEnabled ifNil: [ sandboxEnabled := false ]
]

{ #category : 'private' }
ChatPharoSettings >> sandboxEnabled: aBoolean [

	sandboxEnabled := aBoolean.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'Sandbox toggled'
		details: (Dictionary new
			at: 'enabled' put: aBoolean;
			yourself)
]

{ #category : 'private' }
ChatPharoSettings >> sandboxRestrictFileSystem [

	^ sandboxRestrictFileSystem ifNil: [ sandboxRestrictFileSystem := true ]
]

{ #category : 'private' }
ChatPharoSettings >> sandboxRestrictFileSystem: aBoolean [

	sandboxRestrictFileSystem := aBoolean.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'Sandbox file system restriction toggled'
		details: (Dictionary new
			at: 'enabled' put: aBoolean;
			yourself)
]

{ #category : 'private' }
ChatPharoSettings >> sandboxRestrictNetwork [

	^ sandboxRestrictNetwork ifNil: [ sandboxRestrictNetwork := true ]
]

{ #category : 'private' }
ChatPharoSettings >> sandboxRestrictNetwork: aBoolean [

	sandboxRestrictNetwork := aBoolean.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'Sandbox network restriction toggled'
		details: (Dictionary new
			at: 'enabled' put: aBoolean;
			yourself)
]

{ #category : 'private' }
ChatPharoSettings >> sandboxRestrictSystemAccess [

	^ sandboxRestrictSystemAccess ifNil: [ sandboxRestrictSystemAccess := true ]
]

{ #category : 'private' }
ChatPharoSettings >> sandboxRestrictSystemAccess: aBoolean [

	sandboxRestrictSystemAccess := aBoolean.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'Sandbox system access restriction toggled'
		details: (Dictionary new
			at: 'enabled' put: aBoolean;
			yourself)
]

{ #category : 'private' }
ChatPharoSettings >> sandboxTimeout [

	^ sandboxTimeout ifNil: [ sandboxTimeout := 5000 ]
]

{ #category : 'private' }
ChatPharoSettings >> sandboxTimeout: anInteger [

	sandboxTimeout := anInteger.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'Sandbox timeout updated'
		details: (Dictionary new
			at: 'timeout' put: anInteger;
			yourself)
]

{ #category : 'skills' }
ChatPharoSettings >> skillFilePaths [

	^ skillFilePaths ifNil: [ skillFilePaths := OrderedCollection new ]
]

{ #category : 'skills' }
ChatPharoSettings >> skillFilePaths: aCollection [

	skillFilePaths := aCollection asOrderedCollection.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'Skill file paths updated'
		details: (Dictionary new
			at: 'paths' put: skillFilePaths asArray printString;
			yourself)
]

{ #category : 'skills' }
ChatPharoSettings >> skillToolsEnabled [

	^ skillToolsEnabled ifNil: [ skillToolsEnabled := true ]
]

{ #category : 'skills' }
ChatPharoSettings >> skillToolsEnabled: aBoolean [

	skillToolsEnabled := aBoolean.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'Skill tools toggled'
		details: (Dictionary new
			at: 'enabled' put: aBoolean;
			yourself)
]

{ #category : 'skills' }
ChatPharoSettings >> skillsEnabled [

	^ skillsEnabled ifNil: [ skillsEnabled := OrderedCollection new ]
]

{ #category : 'skills' }
ChatPharoSettings >> skillsEnabled: aCollection [

	skillsEnabled := aCollection.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logFrontend: 'Skills selection updated'
		details: (Dictionary new
			at: 'skills' put: aCollection asArray printString;
			yourself)
]

{ #category : 'ethics' }
ChatPharoSettings >> timeBudgetMinutes [

	^ self ethicsDirector timeBudgetMinutes
]

{ #category : 'ethics' }
ChatPharoSettings >> timeBudgetMinutes: aNumber [

	self ethicsDirector timeBudgetMinutes: aNumber.
	self class setDefault: self.
	self class saveDefault
]

{ #category : 'ethics' }
ChatPharoSettings >> tokenBudget [

	^ self ethicsDirector tokenBudget
]

{ #category : 'ethics' }
ChatPharoSettings >> tokenBudget: aNumber [

	self ethicsDirector tokenBudget: aNumber.
	self class setDefault: self.
	self class saveDefault
]

{ #category : 'initialization' }
ChatPharoSettings >> tutorialCompleted [

	^ tutorialCompleted ifNil: [ tutorialCompleted := false ]
]

{ #category : 'initialization' }
ChatPharoSettings >> tutorialCompleted: aBoolean [

	tutorialCompleted := aBoolean.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logSystem: 'Tutorial completion status updated' details: (Dictionary new
			 at: 'tutorialCompleted' put: aBoolean;
			 yourself)
]

{ #category : 'initialization' }
ChatPharoSettings >> useApi: anAgentClass [

        agent := anAgentClass new.
        self class setDefault: self.
        self class saveDefault.
        ChatPharoLogger logFrontend: 'Active agent changed'
                details: (Dictionary new
                        at: 'agent' put: (ChatPharoLogger agentNameFor: agent);
                        yourself)
]

{ #category : 'initialization' }
ChatPharoSettings >> useModel: aModelName [

        agent model: aModelName.
        self class setDefault: self.
        self class saveDefault.
        ChatPharoLogger logFrontend: 'Model selection updated'
                details: (Dictionary new
                        at: 'agent' put: (ChatPharoLogger agentNameFor: agent);
                        at: 'model' put: aModelName;
                        yourself)
]

{ #category : 'initialization' }
ChatPharoSettings >> userLevel [

	^ userLevel ifNil: [ userLevel := 'beginner' ]
]

{ #category : 'initialization' }
ChatPharoSettings >> userLevel: aString [

	userLevel := aString.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logSystem: 'User level updated' details: (Dictionary new
			 at: 'userLevel' put: aString;
			 yourself)
]

{ #category : 'initialization' }
ChatPharoSettings >> userLevelDisplayName [

	^ self userLevelDisplayNameFor: self userLevel
]

{ #category : 'initialization' }
ChatPharoSettings >> userLevelDisplayNameFor: aLevel [

	aLevel = 'beginner' ifTrue: [ ^ 'Beginner - New to Pharo' ].
	aLevel = 'intermediate' ifTrue: [ ^ 'Intermediate - Familiar with Pharo basics' ].
	aLevel = 'advanced' ifTrue: [ ^ 'Advanced - Experienced Pharo developer' ].
	^ aLevel
]

{ #category : 'developer' }
ChatPharoSettings >> userName [

	^ userName ifNil: [ userName := '' ]
]

{ #category : 'developer' }
ChatPharoSettings >> userName: aString [

	userName := aString.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logSystem: 'User name updated'
		details: (Dictionary new
			at: 'userName' put: aString;
			yourself)
]

{ #category : 'developer' }
ChatPharoSettings >> userOrganization [

	^ userOrganization ifNil: [ userOrganization := '' ]
]

{ #category : 'developer' }
ChatPharoSettings >> userOrganization: aString [

	userOrganization := aString.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logSystem: 'User organization updated'
		details: (Dictionary new
			at: 'userOrganization' put: aString;
			yourself)
]

{ #category : 'initialization' }
ChatPharoSettings >> wantsTutorial [

	^ wantsTutorial ifNil: [ wantsTutorial := false ]
]

{ #category : 'initialization' }
ChatPharoSettings >> wantsTutorial: aBoolean [

	wantsTutorial := aBoolean.
	self class setDefault: self.
	self class saveDefault.
	ChatPharoLogger logSystem: 'Tutorial preference updated' details: (Dictionary new
			 at: 'wantsTutorial' put: aBoolean;
			 yourself)
]

{ #category : 'accessing' }
ChatPharoSettings >> welcomeMessageEnabled [ 

       ^ welcomeMessageEnabled ifNil: [ false ]
]

{ #category : 'accessing' }
ChatPharoSettings >> welcomeMessageEnabled: aBoolean [

	welcomeMessageEnabled := aBoolean.
	self class setDefault: self.
	self class saveDefault.
       ChatPharoLogger logFrontend: 'Welcome message toggled'
               details: (Dictionary new
                       at: 'enabled' put: aBoolean;
                       yourself)
]
