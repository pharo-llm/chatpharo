"
I am the **user and work memory (long-term)**: who the user is, their
preferences, the corrections they gave and the decisions of past conversations.

The profile comes from `ChatPharoSettings`; the memories relevant to the current
question come from `ChatPharoMemory`.
"
Class {
	#name : 'ChatPharoMemoryLayer',
	#superclass : 'ChatPharoContextLayer',
	#category : 'AI-ChatPharo-Context',
	#package : 'AI-ChatPharo-Context'
}

{ #category : 'testing' }
ChatPharoMemoryLayer >> isEnabled [

	^ self settings memoryEnabled
]

{ #category : 'accessing' }
ChatPharoMemoryLayer >> linesFor: aQueryString [

	^ self profileLines , (self memoryLinesFor: aQueryString)
]

{ #category : 'private' }
ChatPharoMemoryLayer >> memoryLinesFor: aQueryString [

	^ (ChatPharoMemory default contextForQuery: aQueryString) lines reject: [ :each | each trimBoth isEmpty ]
]

{ #category : 'private' }
ChatPharoMemoryLayer >> profileLines [

	^ Array streamContents: [ :stream |
		  self settings userName ifNotEmpty: [ :name | stream nextPut: '- User name: ' , name ].
		  self settings userOrganization ifNotEmpty: [ :organization |
			  stream nextPut: '- Organization: ' , organization ].
		  stream nextPut: '- Pharo experience: ' , self settings userLevelDisplayName ]
]

{ #category : 'accessing' }
ChatPharoMemoryLayer >> title [

	^ 'User and work memory (long-term)'
]
