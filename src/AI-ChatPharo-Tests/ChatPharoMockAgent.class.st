"
a mock class
"
Class {
	#name : 'ChatPharoMockAgent',
	#superclass : 'Object',
	#instVars : [
		'conversationHistory',
		'currentModel'
	],
	#category : 'AI-ChatPharo-Tests-Mock',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Mock'
}

{ #category : 'api' }
ChatPharoMockAgent class >> modelNames [
	^ #('mock-default' 'mock-advanced')
]

{ #category : 'private - uffi' }
ChatPharoMockAgent >> getResponseForPrompt: aPromptString [

	conversationHistory addLast: { (#userPrompt -> aPromptString) }.
	^ '<<' , currentModel asUppercase , '-REPLY to: ' , aPromptString
	  , '>>'
]

{ #category : 'private - uffi' }
ChatPharoMockAgent >> history [ 

        ^ conversationHistory
]

{ #category : 'private - uffi' }
ChatPharoMockAgent >> history: aHistory [ 

        "ignore history"
]

{ #category : 'initialization' }
ChatPharoMockAgent >> initialize [
	super initialize.
	conversationHistory := OrderedCollection new.
	currentModel := 'mock-default'.
]

{ #category : 'initialization' }
ChatPharoMockAgent >> model [

        ^ currentModel
]

{ #category : 'initialization' }
ChatPharoMockAgent >> model: aString [
	currentModel := aString.
]

{ #category : 'private - ffi' }
ChatPharoMockAgent >> onToolExecution [ 

        ^ nil
]

{ #category : 'private - ffi' }
ChatPharoMockAgent >> onToolExecution: aBlock [ 

        "ignore tool execution callbacks"
]

{ #category : 'private - uffi' }
ChatPharoMockAgent >> promptPrefix [ 

        ^ ''
]

{ #category : 'private - uffi' }
ChatPharoMockAgent >> promptPrefix: aString [ 

        "ignored for tests"
]

{ #category : 'tools support' }
ChatPharoMockAgent >> supportsToolCalling [
	"Mock agent supports tool calling for testing purposes."

	^ true
]

{ #category : 'private - uffi' }
ChatPharoMockAgent >> system: aSystemPrompt [

	conversationHistory addLast: { (#systemPrompt -> aSystemPrompt) }.
	^ self
]

{ #category : 'accessing' }
ChatPharoMockAgent >> systemPrompt [ 

        ^ ''
]

{ #category : 'private - uffi' }
ChatPharoMockAgent >> systemPrompt: aString [ 
        "No-op for the mock agent. Real agents store systemPrompt as an ivar
	 without touching conversationHistory; forwarding to #system: would
	 inflate history counts used by tests to tally backend calls."
]
