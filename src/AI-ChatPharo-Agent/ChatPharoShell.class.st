"
I launch programs on the user's machine without blocking the image.

I am the single place where ChatPharo talks to the operating system shell, so
that `ChatPharoLocalRuntime` can be tested with a recording stand-in.

`launch:` starts a command detached from the image: it keeps running after the
call returns and its output is discarded.
"
Class {
	#name : 'ChatPharoShell',
	#superclass : 'Object',
	#category : 'AI-ChatPharo-Agent-Local',
	#package : 'AI-ChatPharo-Agent',
	#tag : 'Local'
}

{ #category : 'private' }
ChatPharoShell >> detachedCommandFor: aCommandLine [

	^ OSPlatform current isWindows
		  ifTrue: [ 'start "" /B ' , aCommandLine ]
		  ifFalse: [ 'nohup ' , aCommandLine , ' >/dev/null 2>&1 &' ]
]

{ #category : 'running' }
ChatPharoShell >> launch: aCommandLine [

	ChatPharoLogger logSystem: 'Launching local program' details: (Dictionary with: 'command' -> aCommandLine).
	^ LibC runCommand: (self detachedCommandFor: aCommandLine)
]
