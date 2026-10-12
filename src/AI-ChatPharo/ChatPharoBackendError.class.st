"
I am signalled when an LLM backend refuses or fails a completion request.

I keep the HTTP status so callers can decide on a recovery policy without
parsing the human readable message:

- `isUsageLimit` — the account, key or model ran out of quota or is rate limited.
- `isMissingModel` — the requested model does not exist on that backend.
- `canFallBackToAnotherModel` — trying a different model has a chance to work.

`ChatPharoAgent` uses me to walk its list of fallback models, and
`ChatPharoRetryHandler` still sees me as a plain `Error`.
"
Class {
	#name : 'ChatPharoBackendError',
	#superclass : 'Error',
	#instVars : [
		'statusCode'
	],
	#category : 'AI-ChatPharo',
	#package : 'AI-ChatPharo'
}

{ #category : 'instance creation' }
ChatPharoBackendError class >> status: anInteger message: aString [

	^ self new
		  statusCode: anInteger;
		  messageText: aString;
		  yourself
]

{ #category : 'testing' }
ChatPharoBackendError >> canFallBackToAnotherModel [

	^ self isUsageLimit or: [ self isMissingModel ]
]

{ #category : 'testing' }
ChatPharoBackendError >> isMissingModel [

	^ statusCode = 404
]

{ #category : 'testing' }
ChatPharoBackendError >> isUsageLimit [

	^ (#( 402 429 ) includes: statusCode) or: [ self mentionsUsageLimit ]
]

{ #category : 'private' }
ChatPharoBackendError >> mentionsUsageLimit [

	| text |
	text := self messageText asLowercase.
	^ #( 'quota' 'rate limit' 'usage limit' 'insufficient balance' 'too many requests' ) anySatisfy: [ :each |
		  text includesSubstring: each ]
]

{ #category : 'accessing' }
ChatPharoBackendError >> statusCode [

	^ statusCode
]

{ #category : 'accessing' }
ChatPharoBackendError >> statusCode: anInteger [

	statusCode := anInteger
]
