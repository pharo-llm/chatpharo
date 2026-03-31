Extension { #name : 'IceTipCommitBrowser' }

{ #category : '*AI-ChatPharo-Env' }
IceTipCommitBrowser >> commentPanelClass [

	^ ChatPharoSettings default icebergExtensionEnabled
		ifTrue: [ ChatPharoIceTipCommentPanel ]
		ifFalse: [ IceTipCommentPanel ]
]

{ #category : '*AI-ChatPharo-Env' }
IceTipCommitBrowser >> initializeAcceptShortcut [

	commentPanel commentText
		addShortcutWith: [ :action |
			action
				shortcutKey: $s actionModifier;
				action: [ self accept ] ]
]
