Class {
	#name : 'ChatPharoRetryHandlerTest',
	#superclass : 'TestCase',
	#category : 'AI-ChatPharo-Tests-History',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'History'
}

{ #category : 'tests' }
ChatPharoRetryHandlerTest >> testCalculateDelayForAttempt [

	| handler |
	handler := ChatPharoRetryHandler new
		           baseDelay: 2;
		           maxDelay: 30;
		           yourself.
	self assert: (handler calculateDelayForAttempt: 1) equals: 2.
	self assert: (handler calculateDelayForAttempt: 2) equals: 4.
	self assert: (handler calculateDelayForAttempt: 3) equals: 8.
	self assert: (handler calculateDelayForAttempt: 4) equals: 16.
	self assert: (handler calculateDelayForAttempt: 5) equals: 30.
	self assert: (handler calculateDelayForAttempt: 6) equals: 30
]

{ #category : 'tests' }
ChatPharoRetryHandlerTest >> testExecuteWithRetryEventualSuccess [

	| handler attemptCount result |
	attemptCount := 0.
	handler := ChatPharoRetryHandler new maxAttempts: 3.
	result := handler executeWithRetry: [
		          attemptCount := attemptCount + 1.
		          attemptCount < 3
			          ifTrue: [ Error signal: 'Connection timeout' ]
			          ifFalse: [ 'Success' ] ].
	self assert: result equals: 'Success'.
	self assert: attemptCount equals: 3
]

{ #category : 'tests' }
ChatPharoRetryHandlerTest >> testExecuteWithRetryImmediateSuccess [

	| handler result |
	handler := ChatPharoRetryHandler new.
	result := handler executeWithRetry: [ 'Success' ].
	self assert: result equals: 'Success'
]

{ #category : 'tests' }
ChatPharoRetryHandlerTest >> testExecuteWithRetryMaxAttemptsExhausted [

	| handler attemptCount |
	attemptCount := 0.
	handler := ChatPharoRetryHandler new maxAttempts: 3.
	self
		should: [
			handler executeWithRetry: [
				attemptCount := attemptCount + 1.
				Error signal: 'Connection timeout' ] ]
		raise: Error.
	self assert: attemptCount equals: 3
]

{ #category : 'tests' }
ChatPharoRetryHandlerTest >> testExecuteWithRetryNonRetryableError [

	| handler attemptCount |
	attemptCount := 0.
	handler := ChatPharoRetryHandler new maxAttempts: 3.
	self
		should: [
			handler executeWithRetry: [
				attemptCount := attemptCount + 1.
				Error signal: 'Authentication failed' ] ]
		raise: Error.
	self assert: attemptCount equals: 1
]

{ #category : 'tests' }
ChatPharoRetryHandlerTest >> testMaxAttemptsConfiguration [

	| handler |
	handler := ChatPharoRetryHandler new.
	self assert: handler maxAttempts equals: 3.
	handler maxAttempts: 5.
	self assert: handler maxAttempts equals: 5.
	handler maxAttempts: 0.
	self assert: handler maxAttempts equals: 1
]

{ #category : 'tests' }
ChatPharoRetryHandlerTest >> testOnRetryAttemptCallback [

	| handler callbackInvoked lastAttempt lastMax |
	callbackInvoked := false.
	handler := ChatPharoRetryHandler new
		           maxAttempts: 3;
		           onRetryAttempt: [ :attempt :max |
			           callbackInvoked := true.
			           lastAttempt := attempt.
			           lastMax := max ];
		           yourself.
	self
		should: [
			handler executeWithRetry: [ Error signal: 'Connection timeout' ] ]
		raise: Error.
	self assert: callbackInvoked.
	self assert: lastAttempt equals: 3.
	self assert: lastMax equals: 3
]
