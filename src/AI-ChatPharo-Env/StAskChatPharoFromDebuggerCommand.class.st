"
Debugger command that opens ChatPharo for the selected stack-frame method.

Use this command to ask for explanations or guidance while investigating a failing execution context.
"
Class {
	#name : 'StAskChatPharoFromDebuggerCommand',
	#superclass : 'StDebuggerCommand',
	#category : 'AI-ChatPharo-Env-Debugger',
	#package : 'AI-ChatPharo-Env',
	#tag : 'Debugger'
}

{ #category : 'default' }
StAskChatPharoFromDebuggerCommand class >> defaultDescription [

	^ 'Open ChatPharo and ask about the selected debugger stack method.'
]

{ #category : 'initialization' }
StAskChatPharoFromDebuggerCommand class >> defaultIconName [

	"Use a named icon because StDebuggerCommand>>forSpecContext:
	expects an icon name symbol."
	^ #chatPharoIcon
]

{ #category : 'default' }
StAskChatPharoFromDebuggerCommand class >> defaultName [

	^ 'Ask ChatPharo'
]

{ #category : 'initialization' }
StAskChatPharoFromDebuggerCommand class >> defaultShortcut [

	^ nil
]

{ #category : 'initialization' }
StAskChatPharoFromDebuggerCommand class >> icon [

	^ ChatPharoIcons chatPharoIcon
]

{ #category : 'testing' }
StAskChatPharoFromDebuggerCommand >> appliesTo: aDebugger [

	^ ((ChatPharoSettings default askFeatureEnabled)
		and: [ ChatPharoSettings default debuggerExtensionEnabled ])
		and: [ aDebugger selectedContext notNil ]
]

{ #category : 'executing' }
StAskChatPharoFromDebuggerCommand >> execute [

	| method settings |
	method := self debugger stackSelectionMethod ifNil: [ ^ self ].
settings := ChatPharoSettings default.
	ChatPharo askAboutMethod: method withSystemPrompt: settings debuggerSystemPrompt
]
