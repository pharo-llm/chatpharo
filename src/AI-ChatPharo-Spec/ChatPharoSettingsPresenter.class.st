"
Multi-tab dialog (Chat, History, API, Configuration, Personal). Hosts per-agent sub-presenters (see below) and general actions such as “Delete all chats”.
"
Class {
	#name : 'ChatPharoSettingsPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'notebook',
		'ollamaModelDropList',
		'model',
		'modelsRefreshButton',
		'apiDropList',
		'apiSettingsContainer',
		'systemPromptInput',
		'browserExtensionCheckBox',
		'browserExtensionPage',
		'debuggerExtensionCheckBox',
		'debuggerExtensionPage',
		'icebergExtensionCheckBox',
		'icebergExtensionPage',
		'maxIterationsInput',
		'playgroundToolCheckBox',
		'browserAutoTabCheckBox',
		'chatPharo',
		'cacheCheckBox',
		'loggingCheckBox',
		'openLogsButton',
		'feedbackCheckBox',
		'askFeatureCheckBox',
		'codeFeatureCheckBox',
		'welcomeMessageCheckBox',
		'userNameInput',
		'userOrganizationInput',
		'developerIdInput',
		'developerStatusLabel',
		'verifyDeveloperButton',
		'saveSettingsButton',
		'ethicsDirectorCheckBox',
		'ethicsMandateInput',
		'cognitiveLoadBudgetInput',
		'tokenBudgetInput',
		'timeBudgetInput',
		'requestTimeoutInput',
		'messageLimitInput',
		'dynamicChatNamingCheckBox'
	],
	#category : 'AI-ChatPharo-Spec-Core',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Core'
}

{ #category : 'helpers' }
ChatPharoSettingsPresenter >> addCheckboxLabeled: aLabel value: aValueBlock changeAction: aChangeBlock [
	| checkbox |
	checkbox := self newCheckBox
		label: aLabel;
		state: aValueBlock value;
		yourself.

	checkbox whenChangedDo: aChangeBlock.

	^ checkbox
]

{ #category : 'initialization' }
ChatPharoSettingsPresenter >> chatPharo [

        ^ chatPharo
]

{ #category : 'initialization' }
ChatPharoSettingsPresenter >> chatPharo: anObject [

        chatPharo := anObject
]

{ #category : 'initialization' }
ChatPharoSettingsPresenter >> connectPresenters [
	"Refresh models on button action"

	| userAccepted |
	modelsRefreshButton action: [
			ollamaModelDropList items: model models.
			ollamaModelDropList items ifNotEmpty: [
					| selected |
					selected := ollamaModelDropList items detect: [ :each | each = model agent model ] ifNone: [ nil ].
					selected ifNotNil: [ ollamaModelDropList selectItem: selected ] ifNil: [ ollamaModelDropList selectFirst ] ] ].
	apiDropList whenSelectedItemChangedDo: [ :assoc |
			| apiClass newPresenter |
			apiClass := assoc value.
			userAccepted := ChatPharoSafetyAdvisor confirmExternalApiUsageOn: self forAgent: apiClass.
			userAccepted ifFalse: [
					apiDropList selectItem:
						(model availableApiChoices detect: [ :a | a value = model agent class ] ifNone: [ model availableApiChoices first ]).
					self ].
			userAccepted ifTrue: [
					model useApi: apiClass.
					chatPharo ifNotNil: [ chatPharo synchronizeChatsWithSettingsAgent ].
					apiSettingsContainer removeAll.
					newPresenter := apiClass settingsPresenterFor: model agent.
					newPresenter ifNotNil: [ apiSettingsContainer add: newPresenter ].
					systemPromptInput text: model agent systemPrompt ] ].
	systemPromptInput whenTextChangedDo: [ :text |
			text ~= ChatPharoAgent defaultSystemPrompt ifTrue: [
					(ChatPharoSafetyAdvisor confirmPromptModificationOn: self)
						ifTrue: [
								model agent systemPrompt: text.
								ChatPharoSettings setDefault: model.
								ChatPharoSettings saveDefault ]
						ifFalse: [ systemPromptInput text: model agent systemPrompt ] ] ].

	maxIterationsInput whenTextChangedDo: [ :t |
			t ifNotEmpty: [
					| num |
					num := t asNumber.
					num < 1
						ifTrue: [
								(ChatPharoSafetyAdvisor confirmMaxIterationsOn: self)
									ifTrue: [
											model maximumIterations: 1.
											maxIterationsInput text: '1' ]
									ifFalse: [ maxIterationsInput text: model maximumIterations asString ] ]
						ifFalse: [ model maximumIterations: num ] ] ].
	browserExtensionCheckBox whenChangedDo: [ :presenter |
			model browserExtensionEnabled: presenter.
			self updateBrowserExtensionTab ].

	debuggerExtensionCheckBox whenChangedDo: [ :presenter |
			model debuggerExtensionEnabled: presenter.
			self updateDebuggerExtensionTab ].

	icebergExtensionCheckBox whenChangedDo: [ :presenter |
			model icebergExtensionEnabled: presenter.
			self updateIcebergExtensionTab ].

	browserAutoTabCheckBox whenChangedDo: [ :presenter | model browserAutoTabEnabled: presenter ].

	cacheCheckBox whenChangedDo: [ :enabled |
			model cacheEnabled: enabled.
			ChatPharoSettings saveDefault ].

	loggingCheckBox whenChangedDo: [ :enabled | model loggingEnabled: enabled ].


	askFeatureCheckBox := self
		                      addCheckboxLabeled: 'Enable Ask button in editors'
		                      value: [ model askFeatureEnabled ]
		                      changeAction: [ :val | model askFeatureEnabled: val ].

	codeFeatureCheckBox := self
		                       addCheckboxLabeled: 'Enable Code button in editors'
		                       value: [ model codeFeatureEnabled ]
		                       changeAction: [ :val | model codeFeatureEnabled: val ].

	feedbackCheckBox := self
		                    addCheckboxLabeled: 'Enable Feedback Buttons'
		                    value: [ ChatPharoSettings default feedbackButtonsEnabled ]
		                    changeAction: [ :val | ChatPharoSettings default feedbackButtonsEnabled: val ].

	welcomeMessageCheckBox := self
		                          addCheckboxLabeled: 'Show Welcome Message'
		                          value: [ ChatPharoSettings default welcomeMessageEnabled ]
		                          changeAction: [ :val | ChatPharoSettings default welcomeMessageEnabled: val ].

	dynamicChatNamingCheckBox := self
		                             addCheckboxLabeled: 'Enable Dynamic Chat Naming'
		                             value: [ ChatPharoSettings default dynamicChatNamingEnabled ]
		                             changeAction: [ :val | ChatPharoSettings default dynamicChatNamingEnabled: val ].

	ethicsDirectorCheckBox whenChangedDo: [ :enabled | model ethicsDirectorEnabled: enabled ].

	ethicsMandateInput whenTextChangedDo: [ :text | model ethicsMandate: text trimBoth ].

	cognitiveLoadBudgetInput whenTextChangedDo: [ :text |
			text isEmpty
				ifTrue: [ model cognitiveLoadBudget: nil ]
				ifFalse: [ model cognitiveLoadBudget: text asNumber ] ].

	tokenBudgetInput whenTextChangedDo: [ :text |
			text isEmpty
				ifTrue: [ model tokenBudget: nil ]
				ifFalse: [ model tokenBudget: text asNumber ] ].

	timeBudgetInput whenTextChangedDo: [ :text |
			text isEmpty
				ifTrue: [ model timeBudgetMinutes: nil ]
				ifFalse: [ model timeBudgetMinutes: text asNumber ] ].

	requestTimeoutInput whenTextChangedDo: [ :text |
			text isEmpty
				ifTrue: [ model requestTimeoutSeconds: nil ]
				ifFalse: [ model requestTimeoutSeconds: text asNumber ] ].

	messageLimitInput whenTextChangedDo: [ :text |
			text isEmpty ifFalse: [
					| newValue |
					newValue := text asNumber.
					newValue ~= model messageLimit ifTrue: [
							(ChatPharoSafetyAdvisor isValidMessageLimit: newValue)
								ifFalse: [
										"Hard rejection: the Ethics Director forbids non-positive limits
										 regardless of developer status."
										ChatPharoSafetyAdvisor rejectMessageLimitOn: self for: newValue.
										messageLimitInput text: model messageLimit asString ]
								ifTrue: [
										ChatPharoSettings default isDeveloper
											ifTrue: [
													(ChatPharoSafetyAdvisor confirmMessageLimitChangeOn: self)
														ifTrue: [ model messageLimit: newValue ]
														ifFalse: [ messageLimitInput text: model messageLimit asString ] ]
											ifFalse: [
													self alert: ChatPharoSafetyAdvisor ethicsSettingChangeMessage.
													messageLimitInput text: model messageLimit asString ] ] ] ] ].


	playgroundToolCheckBox whenChangedDo: [ :checked |
			checked
				ifTrue: [ model enableBrowserTool: 'open_playground' ]
				ifFalse: [
						(ChatPharoSafetyAdvisor confirmToolDisableOn: self)
							ifTrue: [ model disableBrowserTool: 'open_playground' ]
							ifFalse: [ playgroundToolCheckBox state: true ] ] ]
]

{ #category : 'layout' }
ChatPharoSettingsPresenter >> defaultLayout [

    ^ SpBoxLayout newTopToBottom
        add: notebook;
add: (SpBoxLayout newHorizontal
			spacing: 8;
			add: (self newLabel label: 'Use Save Settings to persist your changes.') expand: true;
			add: saveSettingsButton expand: false;
			yourself)
		expand: false;
        yourself
]

{ #category : 'initialization' }
ChatPharoSettingsPresenter >> developerStatusText [
	"Return the developer status text."

	| settings |
	settings := ChatPharoSettings default.
	settings isDeveloper
		ifTrue: [ ^ 'Verified Developer' ]
		ifFalse: [
			settings developerId isEmpty
				ifTrue: [ ^ 'Not a developer' ]
				ifFalse: [ ^ 'Developer ID not verified' ] ]
]

{ #category : 'initialization' }
ChatPharoSettingsPresenter >> ensureBrowserExtensionTab [

	browserExtensionPage ifNil: [
			browserExtensionPage := SpNotebookPage
				                        title: 'System Browser'
				                        icon: (self iconNamed: #nautilus)
				                        provider: [
				                       ChatPharoBrowserExtensionSettingsPresenter on: model  ].
			notebook addPage: browserExtensionPage ]
]

{ #category : 'initialization' }
ChatPharoSettingsPresenter >> ensureDebuggerExtensionTab [

		debuggerExtensionPage ifNil: [
		debuggerExtensionPage := SpNotebookPage
				title: 'Debugger Tab'
				icon: (self iconNamed: #smallConfiguration)
				provider: [ self newDebuggerTab ].
		notebook addPage: debuggerExtensionPage ].
	notebook selectPage: debuggerExtensionPage
]

{ #category : 'initialization' }
ChatPharoSettingsPresenter >> ensureIcebergExtensionTab [

	icebergExtensionPage ifNil: [
		icebergExtensionPage := SpNotebookPage
				title: 'Iceberg Tab'
				icon: (self iconNamed: #branch)
				provider: [ self newIcebergTab ].
		notebook addPage: icebergExtensionPage ].
	notebook selectPage: icebergExtensionPage
]

{ #category : 'accessing - model' }
ChatPharoSettingsPresenter >> historyTextForChats [

	| chats history |
	chats := chatPharo ifNotNil: [ chatPharo chats ] ifNil: [ #(  ) ].
	chats isEmpty ifTrue: [
			history := model agent history.
			^ (history notNil and: [ history messages notEmpty ])
			  ifTrue: [ history asPromptPrefix ]
			  ifFalse: [ 'No history available.' ] ].

	^ String streamContents: [ :stream |
			  chats withIndexDo: [ :chat :index |
					  | prefix |
					  stream
						 nextPutAll: '--- Chat ' , index asString , ' ---';
						  cr.
					  prefix := chat historyPromptPrefix.
					  prefix isEmpty
						  ifTrue: [ stream nextPutAll: 'No history available.' ]
						  ifFalse: [ stream nextPutAll: prefix ].
					  index < chats size ifTrue: [
							  stream
								  cr;
								  cr ] ] ]
]

{ #category : 'initialization' }
ChatPharoSettingsPresenter >> initializePresenters [

	super initializePresenters.

	notebook := self newNotebook.
	apiSettingsContainer := SpBoxLayout newTopToBottom.

	notebook addPage: (SpNotebookPage title: 'Chat' icon: (self iconNamed: #announcement) provider: [ self newChatTab ]).

	notebook addPage: (SpNotebookPage title: 'History' icon: (self iconNamed: #history) provider: [ self newHistoryTab ]).

	notebook addPage:
		(SpNotebookPage title: 'Agent' icon: (self iconNamed: #smallConfiguration) provider: [ self newConfigurationTab ]).

	notebook addPage:
		(SpNotebookPage title: 'Extensions' icon: (self iconNamed: #smallCogInitialState) provider: [ self newExtensionsTab ]).

	notebook addPage:
		(SpNotebookPage title: 'Security' icon: (self iconNamed: #lock) provider: [ ChatPharoSecuritySettingsPresenter on: model ]).

	notebook addPage: (SpNotebookPage title: 'Ethics' icon: (self iconNamed: #glamorousGoal) provider: [ self newEthicsTab ]).

	notebook addPage: (SpNotebookPage title: 'Personal' icon: (self iconNamed: #user) provider: [ self newPersonalTab ]).

	notebook addPage: (SpNotebookPage title: 'Skills' icon: (self iconNamed: #smallObjects) provider: [ self newSkillsTab ]).

	notebook addPage: (SpNotebookPage title: 'Memory' icon: (self iconNamed: #history) provider: [ self newMemoryTab ]).

	notebook addPage:
		(SpNotebookPage title: 'Custom Tools' icon: (self iconNamed: #smallObjects) provider: [ self newCustomToolsTab ]).

	notebook addPage: (SpNotebookPage title: 'MCP' icon: (self iconNamed: #network) provider: [ self newMCPTab ]).

	notebook addPage: (SpNotebookPage title: 'Multivers' icon: (self iconNamed: #branch) provider: [ self newMultiversTab ]).

	modelsRefreshButton := self newButton
		                       label: 'Refresh';
		                       icon: (self iconNamed: #refresh);
		                       help: 'Refresh models';
		                       yourself.

	apiDropList := SpDropListPresenter new
		               help: 'Select backend API';
		               items: model availableApiChoices;
		               display: [ :assoc | assoc key ];
		               yourself.

	ollamaModelDropList := SpDropListPresenter new
		                       help: 'Select ollama model';
		                       items: model models;
		                       display: [ :e | e ];
		                       yourself.

	systemPromptInput := self newTextInput
		                     placeholder: 'System prompt...';
		                     text: model agent systemPrompt;
		                     yourself.


	maxIterationsInput := self newNumberInput
		                      placeholder: 'e.g. 5';
		                      text: model maximumIterations asString;
		                      yourself.

	browserExtensionCheckBox := self newCheckBox
		                            label: 'Enable browser tab';
		                            state: model browserExtensionEnabled;
		                            yourself.

	debuggerExtensionCheckBox := self newCheckBox
		                             label: 'Debugger';
		                             state: model debuggerExtensionEnabled;
		                             yourself.


	icebergExtensionCheckBox := self newCheckBox
		                            label: 'Iceberg';
		                            state: model icebergExtensionEnabled;
		                            yourself.


	browserAutoTabCheckBox := self newCheckBox
		                          label: 'Open tab on selection';
		                          state: model browserAutoTabEnabled;
		                          yourself.

	playgroundToolCheckBox := self newCheckBox
		                          label: 'Enable open playground tool';
		                          state: (model browserToolsEnabled includes: 'open_playground');
		                          yourself.

	cacheCheckBox := self newCheckBox
		                 label: 'Enable cache';
		                 state: model cacheEnabled;
		                 yourself.

	openLogsButton := self newButton
		                  label: 'Open Logs';
		                  icon: (self iconNamed: #glamorousOpen);
		                  help: 'Open the ChatPharo log file';
		                  action: [ self openLogs ];
		                  yourself.

	loggingCheckBox := self newCheckBox
		                   label: 'Enable logging';
		                   state: model loggingEnabled;
		                   yourself.

	ethicsDirectorCheckBox := self newCheckBox
		                          label: 'Enable Ethics Director';
		                          state: model ethicsDirectorEnabled;
		                          yourself.

	ethicsMandateInput := self newTextInput
		                      placeholder: 'Ethics mandate...';
		                      text: model ethicsMandate;
		                      yourself.

	cognitiveLoadBudgetInput := self newNumberInput
		                            placeholder: 'e.g. 120';
		                            text: model cognitiveLoadBudget asString;
		                            yourself.

	tokenBudgetInput := self newNumberInput
		                    placeholder: 'e.g. 4096';
		                    text: model tokenBudget asString;
		                    yourself.

	timeBudgetInput := self newNumberInput
		                   placeholder: 'e.g. 30';
		                   text: model timeBudgetMinutes asString;
		                   yourself.


	requestTimeoutInput := self newNumberInput
		                       placeholder: 'e.g. 300';
		                       text: model requestTimeoutSeconds asString;
		                       yourself.


	messageLimitInput := self newNumberInput
		                     placeholder: 'e.g. 50';
		                     text: model messageLimit asString;
		                     yourself.

	saveSettingsButton := self newButton
		                      label: 'Save Settings';
		                      icon: (self iconNamed: #smallSave);
		                      help: 'Persist current settings';
		                      action: [ self saveSettings ];
		                      yourself.

	apiDropList selectItem:
		(model availableApiChoices detect: [ :assoc | assoc value = model agent class ] ifNone: [ model availableApiChoices first ]).

	self refreshApiSettings.
	self updateBrowserExtensionTab.
	self updateIcebergExtensionTab.
	self updateDebuggerExtensionTab
]

{ #category : 'initialization' }
ChatPharoSettingsPresenter >> initializeWindow: aWindowPresenter [
	
	super initializeWindow: aWindowPresenter.
	
	aWindowPresenter
		title: 'ChatPharo settings';
		initialExtent: 800@500
]

{ #category : 'tabs' }
ChatPharoSettingsPresenter >> newChatTab [

	| agentSection toolsSection loggingSection uiSection |
	"Agent Settings Section"
	agentSection := SpBoxLayout newTopToBottom
		                spacing: 6;
		                add: (self newLabel label: '— Agent Settings —') expand: false;
		                add: (SpBoxLayout newHorizontal
				                 spacing: 8;
				                 add: (self newLabel label: 'System prompt:') expand: false;
				                 add: systemPromptInput expand: true;
				                 yourself)
		                expand: false;
		                add: (SpBoxLayout newHorizontal
				                 spacing: 8;
				                 add: (self newLabel label: 'Max iterations:') expand: false;
				                 add: maxIterationsInput width: 80;
				                 yourself)
		                expand: false;
		                yourself. "Tools & Features Section"
	toolsSection := SpBoxLayout newTopToBottom
		                spacing: 6;
		                add: (self newLabel label: '— Tools & Features —') expand: false;
		                add: playgroundToolCheckBox expand: false;
		                add: askFeatureCheckBox expand: false;
		                add: codeFeatureCheckBox expand: false;
		                yourself. "Logging & Cache Section"
	loggingSection := SpBoxLayout newTopToBottom
		                  spacing: 6;
		                  add: (self newLabel label: '— Logging & Cache —') expand: false;
		                  add: cacheCheckBox expand: false;
		                  add: (SpBoxLayout newHorizontal
				                   spacing: 8;
				                   add: loggingCheckBox expand: false;
				                   add: openLogsButton expand: false;
				                   yourself)
		                  expand: false;
		                  yourself. "UI Preferences Section"
	uiSection := SpBoxLayout newTopToBottom
		             spacing: 6;
		             add: (self newLabel label: '— UI Preferences —') expand: false;
		             add: feedbackCheckBox expand: false;
		             add: welcomeMessageCheckBox expand: false;
						 add: dynamicChatNamingCheckBox expand: false;
		             yourself.

	^ SpPresenter new
		  layout: (SpBoxLayout newTopToBottom
				   spacing: 16;
				   borderWidth: 10;
				   add: agentSection expand: false;
				   add: toolsSection expand: false;
				   add: loggingSection expand: false;
				   add: uiSection expand: false;
				   yourself);
		  yourself
]

{ #category : 'tabs' }
ChatPharoSettingsPresenter >> newConfigurationTab [

	^ SpPresenter new
		  layout: (SpBoxLayout newTopToBottom
				   add: (SpBoxLayout newHorizontal
						    add: 'Agent:' expand: false;
						    add: apiDropList;
						    yourself)
				   expand: false;
				   add: apiSettingsContainer;
				   yourself);
		  yourself
]

{ #category : 'tabs' }
ChatPharoSettingsPresenter >> newCustomToolsTab [
	"Creates the Custom Tools configuration tab"

	^ ChatPharoCustomToolsSettingsPresenter on: model
]

{ #category : 'tabs' }
ChatPharoSettingsPresenter >> newDebuggerTab [

	| infoLabel systemPromptInput |
	infoLabel := self newLabel
		             label: 'Debugger integration is enabled. Configure the system prompt used by Ask ChatPharo from the debugger.';
		             yourself.
	systemPromptInput := self newTextInput
		                     placeholder: 'Debugger system prompt...';
		                     text: model debuggerSystemPrompt;
		                     yourself.
	systemPromptInput whenTextChangedDo: [ :text | model debuggerSystemPrompt: text ].

	^ SpPresenter new
		  layout: (SpBoxLayout newTopToBottom
				   spacing: 8;
				   add: infoLabel expand: false;
				   add: (self newLabel label: 'System prompt:') expand: false;
				   add: systemPromptInput expand: true;
				   yourself);
		  yourself
]

{ #category : 'tabs' }
ChatPharoSettingsPresenter >> newEthicsTab [
	"Create the Ethics Director configuration tab."

	| developerNote |
	developerNote := ChatPharoSettings default isDeveloper
		                 ifTrue: [ '' ]
		                 ifFalse: [ ' (developer only)' ].
	^ SpPresenter new
		  layout: (SpBoxLayout newTopToBottom
				   spacing: 12;
				   borderWidth: 8;
				   add: (self newLabel label: 'Director of Ethics') expand: false;
				   add: ethicsDirectorCheckBox expand: false;
				   add: (SpBoxLayout newHorizontal
						    spacing: 8;
						    add: (self newLabel label: 'Ethics mandate:') expand: false;
						    add: ethicsMandateInput expand: true;
						    yourself)
				   expand: false;
				   add: (SpBoxLayout newHorizontal
						    spacing: 8;
						    add: (self newLabel label: 'Cognitive load budget:') expand: false;
						    add: cognitiveLoadBudgetInput expand: true;
						    yourself)
				   expand: false;
				   add: (SpBoxLayout newHorizontal
						    spacing: 8;
						    add: (self newLabel label: 'Token budget:') expand: false;
						    add: tokenBudgetInput expand: true;
						    yourself)
				   expand: false;
				   add: (SpBoxLayout newHorizontal
						    spacing: 8;
						    add: (self newLabel label: 'Time budget (minutes):') expand: false;
						    add: timeBudgetInput expand: true;
						    yourself)
				   expand: false;
				add: (SpBoxLayout newHorizontal
						    spacing: 8;
						    add: (self newLabel label: 'Request timeout (seconds):') expand: false;
						    add: requestTimeoutInput expand: true;
						    yourself)
				   expand: false;
				   add: (SpBoxLayout newHorizontal
						    spacing: 8;
						    add: (self newLabel label: 'Message limit per chat' , developerNote) expand: false;
						    add: messageLimitInput expand: true;
						    yourself)
				   expand: false;
				   yourself);
		  yourself
]

{ #category : 'tabs' }
ChatPharoSettingsPresenter >> newExtensionsTab [

	^ SpPresenter new
		  layout: (SpBoxLayout newTopToBottom
				   add: browserExtensionCheckBox expand: false;
				   add: icebergExtensionCheckBox expand: false;
				 add: debuggerExtensionCheckBox expand: false;
				   "add: browserAutoTabCheckBox expand: false;"yourself);
		  yourself
]

{ #category : 'tabs' }
ChatPharoSettingsPresenter >> newHistoryTab [

	| historyText historyView refreshButton clearButton buttonBar |
	historyText := self historyTextForChats.

	historyView := self newText.
	historyView text: historyText asText.
	
	refreshButton := self newButton
		                  label: 'Refresh';
		                  icon: (self iconNamed: #refresh);
		                  help: 'Refresh the history view';
		                  action: [ historyView text: self historyTextForChats asText ];
		                  yourself.

	clearButton := self newButton
		                label: 'Clear History';
		                icon: (self iconNamed: #delete);
		                help: 'Clear all chat history';
		                action: [
			                (self confirm: 'Are you sure you want to clear all chat history?') ifTrue: [
					                chatPharo ifNotNil: [
							                chatPharo chats do: [ :chat |
									                chat clearChat ] ].
					                model agent history clear.
					                historyView text: self historyTextForChats asText ] ];
		                yourself.

	buttonBar := SpBoxLayout newHorizontal
		             spacing: 8;
		             add: refreshButton expand: false;
		             add: clearButton expand: false;
		             yourself.

	^ SpPresenter new
		  layout: (SpBoxLayout newTopToBottom
		add: buttonBar expand: false;
				   add: historyView;
				   yourself);
		  yourself
]

{ #category : 'tabs' }
ChatPharoSettingsPresenter >> newIcebergTab [

	| infoLabel |
	infoLabel := self newLabel
		             label: 'Iceberg integration is enabled. Open the Iceberg commit browser to generate a commit message.';
		             yourself.

	systemPromptInput := self newTextInput
		                     placeholder: 'Iceberg system prompt...';
		                     text: model icebergSystemPrompt;
		                     yourself.
	systemPromptInput whenTextChangedDo: [ :text | model icebergSystemPrompt: text ].


	^ SpPresenter new
		  layout: (SpBoxLayout newTopToBottom
		 spacing: 8;
				   add: infoLabel expand: false;
				   add: (self newLabel label: 'System prompt:') expand: false;
				   add: systemPromptInput expand: true;
				   yourself);
		  yourself
]

{ #category : 'tabs' }
ChatPharoSettingsPresenter >> newMCPTab [
	"Creates the MCP (Model Context Protocol) configuration tab"

	^ ChatPharoMCPSettingsPresenter on: model
]

{ #category : 'tabs' }
ChatPharoSettingsPresenter >> newMemoryTab [
	"Creates the Long-Term Memory configuration tab"

	^ ChatPharoMemoryPresenter on: model
]

{ #category : 'tabs' }
ChatPharoSettingsPresenter >> newMultiversTab [
	"Creates the Multivers configuration tab"

	^ ChatPharoMultiversPresenter on: model
]

{ #category : 'tabs' }
ChatPharoSettingsPresenter >> newPersonalTab [
	"Create the personal configuration tab."

	| settings nameRow orgRow devIdRow statusRow buttonRow |
	settings := ChatPharoSettings default.

	userNameInput := self newTextInput
		placeholder: 'Your name...';
		text: settings userName;
		yourself.

	userOrganizationInput := self newTextInput
		placeholder: 'Organization/Company...';
		text: settings userOrganization;
		yourself.

	developerIdInput := self newTextInput
		placeholder: 'Developer ID (optional)...';
		text: settings developerId;
		yourself.

	developerStatusLabel := self newLabel
		label: (self developerStatusText);
		yourself.

	verifyDeveloperButton := self newButton
		label: 'Verify Developer ID';
		icon: (self iconNamed: #glamorousGo);
		action: [ self verifyDeveloperId ];
		yourself.

	userNameInput whenTextChangedDo: [ :text |
		settings userName: text trimBoth ].

	userOrganizationInput whenTextChangedDo: [ :text |
		settings userOrganization: text trimBoth ].

	nameRow := SpBoxLayout newHorizontal
		spacing: 8;
		add: (self newLabel label: 'Name:') expand: false;
		add: userNameInput expand: true;
		yourself.

	orgRow := SpBoxLayout newHorizontal
		spacing: 8;
		add: (self newLabel label: 'Organization:') expand: false;
		add: userOrganizationInput expand: true;
		yourself.

	devIdRow := SpBoxLayout newHorizontal
		spacing: 8;
		add: (self newLabel label: 'Developer ID:') expand: false;
		add: developerIdInput expand: true;
		yourself.

	statusRow := SpBoxLayout newHorizontal
		spacing: 8;
		add: (self newLabel label: 'Status:') expand: false;
		add: developerStatusLabel expand: true;
		yourself.

	buttonRow := SpBoxLayout newHorizontal
		spacing: 8;
		add: verifyDeveloperButton expand: false;
		yourself.

	^ SpPresenter new
		layout: (SpBoxLayout newTopToBottom
			spacing: 12;
			borderWidth: 8;
			add: nameRow expand: false;
			add: orgRow expand: false;
			add: devIdRow expand: false;
			add: buttonRow expand: false;
			add: statusRow expand: false;
			yourself);
		yourself
]

{ #category : 'tabs' }
ChatPharoSettingsPresenter >> newSkillsTab [
	"Creates the Skills configuration tab"

	^ ChatPharoSkillsSettingsPresenter on: model
]

{ #category : 'initialization' }
ChatPharoSettingsPresenter >> notebook [

	^ notebook
]

{ #category : 'initialization' }
ChatPharoSettingsPresenter >> notebook: anObject [

	notebook := anObject
]

{ #category : 'initialization' }
ChatPharoSettingsPresenter >> openLogs [
	"Open the ChatPharo log file."

	| logFile |
	logFile := ChatPharoLogger logFile.
	logFile exists
		ifTrue: [ WebBrowser openOn: logFile fullName ]
		ifFalse: [ self inform: 'No log file found. Enable logging and use ChatPharo to generate logs.' ]
]

{ #category : 'initialization' }
ChatPharoSettingsPresenter >> refreshApiSettings [

	| newPresenter |
	apiSettingsContainer removeAll.
	newPresenter := model agent class settingsPresenterFor: model agent.
	newPresenter ifNotNil: [ apiSettingsContainer add: newPresenter ].
	apiSettingsContainer changed 
]

{ #category : 'initialization' }
ChatPharoSettingsPresenter >> removeBrowserExtensionTab [ 
    browserExtensionPage ifNotNil: [
        notebook removePage: browserExtensionPage.
        browserExtensionPage := nil ]
]

{ #category : 'initialization' }
ChatPharoSettingsPresenter >> removeDebuggerExtensionTab [

	debuggerExtensionPage ifNotNil: [
		notebook removePage: debuggerExtensionPage.
		debuggerExtensionPage := nil ]
]

{ #category : 'initialization' }
ChatPharoSettingsPresenter >> removeIcebergExtensionTab [

	icebergExtensionPage ifNotNil: [
		notebook removePage: icebergExtensionPage.
		icebergExtensionPage := nil ]
]

{ #category : 'initialization' }
ChatPharoSettingsPresenter >> saveSettings [

	ChatPharoSettings setDefault: model.
	ChatPharoSettings saveDefault.
	self inform: 'Settings saved.'
]

{ #category : 'accessing - model' }
ChatPharoSettingsPresenter >> setModelBeforeInitialization: anObject [

	model := anObject
]

{ #category : 'initialization' }
ChatPharoSettingsPresenter >> updateBrowserExtensionTab [ 
    browserExtensionCheckBox state
        ifTrue: [ self ensureBrowserExtensionTab ]
        ifFalse: [ self removeBrowserExtensionTab ]
]

{ #category : 'initialization' }
ChatPharoSettingsPresenter >> updateDebuggerExtensionTab [

	debuggerExtensionCheckBox state
		ifTrue: [ self ensureDebuggerExtensionTab ]
		ifFalse: [ self removeDebuggerExtensionTab ]
]

{ #category : 'initialization' }
ChatPharoSettingsPresenter >> updateIcebergExtensionTab [

	icebergExtensionCheckBox state
		ifTrue: [ self ensureIcebergExtensionTab ]
		ifFalse: [ self removeIcebergExtensionTab ]
]

{ #category : 'initialization' }
ChatPharoSettingsPresenter >> verifyDeveloperId [
	"Verify the developer ID entered in the personal tab."

	| enteredId settings |
	enteredId := developerIdInput text trimBoth.
	settings := ChatPharoSettings default.

	enteredId isEmpty ifTrue: [
		settings isDeveloper: false.
		settings developerId: ''.
		developerStatusLabel label: 'Not a developer'.
		self inform: 'Developer ID cleared.'.
		^ self ].

	developerStatusLabel label: 'Verifying...'.
	verifyDeveloperButton enabled: false.

	[
		| isValid |
		isValid := ChatPharoDeveloperConfig verifyDeveloperId: enteredId.

		self defer: [
			verifyDeveloperButton enabled: true.
			isValid
				ifTrue: [
					settings developerId: enteredId.
					settings isDeveloper: true.
					developerStatusLabel label: 'Verified Developer'.
					self inform: 'Developer ID verified successfully!' ]
				ifFalse: [
					settings developerId: enteredId.
					settings isDeveloper: false.
					developerStatusLabel label: 'Developer ID not verified'.
					self inform: 'Invalid Developer ID.' ]
		]
	] fork
]
