Extension { #name : 'StDebugger' }

{ #category : '*AI-ChatPharo-Env' }
StDebugger class >> chatPharoBrowseCommandWith: aPresenter forRootGroup: aCmCommandsGroup [

	<extensionCommands>
	| command stackGroup decoratedGroup intelligentCommand |
	intelligentCommand := StIntelligentDebugChatPharoCommand forSpecContext: aPresenter.
	stackGroup := aCmCommandsGroup / StDebuggerStackCommandTreeBuilder groupName.
	decoratedGroup := stackGroup decoratedGroup.
	decoratedGroup register: intelligentCommand.
	decoratedGroup entries remove: intelligentCommand ifAbsent: [ ].
	decoratedGroup entries addFirst: intelligentCommand.
	command := StAskChatPharoFromDebuggerCommand forSpecContext: aPresenter.
	decoratedGroup register: command.
	decoratedGroup entries remove: command ifAbsent: [ ].
	decoratedGroup entries add: command afterIndex: 1
]
