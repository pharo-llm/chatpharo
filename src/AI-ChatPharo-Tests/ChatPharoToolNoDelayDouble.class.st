Class {
	#name : 'ChatPharoToolNoDelayDouble',
	#superclass : 'ChatPharoTool',
	#category : 'AI-ChatPharo-Tests-Mock',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Mock'
}

{ #category : 'accessing' }
ChatPharoToolNoDelayDouble >> entity: anEntity [

	^ self
]

{ #category : 'as yet unclassified' }
ChatPharoToolNoDelayDouble >> retryDelaySecondsForAttempt: attempt [

	^ 0
]
