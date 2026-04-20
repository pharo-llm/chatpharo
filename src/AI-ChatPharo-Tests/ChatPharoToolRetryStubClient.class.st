Class {
	#name : 'ChatPharoToolRetryStubClient',
	#superclass : 'ChatPharoTool',
	#instVars : [
		'outcomes',
		'postCount',
		'currentStatus'
	],
	#category : 'AI-ChatPharo-Tests-Mock',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Mock'
}

{ #category : 'accessing' }
ChatPharoToolRetryStubClient >> entity: anEntity [

	^ self
]

{ #category : 'accessing' }
ChatPharoToolRetryStubClient >> initialize [

	super initialize.
	outcomes := #().
	postCount := 0.
	currentStatus := nil
]

{ #category : 'accessing' }
ChatPharoToolRetryStubClient >> outcomes: aCollection [

	outcomes := aCollection asArray.
	postCount := 0
]

{ #category : 'accessing' }
ChatPharoToolRetryStubClient >> post [

	| outcome |
	postCount := postCount + 1.
	outcome := outcomes
		at: (postCount min: outcomes size)
		ifAbsent: [ 200 ].
	outcome = #networkError ifTrue: [
		currentStatus := nil.
		NetworkError signal: 'stub network error' ].
	currentStatus := outcome.
	^ self
]

{ #category : 'accessing' }
ChatPharoToolRetryStubClient >> postCount [

	^ postCount
]

{ #category : 'accessing' }
ChatPharoToolRetryStubClient >> resetEntity [

	^ self
]

{ #category : 'accessing' }
ChatPharoToolRetryStubClient >> response [

	^ ChatPharoToolRetryStubResponse new
		  status: currentStatus;
		  yourself
]

{ #category : 'accessing' }
ChatPharoToolRetryStubClient >> timeout: seconds [

	^ self
]
