Class {
	#name : 'ChatPharoToolRetryTest',
	#superclass : 'TestCase',
	#instVars : [
		'tool'
	],
	#category : 'AI-ChatPharo-Tests-Tools',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Tools'
}

{ #category : 'running' }
ChatPharoToolRetryTest >> setUp [

	super setUp.
	tool := ChatPharoTool basicNew
]

{ #category : 'running' }
ChatPharoToolRetryTest >> testExponentialBackoffSchedule [

	self assert: (tool retryDelaySecondsForAttempt: 1) equals: 1.
	self assert: (tool retryDelaySecondsForAttempt: 2) equals: 2.
	self assert: (tool retryDelaySecondsForAttempt: 3) equals: 4
]

{ #category : 'running' }
ChatPharoToolRetryTest >> testIsRetryableStatusFalseForSuccessAndClientErrors [

	self deny: (tool isRetryableStatus: 200).
	self deny: (tool isRetryableStatus: 201).
	self deny: (tool isRetryableStatus: 301).
	self deny: (tool isRetryableStatus: 400).
	self deny: (tool isRetryableStatus: 401).
	self deny: (tool isRetryableStatus: 403).
	self deny: (tool isRetryableStatus: 404).
	self deny: (tool isRetryableStatus: nil)
]

{ #category : 'running' }
ChatPharoToolRetryTest >> testIsRetryableStatusTrueForTransientCodes [

	self assert: (tool isRetryableStatus: 408).
	self assert: (tool isRetryableStatus: 429).
	self assert: (tool isRetryableStatus: 500).
	self assert: (tool isRetryableStatus: 502).
	self assert: (tool isRetryableStatus: 503).
	self assert: (tool isRetryableStatus: 504)
]

{ #category : 'running' }
ChatPharoToolRetryTest >> testMaxRetriesIsThree [

	self assert: tool maxRetries equals: 3
]

{ #category : 'running' }
ChatPharoToolRetryTest >> testNotifyRetryAttemptInvokesCallback [

	| recordedAttempt recordedMax |
	recordedAttempt := nil.
	recordedMax := nil.
	tool onRetry: [ :attempt :max |
		recordedAttempt := attempt.
		recordedMax := max ].
	tool notifyRetryAttempt: 2 of: 3.
	self assert: recordedAttempt equals: 2.
	self assert: recordedMax equals: 3
]

{ #category : 'running' }
ChatPharoToolRetryTest >> testNotifyRetryAttemptSafeWithoutCallback [

	"Must not raise when no callback is registered."
	tool notifyRetryAttempt: 1 of: 3
]

{ #category : 'running' }
ChatPharoToolRetryTest >> testPostEntityExhaustedOn5xxReturnsLastResponse [

	| client fastTool attempts final |
	attempts := OrderedCollection new.
	client := ChatPharoToolRetryStubClient new
		          outcomes: #( 500 500 500 500 );
		          yourself.
	fastTool := ChatPharoToolNoDelayDouble basicNew.
	fastTool onRetry: [ :a :m | attempts add: a -> m ].
	final := fastTool postEntity: nil withClient: client.
	self assert: final status equals: 500.
	self assert: client postCount equals: 4.
	self assert: attempts size equals: 3.
	self
		assert: (attempts collect: [ :p | p key ]) asArray
		equals: #( 1 2 3 )
]

{ #category : 'running' }
ChatPharoToolRetryTest >> testPostEntityExhaustedOnNetworkErrorRaises [

	| client fastTool |
	client := ChatPharoToolRetryStubClient new
		          outcomes: #( #networkError #networkError #networkError #networkError );
		          yourself.
	fastTool := ChatPharoToolNoDelayDouble basicNew.
	self
		should: [ fastTool postEntity: nil withClient: client ]
		raise: NetworkError
]

{ #category : 'running' }
ChatPharoToolRetryTest >> testPostEntityNoRetryOnNonRetryableStatus [

	| client fastTool attempts final |
	attempts := OrderedCollection new.
	client := ChatPharoToolRetryStubClient new
		          outcomes: #( 401 );
		          yourself.
	fastTool := ChatPharoToolNoDelayDouble basicNew.
	fastTool onRetry: [ :a :m | attempts add: a ].
	final := fastTool postEntity: nil withClient: client.
	self assert: final status equals: 401.
	self assert: client postCount equals: 1.
	self assert: attempts isEmpty
]

{ #category : 'running' }
ChatPharoToolRetryTest >> testPostEntityRecoversFromNetworkError [

	| client fastTool attempts final |
	attempts := OrderedCollection new.
	client := ChatPharoToolRetryStubClient new
		          outcomes: #( #networkError 200 );
		          yourself.
	fastTool := ChatPharoToolNoDelayDouble basicNew.
	fastTool onRetry: [ :a :m | attempts add: a ].
	final := fastTool postEntity: nil withClient: client.
	self assert: final status equals: 200.
	self assert: attempts asArray equals: #( 1 )
]

{ #category : 'running' }
ChatPharoToolRetryTest >> testPostEntityRetriesTransientThenSucceeds [

	| client fastTool attempts final |
	attempts := OrderedCollection new.
	client := ChatPharoToolRetryStubClient new
		          outcomes: #( 503 429 200 );
		          yourself.
	fastTool := ChatPharoToolNoDelayDouble basicNew.
	fastTool onRetry: [ :a :m | attempts add: a -> m ].
	final := fastTool postEntity: nil withClient: client.
	self assert: final status equals: 200.
	self assert: client postCount equals: 3.
	self assert: attempts size equals: 2.
	self assert: attempts first key equals: 1.
	self assert: attempts first value equals: 3.
	self assert: attempts last key equals: 2
]
