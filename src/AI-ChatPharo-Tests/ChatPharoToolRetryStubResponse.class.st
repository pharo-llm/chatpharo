Class {
	#name : 'ChatPharoToolRetryStubResponse',
	#superclass : 'Object',
	#instVars : [
		'status'
	],
	#category : 'AI-ChatPharo-Tests-Mock',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Mock'
}

{ #category : 'testing' }
ChatPharoToolRetryStubResponse >> isSuccess [

	status ifNil: [ ^ false ].
	^ status >= 200 and: [ status < 300 ]
]

{ #category : 'testing' }
ChatPharoToolRetryStubResponse >> status [

	^ status
]

{ #category : 'testing' }
ChatPharoToolRetryStubResponse >> status: anInteger [

	status := anInteger
]
