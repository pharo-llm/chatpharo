"
I am the Applications tab of the settings: the optional capabilities of
ChatPharo. Tick an application to activate it, select it to configure it and to
see the tools it gives the model.

- Tools — every built-in tool, with its switch.
- Plans and tasks — plan first, validate each step, follow progress.
- Context — what the model is told before each request.
- Local runtimes — find and start Ollama or LM Studio.
- Terminal agents — let Claude Code, Codex or Gemini CLI use the tools.
- MCP, Multivers, Skills, Memory, Custom Tools.
"
Class {
	#name : 'ChatPharoApplicationSettingsPresenter',
	#superclass : 'ChatPharoFeatureSettingsPresenter',
	#category : 'AI-ChatPharo-Spec-Core',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Core'
}

{ #category : 'private - features' }
ChatPharoApplicationSettingsPresenter >> contextFeature [

	^ (ChatPharoSettingsFeature
		   named: 'Context'
		   description: 'What ChatPharo tells the model before each request: environment, project, session.'
		   icon: #book)
		  configuredBy: [ ChatPharoContextSettingsPresenter on: model ];
		  yourself
]

{ #category : 'private - features' }
ChatPharoApplicationSettingsPresenter >> customToolsFeature [

	^ (ChatPharoSettingsFeature named: 'Custom Tools' description: 'Define custom tools for the agent to use' icon: #smallObjects)
		  configuredBy: [ ChatPharoCustomToolsSettingsPresenter on: model ];
		  yourself
]

{ #category : 'accessing' }
ChatPharoApplicationSettingsPresenter >> features [

	^ {
		  self toolsFeature.
		  self plansFeature.
		  self contextFeature.
		  self localRuntimesFeature.
		  self terminalAgentsFeature.
		  self mcpFeature.
		  self multiversFeature.
		  self skillsFeature.
		  self memoryFeature.
		  self customToolsFeature }
]

{ #category : 'accessing' }
ChatPharoApplicationSettingsPresenter >> listTitle [

	^ 'Application'
]

{ #category : 'private - features' }
ChatPharoApplicationSettingsPresenter >> localRuntimesFeature [

	^ (ChatPharoSettingsFeature
		   named: 'Local runtimes'
		   description: 'Ollama and LM Studio on this machine: detected, and started when needed.'
		   icon: #smallHome)
		  enabledWhen: [ model autoStartLocalRuntimes ] toggledBy: [ :state | model autoStartLocalRuntimes: state ];
		  configuredBy: [ ChatPharoLocalRuntimesPresenter new ];
		  yourself
]

{ #category : 'private - features' }
ChatPharoApplicationSettingsPresenter >> mcpFeature [

	^ (ChatPharoSettingsFeature
		   named: 'MCP'
		   description: 'Model Context Protocol - connect to external tool servers'
		   icon: #network)
		  enabledWhen: [ model mcpEnabled ] toggledBy: [ :state | model mcpEnabled: state ];
		  configuredBy: [ ChatPharoMCPSettingsPresenter on: model ];
		  providingTools: [ model mcpToolsAsClients ];
		  yourself
]

{ #category : 'private - features' }
ChatPharoApplicationSettingsPresenter >> memoryFeature [

	^ (ChatPharoSettingsFeature named: 'Memory' description: 'Long-term memory for conversation context' icon: #history)
		  enabledWhen: [ model memoryEnabled ] toggledBy: [ :state | model memoryEnabled: state ];
		  configuredBy: [ ChatPharoMemoryPresenter on: model ];
		  yourself
]

{ #category : 'private - features' }
ChatPharoApplicationSettingsPresenter >> multiversFeature [

	^ (ChatPharoSettingsFeature
		   named: 'Multivers'
		   description: 'Chain multiple agents in sequence for complex workflows'
		   icon: #branch)
		  enabledWhen: [ model multiversEnabled ] toggledBy: [ :state | model multiversEnabled: state ];
		  configuredBy: [ ChatPharoMultiversPresenter on: model ];
		  yourself
]

{ #category : 'private - features' }
ChatPharoApplicationSettingsPresenter >> plansFeature [

	^ (ChatPharoSettingsFeature
		   named: 'Plans and tasks'
		   description: 'ChatPharo proposes a plan, you validate each step, the Task Manager shows progress.'
		   icon: #smallProfile)
		  enabledWhen: [ model planValidationEnabled ] toggledBy: [ :state | model planValidationEnabled: state ];
		  configuredBy: [ ChatPharoPlanSettingsPresenter new ];
		  providingTools: [ ChatPharoPlanTools new tools ];
		  yourself
]

{ #category : 'private - features' }
ChatPharoApplicationSettingsPresenter >> skillsFeature [

	^ (ChatPharoSettingsFeature
		   named: 'Skills'
		   description: 'Manage skill files and automatic skill detection'
		   icon: #smallObjects)
		  enabledWhen: [ model skillToolsEnabled ] toggledBy: [ :state | model skillToolsEnabled: state ];
		  configuredBy: [ ChatPharoSkillsSettingsPresenter on: model ];
		  yourself
]

{ #category : 'private - features' }
ChatPharoApplicationSettingsPresenter >> terminalAgentsFeature [

	^ (ChatPharoSettingsFeature
		   named: 'Terminal agents'
		   description: 'Let Claude Code, Codex CLI or Gemini CLI use the ChatPharo tools of this image.'
		   icon: #smallRemoteOpen)
		  enabledWhen: [ ChatPharoMCPBridge default isRunning ] toggledBy: [ :state | self runBridge: state ];
		  configuredBy: [ ChatPharoMCPBridgePresenter on: ChatPharoMCPBridge default ];
		  providingTools: [ (ChatPharoToolbox settings: model) enabledTools ];
		  yourself
]

{ #category : 'private' }
ChatPharoApplicationSettingsPresenter >> runBridge: aBoolean [

	aBoolean
		ifTrue: [ ChatPharoMCPBridge default start ]
		ifFalse: [ ChatPharoMCPBridge default stop ]
]

{ #category : 'private - features' }
ChatPharoApplicationSettingsPresenter >> toolsFeature [

	^ (ChatPharoSettingsFeature
		   named: 'Tools'
		   description: 'Every tool ChatPharo can use on your image. Untick a tool to keep it away from the model.'
		   icon: #smallConfiguration)
		  configuredBy: [ self newLabel label: 'Tools that change the image ask for your confirmation before they run.' ];
		  providingTools: [ (ChatPharoToolbox settings: model) builtInTools ];
		  yourself
]
