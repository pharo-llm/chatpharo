Extension { #name : 'ToolShortcutsCategory' }

{ #category : '*AI-ChatPharo-Env' }
ToolShortcutsCategory >> openChatPharo [

	<shortcut>
	^ KMKeymap 
		shortcut: PharoShortcuts current openChatPharoShortcut 
		action: [ ChatPharoState openTempChatPresenter ]
]
