"
I am the panel of the **terminal agents** application: I start and stop
`ChatPharoMCPBridge` and show the commands that connect Claude Code, Codex CLI
and Gemini CLI to the tools of this image.
"
Class {
	#name : 'ChatPharoMCPBridgePresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'bridge',
		'statusLabel',
		'toggleButton',
		'instructionsText',
		'copyButton'
	],
	#category : 'AI-ChatPharo-Spec-Extentions',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Extentions'
}

{ #category : 'initialization' }
ChatPharoMCPBridgePresenter >> connectPresenters [

	toggleButton action: [ self toggleBridge ].
	copyButton action: [
		Clipboard clipboardText: bridge connectionInstructions.
		self inform: 'Commands copied to the clipboard' ]
]

{ #category : 'layout' }
ChatPharoMCPBridgePresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 8;
		  add: (SpBoxLayout newLeftToRight
				   spacing: 8;
				   add: statusLabel;
				   add: toggleButton expand: false;
				   yourself)
		  expand: false;
		  add: 'Run one of these commands in your terminal while the bridge is running:' expand: false;
		  add: instructionsText;
		  add: copyButton expand: false;
		  add: 'The agent gets the tools enabled in Settings. Tools that change the image ask you first, here in Pharo.'
		  expand: false;
		  yourself
]

{ #category : 'initialization' }
ChatPharoMCPBridgePresenter >> initializePresenters [

	statusLabel := self newLabel.
	toggleButton := self newButton.
	instructionsText := self newText
		                    text: bridge connectionInstructions;
		                    beNotEditable;
		                    yourself.
	copyButton := self newButton
		              label: 'Copy commands';
		              icon: (self iconNamed: #smallCopy);
		              yourself.
	self updateStatus
]

{ #category : 'accessing - model' }
ChatPharoMCPBridgePresenter >> setModelBeforeInitialization: aBridge [

	bridge := aBridge
]

{ #category : 'actions' }
ChatPharoMCPBridgePresenter >> toggleBridge [

	bridge isRunning
		ifTrue: [ bridge stop ]
		ifFalse: [ bridge start ].
	self updateStatus
]

{ #category : 'updating' }
ChatPharoMCPBridgePresenter >> updateStatus [

	statusLabel label: (bridge isRunning
			 ifTrue: [ 'Running at ' , bridge url ]
			 ifFalse: [ 'Stopped. Terminal agents cannot reach this image.' ]).
	toggleButton
		label: (bridge isRunning
				 ifTrue: [ 'Stop' ]
				 ifFalse: [ 'Start' ]);
		icon: (self iconNamed: (bridge isRunning
						  ifTrue: [ #stop ]
						  ifFalse: [ #smallDoIt ]))
]
