"
I am a real `ChatPharoAgent` whose backend is a `ChatPharoScriptedCompletionClient`,
so tests run the production conversation loop without a network.
"
Class {
	#name : 'ChatPharoScriptedAgent',
	#superclass : 'ChatPharoAgent',
	#instVars : [
		'client'
	],
	#category : 'AI-ChatPharo-Tests-Mock',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Mock'
}

{ #category : 'instance creation' }
ChatPharoScriptedAgent class >> answering: replies [

	^ self new
		  client: (ChatPharoScriptedCompletionClient answering: replies);
		  model: 'primary';
		  yourself
]

{ #category : 'api' }
ChatPharoScriptedAgent class >> displayName [

	^ 'Scripted'
]

{ #category : 'api' }
ChatPharoScriptedAgent class >> isReachable [

	^ true
]

{ #category : 'api' }
ChatPharoScriptedAgent class >> modelNames [

	^ #( 'primary' 'backup' )
]

{ #category : 'accessing' }
ChatPharoScriptedAgent >> client [

	^ client
]

{ #category : 'accessing' }
ChatPharoScriptedAgent >> client: aScriptedClient [

	client := aScriptedClient
]

{ #category : 'private - conversation' }
ChatPharoScriptedAgent >> newCompletionClient [

	^ client
]

{ #category : 'tools support' }
ChatPharoScriptedAgent >> tools [

	^ #(  )
]
