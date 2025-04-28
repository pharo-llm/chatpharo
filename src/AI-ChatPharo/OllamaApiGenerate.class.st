Class {
	#name : 'OllamaApiGenerate',
	#superclass : 'OllamaAPI',
	#instVars : [
		'response'
	],
	#category : 'AI-ChatPharo-Ollama',
	#package : 'AI-ChatPharo',
	#tag : 'Ollama'
}

{ #category : 'instance creation' }
OllamaApiGenerate class >> new [
	"Create an instance that uses the native Ollama API for backward compatibility"
	^ self newWithNativeAPI
]

{ #category : 'initialization' }
OllamaApiGenerate >> initialize [
	super initialize.
	self useOpenAICompatibleAPI: false.
]

{ #category : 'api access' }
OllamaApiGenerate >> getResponseForPrompt: prompt [
	"Legacy method for backward compatibility with tests"
	
	response := self getResponseWithNativeAPIForPrompt: prompt.
	^ response
]

{ #category : 'accessing' }
OllamaApiGenerate >> response [
	^ response
]

{ #category : 'accessing' }
OllamaApiGenerate >> response: anObject [
	response := anObject
] 