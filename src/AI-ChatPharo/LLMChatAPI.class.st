"
I am the abstract superclass for all language model API integrations in ChatPharo.

I define common behavior and structure for different LLM API implementations like OpenAI and Ollama.
Subclasses should implement the following methods:
- getResponseForHistory: - to get responses from the LLM
- modelNames - to get the available model names

My subclasses include:
- OllamaAPI: Integration with Ollama local LLMs
- OpenAIChatAPI: Integration with OpenAI and compatible services
"
Class {
	#name : 'LLMChatAPI',
	#superclass : 'Object',
	#instVars : [
		'model',
		'system',
		'tools'
	],
	#category : 'AI-ChatPharo-API',
	#package : 'AI-ChatPharo',
	#tag : 'API'
}

{ #category : 'accessing' }
LLMChatAPI >> getResponseForHistory: history [
	"Gets a response from the language model for the given history.
	This method must be implemented by subclasses."
	
	self subclassResponsibility
]

{ #category : 'initialization' }
LLMChatAPI >> initialize [
	super initialize.
	system := ''.
	tools := nil.
]

{ #category : 'accessing' }
LLMChatAPI >> model [
	^ model
]

{ #category : 'accessing' }
LLMChatAPI >> model: anObject [
	model := anObject
]

{ #category : 'accessing' }
LLMChatAPI >> modelNames [
	"Return the available model names.
	This method must be implemented by subclasses."
	
	self subclassResponsibility
]

{ #category : 'accessing' }
LLMChatAPI >> system [
	^ system
]

{ #category : 'accessing' }
LLMChatAPI >> system: anObject [
	system := anObject
]

{ #category : 'accessing' }
LLMChatAPI >> tools [
	^ tools
]

{ #category : 'accessing' }
LLMChatAPI >> tools: anObject [
	tools := anObject
] 