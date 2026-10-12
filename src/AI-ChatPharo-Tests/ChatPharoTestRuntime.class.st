"
I am a local runtime whose installation and server are simulated: launching me
records the command and, unless told otherwise, makes me report as running.
"
Class {
	#name : 'ChatPharoTestRuntime',
	#superclass : 'ChatPharoLocalRuntime',
	#instVars : [
		'installed',
		'running',
		'startsWhenLaunched',
		'launchedCommands'
	],
	#category : 'AI-ChatPharo-Tests-Mock',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Mock'
}

{ #category : 'accessing' }
ChatPharoTestRuntime >> displayName [

	^ 'Test runtime'
]

{ #category : 'accessing' }
ChatPharoTestRuntime >> executable [

	^ installed ifTrue: [ '/opt/test runtime/bin/server' asFileReference ]
]

{ #category : 'initialization' }
ChatPharoTestRuntime >> initialize [

	super initialize.
	installed := true.
	running := false.
	startsWhenLaunched := true.
	launchedCommands := OrderedCollection new.
	self shell: self
]

{ #category : 'accessing' }
ChatPharoTestRuntime >> installed: aBoolean [

	installed := aBoolean
]

{ #category : 'testing' }
ChatPharoTestRuntime >> isRunning [

	^ running
]

{ #category : 'shell' }
ChatPharoTestRuntime >> launch: aCommandLine [
	"I am my own shell."

	launchedCommands add: aCommandLine.
	running := startsWhenLaunched
]

{ #category : 'accessing' }
ChatPharoTestRuntime >> launchedCommands [

	^ launchedCommands
]

{ #category : 'accessing' }
ChatPharoTestRuntime >> neverStarts [

	startsWhenLaunched := false
]

{ #category : 'accessing' }
ChatPharoTestRuntime >> running: aBoolean [

	running := aBoolean
]

{ #category : 'private' }
ChatPharoTestRuntime >> startCommandFor: anExecutable [

	^ (self quoted: anExecutable) , ' serve'
]
