"
I stand in for `ChatPharoTool` in tests: I answer the replies I was scripted
with, one per request, and remember what I was asked.

A scripted entry is either a reply (`ChatPharoHistorySaver`) or an exception to
signal, which lets tests exercise usage limits and failures without a network.
"
Class {
	#name : 'ChatPharoScriptedCompletionClient',
	#superclass : 'Object',
	#instVars : [
		'script',
		'requestCount',
		'closingRequestCount',
		'model',
		'requestedModels'
	],
	#category : 'AI-ChatPharo-Tests-Mock',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Mock'
}

{ #category : 'instance creation' }
ChatPharoScriptedCompletionClient class >> answering: replies [

	^ self new
		  script: replies;
		  yourself
]

{ #category : 'scripting' }
ChatPharoScriptedCompletionClient class >> reply: aString [

	^ (ChatPharoHistorySaver role: 'assistant' content: aString)
		  inputTokens: 10;
		  outputTokens: 5;
		  yourself
]

{ #category : 'scripting' }
ChatPharoScriptedCompletionClient class >> toolReplyThinking: aString [
	"A reply that asks for one tool call, as ChatPharoTool answers it after running the tool."

	^ (ChatPharoHistorySaver
		   role: 'assistant'
		   content: nil
		   toolCalls: { (ChatPharoHistorySaverToolCall
				    id: 'call-1'
				    functionName: 'get_packages'
				    arguments: '{}'
				    content: '{"packages":[]}') })
		  thinking: aString;
		  inputTokens: 10;
		  outputTokens: 5;
		  yourself
]

{ #category : 'accessing' }
ChatPharoScriptedCompletionClient >> closingRequestCount [

	^ closingRequestCount
]

{ #category : 'requests' }
ChatPharoScriptedCompletionClient >> getClosingResponseForHistory: aHistory [

	closingRequestCount := closingRequestCount + 1.
	^ self class reply: nil
]

{ #category : 'requests' }
ChatPharoScriptedCompletionClient >> getResponseForHistory: aHistory [

	requestCount := requestCount + 1.
	requestedModels add: model.
	^ script removeFirst value
]

{ #category : 'initialization' }
ChatPharoScriptedCompletionClient >> initialize [

	super initialize.
	script := OrderedCollection new.
	requestCount := 0.
	closingRequestCount := 0.
	requestedModels := OrderedCollection new
]

{ #category : 'accessing' }
ChatPharoScriptedCompletionClient >> model: aString [

	model := aString
]

{ #category : 'accessing' }
ChatPharoScriptedCompletionClient >> onToolExecution: aBlock [
	"Scripted replies already contain their tool results."
]

{ #category : 'accessing' }
ChatPharoScriptedCompletionClient >> requestCount [

	^ requestCount
]

{ #category : 'accessing' }
ChatPharoScriptedCompletionClient >> requestParameters: aDictionary [
	"Scripted replies do not depend on sampling parameters."
]

{ #category : 'accessing' }
ChatPharoScriptedCompletionClient >> requestedModels [

	^ requestedModels
]

{ #category : 'accessing' }
ChatPharoScriptedCompletionClient >> script: replies [
	"Each entry is evaluated when its turn comes: a reply answers itself, a block may signal."

	script := replies asOrderedCollection
]
