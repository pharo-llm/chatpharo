"
Handles **automatic retry logic** for API calls that fail due to network issues or provider disconnections.

* Implements exponential backoff with configurable max attempts
* Logs each retry attempt for debugging
* Distinguishes between retryable errors (network, timeout) and non-retryable errors (auth, validation)
* **Why** – ensures robust handling of temporary provider disconnections during long-running tasks

```smalltalk
ChatPharoRetryHandler new
	maxAttempts: 3;
	executeWithRetry: [ api getResponseForPrompt: 'Hello' ]
```
"
Class {
	#name : 'ChatPharoRetryHandler',
	#superclass : 'Object',
	#instVars : [
		'maxAttempts',
		'baseDelay',
		'maxDelay',
		'onRetryAttempt'
	],
	#category : 'AI-ChatPharo',
	#package : 'AI-ChatPharo'
}

{ #category : 'accessing' }
ChatPharoRetryHandler >> baseDelay [
	
	^ baseDelay
]

{ #category : 'accessing' }
ChatPharoRetryHandler >> baseDelay: aNumber [ 
	"Set base delay in seconds before first retry"
	
	baseDelay := aNumber
]

{ #category : 'accessing' }
ChatPharoRetryHandler >> calculateDelayForAttempt: attemptNumber [
	
	| delay |
	delay := baseDelay * (2 raisedTo: attemptNumber - 1).
	^ delay min: maxDelay
]

{ #category : 'executing' }
ChatPharoRetryHandler >> executeWithRetry: aBlock [

	
	| attempt lastError |
	attempt := 1.
	
	[ attempt <= maxAttempts ] whileTrue: [
		[
			| result |
			attempt > 1 ifTrue: [
				ChatPharoLogger logBackend: 'Retry attempt' details: (Dictionary new
					at: 'attempt' put: attempt;
					at: 'maxAttempts' put: maxAttempts;
					yourself).
				onRetryAttempt ifNotNil: [ :blk | blk cull: attempt cull: maxAttempts ] ].
			
			result := aBlock value.
			
			"Success - log if this was a retry"
			attempt > 1 ifTrue: [
				ChatPharoLogger logBackend: 'Retry succeeded' details: (Dictionary new
					at: 'successfulAttempt' put: attempt;
					at: 'totalAttempts' put: maxAttempts;
					yourself) ].
			
			^ result
		] on: Error do: [ :ex |
			lastError := ex.
			
			"Check if this is a retryable error"
			(self isRetryableError: ex) ifFalse: [
				"Non-retryable error - fail immediately"
				ChatPharoLogger logBackend: 'Non-retryable error encountered' details: (Dictionary new
					at: 'error' put: ex messageText;
					at: 'errorClass' put: ex class name;
					yourself).
				ex signal ].
			
			"Log the retry attempt"
			ChatPharoLogger logBackend: 'Retryable error encountered' details: (Dictionary new
				at: 'attempt' put: attempt;
				at: 'maxAttempts' put: maxAttempts;
				at: 'error' put: ex messageText;
				at: 'errorClass' put: ex class name;
				yourself).
			
			"If this was the last attempt, signal the error"
			attempt >= maxAttempts ifTrue: [
				ChatPharoLogger logBackend: 'All retry attempts exhausted' details: (Dictionary new
					at: 'totalAttempts' put: maxAttempts;
					at: 'finalError' put: ex messageText;
					yourself).
				ex signal ].
			
			"Wait before retrying (exponential backoff)"
			self waitBeforeRetry: attempt.
			
			attempt := attempt + 1 ] ].
	
	"Should never reach here, but signal last error just in case"
	lastError signal
]

{ #category : 'accessing' }
ChatPharoRetryHandler >> initialize [

	super initialize.
	maxAttempts := 3.
	baseDelay := 2.  "2 seconds"
	maxDelay := 30.  "30 seconds max"
	onRetryAttempt := nil
]

{ #category : 'private' }
ChatPharoRetryHandler >> isRetryableError: anError [
	
	| errorClass errorMessage |
	errorClass := anError class name asString.
	errorMessage := anError messageText asLowercase.
	
	"Network-related errors are retryable"
	(errorClass includesSubstring: 'Network') ifTrue: [ ^ true ].
	(errorClass includesSubstring: 'Timeout') ifTrue: [ ^ true ].
	(errorClass includesSubstring: 'ConnectionClosed') ifTrue: [ ^ true ].
	(errorClass includesSubstring: 'ConnectionFailed') ifTrue: [ ^ true ].
	
	"Check for ZnHttpUnsuccessful - only 5xx errors are retryable"
	(errorClass includesSubstring: 'ZnHttpUnsuccessful') ifTrue: [
		"5xx server errors are retryable, 4xx client errors are not"
		(errorMessage includesSubstring: '5') ifTrue: [ ^ true ].
		(errorMessage includesSubstring: 'server') ifTrue: [ ^ true ].
		^ false ].
	
	"Check error message for common retryable patterns"
	(errorMessage includesSubstring: 'connection') ifTrue: [ ^ true ].
	(errorMessage includesSubstring: 'timeout') ifTrue: [ ^ true ].
	(errorMessage includesSubstring: 'disconnected') ifTrue: [ ^ true ].
	(errorMessage includesSubstring: 'unavailable') ifTrue: [ ^ true ].
	(errorMessage includesSubstring: 'overloaded') ifTrue: [ ^ true ].
	(errorMessage includesSubstring: 'rate limit') ifTrue: [ ^ true ].
	
	"Check for wrapped HTTP 5xx server errors (ChatPharoTool wraps these as generic Error)"
	(errorMessage includesSubstring: 'chat completion: 5') ifTrue: [ ^ true ].
	
	"Check for non-retryable patterns"
	(errorMessage includesSubstring: 'authentication') ifTrue: [ ^ false ].
	(errorMessage includesSubstring: 'unauthorized') ifTrue: [ ^ false ].
	(errorMessage includesSubstring: 'forbidden') ifTrue: [ ^ false ].
	(errorMessage includesSubstring: 'invalid') ifTrue: [ ^ false ].
	(errorMessage includesSubstring: 'api key') ifTrue: [ ^ false ].
	
	"Default: treat unknown errors as non-retryable to avoid infinite loops"
	^ false
]

{ #category : 'accessing' }
ChatPharoRetryHandler >> maxAttempts [
	"Maximum number of attempts (including the initial attempt)"
	
	^ maxAttempts
]

{ #category : 'accessing' }
ChatPharoRetryHandler >> maxAttempts: anInteger [
	
	maxAttempts := anInteger max: 1
]

{ #category : 'accessing' }
ChatPharoRetryHandler >> maxDelay [
	
	^ maxDelay
]

{ #category : 'accessing' }
ChatPharoRetryHandler >> maxDelay: aNumber [
	
	maxDelay := aNumber
]

{ #category : 'accessing' }
ChatPharoRetryHandler >> onRetryAttempt: aBlock [
	
	onRetryAttempt := aBlock
]

{ #category : 'private' }
ChatPharoRetryHandler >> waitBeforeRetry: attemptNumber [
	
	| delaySeconds |
	delaySeconds := self calculateDelayForAttempt: attemptNumber.
	
	ChatPharoLogger logBackend: 'Waiting before retry' details: (Dictionary new
		at: 'delaySeconds' put: delaySeconds;
		at: 'attempt' put: attemptNumber;
		yourself).
	
	(Delay forSeconds: delaySeconds) wait
]
