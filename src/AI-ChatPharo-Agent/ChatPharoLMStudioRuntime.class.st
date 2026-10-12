"
I am the LM Studio runtime: I find its `lms` command line tool, installed in
`~/.lmstudio/bin` on every platform, and start `lms server start`.
"
Class {
	#name : 'ChatPharoLMStudioRuntime',
	#superclass : 'ChatPharoLocalRuntime',
	#category : 'AI-ChatPharo-Agent-Local',
	#package : 'AI-ChatPharo-Agent',
	#tag : 'Local'
}

{ #category : 'accessing' }
ChatPharoLMStudioRuntime >> agentClass [

	^ ChatPharoLMStudioAgent
]

{ #category : 'private' }
ChatPharoLMStudioRuntime >> startCommandFor: anExecutable [

	^ (self quoted: anExecutable) , ' server start'
]

{ #category : 'private' }
ChatPharoLMStudioRuntime >> unixLocations [

	^ {
		  (self home / '.lmstudio' / 'bin' / 'lms').
		  (self home / '.cache' / 'lm-studio' / 'bin' / 'lms') }
]

{ #category : 'private' }
ChatPharoLMStudioRuntime >> windowsLocations [

	^ { (self home / '.lmstudio' / 'bin' / 'lms.exe') }
]
