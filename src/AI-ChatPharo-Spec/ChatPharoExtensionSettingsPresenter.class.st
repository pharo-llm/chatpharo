"
I am the Extensions tab of the settings: the places where ChatPharo plugs into
the Pharo IDE — the System Browser, Iceberg and the debugger.

I use the same list-and-detail UI as the Applications tab: tick an extension to
activate it, select it to configure it and to see the tools it gives the model.
"
Class {
	#name : 'ChatPharoExtensionSettingsPresenter',
	#superclass : 'ChatPharoFeatureSettingsPresenter',
	#category : 'AI-ChatPharo-Spec-Extentions',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Extentions'
}

{ #category : 'private' }
ChatPharoExtensionSettingsPresenter >> debuggerFeature [

	^ (ChatPharoSettingsFeature
		   named: 'Debugger'
		   description: 'Ask ChatPharo from the debugger: it reads the stack, explains the error and proposes a fix.'
		   icon: #smallDebug)
		  enabledWhen: [ model debuggerExtensionEnabled ] toggledBy: [ :state | model debuggerExtensionEnabled: state ];
		  configuredBy: [
			  ChatPharoPromptSettingsPresenter on: (ChatPharoPromptSetting
					   explaining: 'System prompt used when ChatPharo is asked from the debugger:'
					   reading: [ model debuggerSystemPrompt ]
					   writing: [ :text | model debuggerSystemPrompt: text ]) ];
		  providingTools: [ (ChatPharoDebuggerEnvironment forContext: nil) tools ];
		  yourself
]

{ #category : 'accessing' }
ChatPharoExtensionSettingsPresenter >> features [

	^ {
		  self systemBrowserFeature.
		  self icebergFeature.
		  self debuggerFeature }
]

{ #category : 'private' }
ChatPharoExtensionSettingsPresenter >> icebergFeature [

	^ (ChatPharoSettingsFeature
		   named: 'Iceberg'
		   description: 'Generate commit messages from the changes shown in the Iceberg commit window.'
		   icon: #git)
		  enabledWhen: [ model icebergExtensionEnabled ] toggledBy: [ :state | model icebergExtensionEnabled: state ];
		  configuredBy: [
			  ChatPharoPromptSettingsPresenter on: (ChatPharoPromptSetting
					   explaining: 'System prompt used to write commit messages ({{commitTemplate}} is replaced by your template):'
					   reading: [ model icebergSystemPrompt ]
					   writing: [ :text | model icebergSystemPrompt: text ]) ];
		  yourself
]

{ #category : 'accessing' }
ChatPharoExtensionSettingsPresenter >> listTitle [

	^ 'Extension'
]

{ #category : 'private' }
ChatPharoExtensionSettingsPresenter >> systemBrowserFeature [
	"Its panel already lists the tools, grouped, with their switches."

	^ (ChatPharoSettingsFeature
		   named: 'System Browser'
		   description: 'A ChatPharo tab in the System Browser, focused on the package, class or method you are browsing.'
		   icon: #nautilus)
		  enabledWhen: [ model browserExtensionEnabled ] toggledBy: [ :state | model browserExtensionEnabled: state ];
		  configuredBy: [ ChatPharoBrowserExtensionSettingsPresenter on: model ];
		  yourself
]
