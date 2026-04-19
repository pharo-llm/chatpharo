Extension { #name : 'ToolShortcutsCategory' }

{ #category : '*AI-ChatPharo-Env' }
ToolShortcutsCategory >> askChatPharo [

	<shortcut>
	^ KMKeymap shortcut: ChatPharoShortcuts current askShortcut action: [ ChatPharoAskCommand new execute ]
]

{ #category : '*AI-ChatPharo-Env' }
ToolShortcutsCategory >> codeChatPharo [

	<shortcut>
	^ KMKeymap shortcut: ChatPharoShortcuts current codeShortcut action: [ ChatPharoCodeCommand new execute ]
]

{ #category : '*AI-ChatPharo-Env' }
ToolShortcutsCategory >> openChatPharo [

	<shortcut>
	^ KMKeymap 
		shortcut: PharoShortcuts current openChatPharoShortcut 
		action: [ ChatPharoState openTempChatPresenter ]
]
