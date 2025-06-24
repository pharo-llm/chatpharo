Class {
	#name : 'ChatPharoZnClientReachabilityStub',
	#superclass : 'Object',
	#classVars : [
		'ShouldFail'
	],
	#classInstVars : [
		'ShouldFail'
	],
	#category : 'AI-ChatPharo-Tests-Mock',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Mock'
}

{ #category : 'instance creation' }
ChatPharoZnClientReachabilityStub class >> new [ 

	^ super new 
]

{ #category : 'instance creation' }
ChatPharoZnClientReachabilityStub class >> shouldFail [ 
		^ ShouldFail ifNil:[ false ] 
]

{ #category : 'instance creation' }
ChatPharoZnClientReachabilityStub class >> shouldFail: aBool [
	 ShouldFail := aBool 
]

{ #category : 'instance creation' }
ChatPharoZnClientReachabilityStub >> get: url [ 

    self class shouldFail ifTrue: [ NetworkError signal: 'fail' ].
    ^ self
]

{ #category : 'instance creation' }
ChatPharoZnClientReachabilityStub >> head: url [ 

    self class shouldFail ifTrue: [ NetworkError signal: 'fail' ].
    ^ self
]
