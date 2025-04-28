Class {
	#name : 'OllamaAPITest',
	#superclass : 'TestCase',
	#instVars : [
		'ollamaApi'
	],
	#category : 'AI-ChatPharo-Tests-Ollama',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Ollama'
}

{ #category : 'running' }
OllamaAPITest >> setUp [
	super setUp.
	
	"Initialize with native API for compatibility with existing tests"
	ollamaApi := OllamaAPI newWithNativeAPI.
	ollamaApi model: ollamaApi modelNames first.
]

{ #category : 'tests' }
OllamaAPITest >> testGetResponseForPrompt [
	"Test that we can get a response from Ollama using the native API"
	
	| response |
	response := ollamaApi getResponseWithNativeAPIForPrompt: 'Can you read these words. Please answer Yes or no'.
	self assert: (response includesSubstring: 'Yes')
]

{ #category : 'tests' }
OllamaAPITest >> testModelInformation [
	"Test that the connection to the model works"

	self 
		assert: ollamaApi modelInformation class 
		equals: Dictionary 
]

{ #category : 'tests' }
OllamaAPITest >> testModelNames [
	"Check that the modelNames function works and returns a non-empty collection"
	
	| modelNames |
	modelNames := ollamaApi modelNames.
	self assert: modelNames size >= 1
]

{ #category : 'tests' }
OllamaAPITest >> testOllamaVersion [
	"Check that the ollamaVersion function works and returns a valid version"
	
	| version |
	version := OllamaAPI ollamaVersion.
	self assert: (version >= '0.5.10')
]

{ #category : 'tests' }
OllamaAPITest >> testPromptPrefix [
	"Test that the promptPrefix is properly set and retrieved"

	ollamaApi promptPrefix: 'test-prefix'.
	self assert: ollamaApi promptPrefix equals: 'test-prefix'
]

{ #category : 'tests' }
OllamaAPITest >> testSystem [
	"Test that the system is properly set and retrieved"

	ollamaApi system: 'test-system'.
	self assert: ollamaApi system equals: 'test-system'
]
