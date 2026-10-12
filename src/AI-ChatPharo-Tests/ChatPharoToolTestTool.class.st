Class {
	#name : 'ChatPharoToolTestTool',
	#superclass : 'Object',
	#instVars : [
		'shouldError'
	],
	#category : 'AI-ChatPharo-Tests-Mock',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Mock'
}

{ #category : 'accessing' }
ChatPharoToolTestTool >> applyTo: args [ 

    shouldError ifTrue: [ Error signal: 'boom' ].
    ^ Dictionary with: 'ok' -> true
]

{ #category : 'accessing' }
ChatPharoToolTestTool >> initialize [ 

    super initialize.
    shouldError := false.
]

{ #category : 'accessing' }
ChatPharoToolTestTool >> name [ 
    ^ 'testTool'

]

{ #category : 'accessing' }
ChatPharoToolTestTool >> shouldError: aBoolean [ 

    shouldError := aBoolean
]

{ #category : 'testing' }
ChatPharoToolTestTool >> isMutating [

	^ false
]
