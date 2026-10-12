"
I am the Ollama runtime: I find the `ollama` program and start `ollama serve`.
"
Class {
	#name : 'ChatPharoOllamaRuntime',
	#superclass : 'ChatPharoLocalRuntime',
	#category : 'AI-ChatPharo-Agent-Local',
	#package : 'AI-ChatPharo-Agent',
	#tag : 'Local'
}

{ #category : 'accessing' }
ChatPharoOllamaRuntime >> agentClass [

	^ ChatPharoOllamaAgent
]

{ #category : 'private' }
ChatPharoOllamaRuntime >> macLocations [

	^ self unixLocations , { '/Applications/Ollama.app/Contents/Resources/ollama' asFileReference }
]

{ #category : 'private' }
ChatPharoOllamaRuntime >> startCommandFor: anExecutable [

	^ (self quoted: anExecutable) , ' serve'
]

{ #category : 'private' }
ChatPharoOllamaRuntime >> unixLocations [

	^ {
		  '/usr/local/bin/ollama' asFileReference.
		  '/opt/homebrew/bin/ollama' asFileReference.
		  '/usr/bin/ollama' asFileReference.
		  (self home / '.local' / 'bin' / 'ollama') }
]

{ #category : 'private' }
ChatPharoOllamaRuntime >> windowsLocations [

	^ { (self home / 'AppData' / 'Local' / 'Programs' / 'Ollama' / 'ollama.exe') }
]
