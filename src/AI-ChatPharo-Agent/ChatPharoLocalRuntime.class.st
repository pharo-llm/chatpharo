"
I represent an LLM runtime installed on the user's machine, such as Ollama or
LM Studio.

I answer three questions and act on them:

- `isInstalled` — is the program on this machine? Pharo started from a launcher
  does not inherit the shell PATH, so I look at the usual install locations
  instead of asking `which`.
- `isRunning` — does its local server answer?
- `ensureRunning` — start it when it is installed but not running, and wait
  until its server answers.

Subclasses name the program, where it is installed per platform, and how to
start its server.

```smalltalk
ChatPharoLocalRuntime installed collect: [ :each | each statusLine ].
ChatPharoOllamaRuntime new ensureRunning
```
"
Class {
	#name : 'ChatPharoLocalRuntime',
	#superclass : 'Object',
	#instVars : [
		'shell',
		'startupTimeout'
	],
	#category : 'AI-ChatPharo-Agent-Local',
	#package : 'AI-ChatPharo-Agent',
	#tag : 'Local'
}

{ #category : 'accessing' }
ChatPharoLocalRuntime class >> all [
	"The local runtimes ChatPharo knows how to find and start."

	^ {
		  ChatPharoOllamaRuntime new.
		  ChatPharoLMStudioRuntime new }
]

{ #category : 'accessing' }
ChatPharoLocalRuntime class >> installed [

	^ self all select: [ :each | each isInstalled ]
]

{ #category : 'testing' }
ChatPharoLocalRuntime class >> isAbstract [

	^ self = ChatPharoLocalRuntime
]

{ #category : 'accessing' }
ChatPharoLocalRuntime >> agentClass [
	"The ChatPharoAgent subclass that talks to my server."

	^ self subclassResponsibility
]

{ #category : 'private' }
ChatPharoLocalRuntime >> candidateLocations [

	OSPlatform current isWindows ifTrue: [ ^ self windowsLocations ].
	OSPlatform current isMacOS ifTrue: [ ^ self macLocations ].
	^ self unixLocations
]

{ #category : 'accessing' }
ChatPharoLocalRuntime >> displayName [

	^ self agentClass displayName
]

{ #category : 'running' }
ChatPharoLocalRuntime >> ensureRunning [
	"Answer whether my server answers, starting it first when it is installed but stopped."

	self isRunning ifTrue: [ ^ true ].
	self isInstalled ifFalse: [ ^ false ].
	self start.
	^ self waitUntilRunning
]

{ #category : 'accessing' }
ChatPharoLocalRuntime >> executable [
	"The installed program, or nil when it is not on this machine."

	^ self candidateLocations detect: [ :each | each exists ] ifNone: [ nil ]
]

{ #category : 'private' }
ChatPharoLocalRuntime >> home [

	^ FileLocator home asFileReference
]

{ #category : 'testing' }
ChatPharoLocalRuntime >> isInstalled [

	^ self executable notNil
]

{ #category : 'testing' }
ChatPharoLocalRuntime >> isRunning [

	^ self agentClass isReachable
]

{ #category : 'private' }
ChatPharoLocalRuntime >> macLocations [

	^ self unixLocations
]

{ #category : 'private' }
ChatPharoLocalRuntime >> quoted: aFileReference [

	^ '"' , aFileReference fullName , '"'
]

{ #category : 'accessing' }
ChatPharoLocalRuntime >> shell [

	^ shell ifNil: [ shell := ChatPharoShell new ]
]

{ #category : 'accessing' }
ChatPharoLocalRuntime >> shell: aShell [

	shell := aShell
]

{ #category : 'running' }
ChatPharoLocalRuntime >> start [
	"Start my server in the background. Use #ensureRunning to also wait for it."

	self shell launch: (self startCommandFor: self executable)
]

{ #category : 'private' }
ChatPharoLocalRuntime >> startCommandFor: anExecutable [

	^ self subclassResponsibility
]

{ #category : 'accessing' }
ChatPharoLocalRuntime >> startupTimeout [

	^ startupTimeout ifNil: [ startupTimeout := 30 seconds ]
]

{ #category : 'accessing' }
ChatPharoLocalRuntime >> startupTimeout: aDuration [

	startupTimeout := aDuration
]

{ #category : 'accessing' }
ChatPharoLocalRuntime >> statusLine [

	self isRunning ifTrue: [ ^ self displayName , ': running' ].
	^ self displayName , (self isInstalled
		   ifTrue: [ ': installed, not running' ]
		   ifFalse: [ ': not installed' ])
]

{ #category : 'private' }
ChatPharoLocalRuntime >> unixLocations [

	^ self subclassResponsibility
]

{ #category : 'private' }
ChatPharoLocalRuntime >> waitUntilRunning [

	| deadline |
	deadline := DateAndTime now + self startupTimeout.
	[ self isRunning ] whileFalse: [
		DateAndTime now > deadline ifTrue: [ ^ false ].
		(Delay forMilliseconds: 500) wait ].
	^ true
]

{ #category : 'private' }
ChatPharoLocalRuntime >> windowsLocations [

	^ self subclassResponsibility
]
