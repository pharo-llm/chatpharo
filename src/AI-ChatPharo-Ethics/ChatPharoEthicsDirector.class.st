"
Configuration for ChatPharo's ethics director controls.

Stores the ethics mandate and budget limits that influence how ChatPharo
should operate in terms of safety and cognitive load.
"
Class {
	#name : 'ChatPharoEthicsDirector',
	#superclass : 'Object',
	#instVars : [
		'enabled',
		'mandate',
		'cognitiveLoadBudget',
		'tokenBudget',
		'timeBudgetMinutes',
		'messageLimit',
		'requestTimeoutSeconds'
	],
	#category : 'AI-ChatPharo-Ethics',
	#package : 'AI-ChatPharo-Ethics'
}

{ #category : 'accessing' }
ChatPharoEthicsDirector >> cognitiveLoadBudget [

	^ cognitiveLoadBudget ifNil: [ cognitiveLoadBudget := 120 ]
]

{ #category : 'accessing' }
ChatPharoEthicsDirector >> cognitiveLoadBudget: aNumber [

	cognitiveLoadBudget := aNumber.
	ChatPharoLogger logFrontend: 'Cognitive load budget updated'
		details: (Dictionary new
			at: 'value' put: (aNumber ifNil: [ 'unset' ] ifNotNil: [ aNumber ]);
			yourself)
]

{ #category : 'accessing' }
ChatPharoEthicsDirector >> enabled [

	^ enabled ifNil: [ enabled := true ]
]

{ #category : 'accessing' }
ChatPharoEthicsDirector >> enabled: aBoolean [

	enabled := aBoolean.
	ChatPharoLogger logFrontend: 'Ethics director toggled'
		details: (Dictionary new
			at: 'enabled' put: aBoolean;
			yourself)
]

{ #category : 'initialization' }
ChatPharoEthicsDirector >> initialize [

	super initialize.
	enabled := true.
	mandate := ''.
	cognitiveLoadBudget := 120.
	tokenBudget := 4096.
	timeBudgetMinutes := 30.
	messageLimit := 50.
	requestTimeoutSeconds := 300
]

{ #category : 'accessing' }
ChatPharoEthicsDirector >> mandate [

	^ mandate ifNil: [ mandate := '' ]
]

{ #category : 'accessing' }
ChatPharoEthicsDirector >> mandate: aString [

	mandate := aString.
	ChatPharoLogger logFrontend: 'Ethics mandate updated'
		details: (Dictionary new
			at: 'length' put: aString size;
			yourself)
]

{ #category : 'initialization' }
ChatPharoEthicsDirector >> messageLimit [

	^ messageLimit ifNil: [ messageLimit := 50 ]
]

{ #category : 'initialization' }
ChatPharoEthicsDirector >> messageLimit: aNumber [

	(aNumber notNil and: [ aNumber isNumber and: [ aNumber < 1 ] ]) ifTrue: [
		ChatPharoLogger logFrontend: 'Message limit rejected (must be >= 1)'
			details: (Dictionary new
				at: 'attempted' put: aNumber;
				yourself).
		^ self error: 'Message limit must be at least 1. You have no right to set it to ' , aNumber asString , '.' ].
	
	messageLimit := aNumber.
	ChatPharoLogger logFrontend: 'Message limit updated'
		details: (Dictionary new
			at: 'limit' put: (aNumber ifNil: [ 'unset' ] ifNotNil: [ aNumber ]);
			yourself)
]

{ #category : 'initialization' }
ChatPharoEthicsDirector >> requestTimeoutSeconds [

	^ requestTimeoutSeconds ifNil: [ requestTimeoutSeconds := 300 ]
]

{ #category : 'initialization' }
ChatPharoEthicsDirector >> requestTimeoutSeconds: anInteger [

	requestTimeoutSeconds := anInteger.
	ChatPharoLogger logFrontend: 'Request timeout updated'
		details: (Dictionary new
			at: 'seconds' put: (anInteger ifNil: [ 'unset' ] ifNotNil: [ anInteger ]);
			yourself)
]

{ #category : 'accessing' }
ChatPharoEthicsDirector >> timeBudgetMinutes [

	^ timeBudgetMinutes ifNil: [ timeBudgetMinutes := 30 ]
]

{ #category : 'accessing' }
ChatPharoEthicsDirector >> timeBudgetMinutes: aNumber [

	timeBudgetMinutes := aNumber.
	ChatPharoLogger logFrontend: 'Time budget updated'
		details: (Dictionary new
			at: 'minutes' put: (aNumber ifNil: [ 'unset' ] ifNotNil: [ aNumber ]);
			yourself)
]

{ #category : 'accessing' }
ChatPharoEthicsDirector >> tokenBudget [

	^ tokenBudget ifNil: [ tokenBudget := 4096 ]
]

{ #category : 'accessing' }
ChatPharoEthicsDirector >> tokenBudget: aNumber [

	tokenBudget := aNumber.
	ChatPharoLogger logFrontend: 'Token budget updated'
		details: (Dictionary new
			at: 'tokens' put: (aNumber ifNil: [ 'unset' ] ifNotNil: [ aNumber ]);
			yourself)
]
