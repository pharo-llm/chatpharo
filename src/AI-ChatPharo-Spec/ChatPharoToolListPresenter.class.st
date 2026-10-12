"
I list tools with their description. Built-in tools have a check box that
enables or disables them for every chat and for terminal agents; tools that only
exist in a special context, such as the debugger tools, are listed for
information.
"
Class {
	#name : 'ChatPharoToolListPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'settings',
		'tools',
		'toolTable',
		'switchableNames'
	],
	#category : 'AI-ChatPharo-Spec-Core',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Core'
}

{ #category : 'layout' }
ChatPharoToolListPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  add: toolTable;
		  yourself
]

{ #category : 'actions' }
ChatPharoToolListPresenter >> enable: aTool to: aBoolean [

	(self isSwitchable: aTool) ifFalse: [ ^ toolTable refresh ].
	aBoolean
		ifTrue: [ settings enableBrowserTool: aTool name ]
		ifFalse: [ settings disableBrowserTool: aTool name ]
]

{ #category : 'initialization' }
ChatPharoToolListPresenter >> initializePresenters [

	tools := #(  ).
	switchableNames := (ChatPharoToolbox settings: settings) builtInTools collect: [ :each | each name ] as: Set.
	toolTable := self newTable
		             addColumn: ((SpCheckBoxTableColumn title: 'On' evaluated: [ :tool | self isEnabled: tool ])
				              onActivation: [ :tool | self enable: tool to: true ];
				              onDeactivation: [ :tool | self enable: tool to: false ];
				              width: 40;
				              yourself);
		             addColumn: ((SpStringTableColumn title: 'Tool' evaluated: [ :tool | tool name ])
				              width: 210;
				              yourself);
		             addColumn: (SpStringTableColumn title: 'What it does' evaluated: [ :tool | tool description ]);
		             yourself
]

{ #category : 'testing' }
ChatPharoToolListPresenter >> isEnabled: aTool [
	"Tools that cannot be switched are always available where they apply."

	^ (self isSwitchable: aTool) not or: [ settings browserToolsEnabled includes: aTool name ]
]

{ #category : 'testing' }
ChatPharoToolListPresenter >> isSwitchable: aTool [

	^ switchableNames includes: aTool name
]

{ #category : 'accessing - model' }
ChatPharoToolListPresenter >> setModelBeforeInitialization: aSettings [

	settings := aSettings
]

{ #category : 'accessing' }
ChatPharoToolListPresenter >> tools: aCollection [

	tools := aCollection.
	toolTable items: tools
]
