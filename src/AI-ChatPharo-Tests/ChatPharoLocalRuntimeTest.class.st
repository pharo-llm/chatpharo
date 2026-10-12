Class {
	#name : 'ChatPharoLocalRuntimeTest',
	#superclass : 'TestCase',
	#category : 'AI-ChatPharo-Tests-Agent',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Agent'
}

{ #category : 'tests' }
ChatPharoLocalRuntimeTest >> testEnsureRunningDoesNotStartWhatIsNotInstalled [

	| runtime |
	runtime := ChatPharoTestRuntime new
		           installed: false;
		           yourself.
	self deny: runtime ensureRunning.
	self assert: runtime launchedCommands isEmpty
]

{ #category : 'tests' }
ChatPharoLocalRuntimeTest >> testEnsureRunningGivesUpAfterTheStartupTimeout [

	| runtime |
	runtime := ChatPharoTestRuntime new
		           neverStarts;
		           startupTimeout: 100 milliSeconds;
		           yourself.
	self deny: runtime ensureRunning
]

{ #category : 'tests' }
ChatPharoLocalRuntimeTest >> testEnsureRunningLeavesARunningServerAlone [

	| runtime |
	runtime := ChatPharoTestRuntime new
		           running: true;
		           yourself.
	self assert: runtime ensureRunning.
	self assert: runtime launchedCommands isEmpty
]

{ #category : 'tests' }
ChatPharoLocalRuntimeTest >> testEnsureRunningStartsAnInstalledServerAndWaitsForIt [

	| runtime |
	runtime := ChatPharoTestRuntime new.
	self assert: runtime ensureRunning.
	self assert: runtime launchedCommands size equals: 1.
	self assert: (runtime launchedCommands first endsWith: ' serve')
]

{ #category : 'tests' }
ChatPharoLocalRuntimeTest >> testKnownRuntimesAreOllamaAndLMStudio [

	self assert: (ChatPharoLocalRuntime all collect: [ :each | each displayName ]) asArray equals: #( 'Ollama' 'LM Studio' )
]

{ #category : 'tests' }
ChatPharoLocalRuntimeTest >> testStartCommandQuotesTheExecutablePath [

	self
		assert: (ChatPharoOllamaRuntime new startCommandFor: '/Applications/My Apps/ollama' asFileReference)
		equals: '"/Applications/My Apps/ollama" serve'.
	self
		assert: (ChatPharoLMStudioRuntime new startCommandFor: '/home/ada/.lmstudio/bin/lms' asFileReference)
		equals: '"/home/ada/.lmstudio/bin/lms" server start'
]

{ #category : 'tests' }
ChatPharoLocalRuntimeTest >> testStatusLine [

	self assert: (ChatPharoTestRuntime new running: true; statusLine) equals: 'Test runtime: running'.
	self assert: ChatPharoTestRuntime new statusLine equals: 'Test runtime: installed, not running'.
	self assert: (ChatPharoTestRuntime new installed: false; statusLine) equals: 'Test runtime: not installed'
]
