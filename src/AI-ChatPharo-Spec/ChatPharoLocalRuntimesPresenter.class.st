"
I show the LLM runtimes installed on this machine — Ollama, LM Studio — whether
their server answers, and I start the one the user selects.
"
Class {
	#name : 'ChatPharoLocalRuntimesPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'runtimeTable',
		'startButton',
		'refreshButton'
	],
	#category : 'AI-ChatPharo-Spec-Extentions',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Extentions'
}

{ #category : 'initialization' }
ChatPharoLocalRuntimesPresenter >> connectPresenters [

	startButton action: [ self startSelectedRuntime ].
	refreshButton action: [ self refresh ]
]

{ #category : 'layout' }
ChatPharoLocalRuntimesPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 8;
		  add: 'When active, ChatPharo starts an installed runtime that is not running before it sends a message.'
		  expand: false;
		  add: runtimeTable;
		  add: (SpBoxLayout newLeftToRight
				   spacing: 8;
				   add: startButton expand: false;
				   add: refreshButton expand: false;
				   yourself)
		  expand: false;
		  yourself
]

{ #category : 'initialization' }
ChatPharoLocalRuntimesPresenter >> initializePresenters [

	runtimeTable := self newTable
		                addColumn: ((SpStringTableColumn title: 'Runtime' evaluated: [ :runtime | runtime displayName ])
				                 width: 120;
				                 yourself);
		                addColumn: (SpStringTableColumn title: 'State' evaluated: [ :runtime | self stateOf: runtime ]);
		                addColumn: (SpStringTableColumn title: 'Program' evaluated: [ :runtime | self programOf: runtime ]);
		                items: ChatPharoLocalRuntime all;
		                yourself.
	startButton := self newButton
		               label: 'Start selected';
		               icon: (self iconNamed: #smallDoIt);
		               yourself.
	refreshButton := self newButton
		                 label: 'Refresh';
		                 icon: (self iconNamed: #refresh);
		                 yourself
]

{ #category : 'private' }
ChatPharoLocalRuntimesPresenter >> programOf: aRuntime [

	^ aRuntime executable
		  ifNil: [ '' ]
		  ifNotNil: [ :executable | executable fullName ]
]

{ #category : 'actions' }
ChatPharoLocalRuntimesPresenter >> refresh [

	runtimeTable items: ChatPharoLocalRuntime all
]

{ #category : 'actions' }
ChatPharoLocalRuntimesPresenter >> startSelectedRuntime [
	"Starting waits for the server, so it runs beside the UI and the table is refreshed afterwards."

	| runtime |
	runtime := runtimeTable selectedItem.
	runtime ifNil: [ ^ self inform: 'Select a runtime first.' ].
	[
		runtime ensureRunning.
		self defer: [ self refresh ] ] fork
]

{ #category : 'private' }
ChatPharoLocalRuntimesPresenter >> stateOf: aRuntime [

	aRuntime isRunning ifTrue: [ ^ 'running' ].
	^ aRuntime isInstalled
		  ifTrue: [ 'installed, not running' ]
		  ifFalse: [ 'not installed' ]
]
