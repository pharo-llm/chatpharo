"
I am the **session context (short-term)**: what the user is doing right now.

I report the window that has the focus, the other open windows, and the code
changes made in this session as recorded by Epicea. With me, ""fix this"" or
""why does it fail?"" has a referent the model can see.
"
Class {
	#name : 'ChatPharoSessionLayer',
	#superclass : 'ChatPharoContextLayer',
	#category : 'AI-ChatPharo-Context',
	#package : 'AI-ChatPharo-Context'
}

{ #category : 'private' }
ChatPharoSessionLayer >> changeLines [

	| changes |
	changes := self recentCodeChanges.
	changes ifEmpty: [ ^ #(  ) ].
	^ (OrderedCollection with: '- Latest code changes of this session, oldest first:')
		  addAll: (changes collect: [ :each | '  - ' , (self describeChange: each) ]);
		  yourself
]

{ #category : 'private' }
ChatPharoSessionLayer >> describeChange: anEpiceaEvent [
	"Epicea prints events as 'an EpMethodModification(Foo>>bar)'; drop the article."

	^ anEpiceaEvent printString copyAfter: Character space
]

{ #category : 'testing' }
ChatPharoSessionLayer >> isEnabled [

	^ self settings sessionContextEnabled
]

{ #category : 'accessing' }
ChatPharoSessionLayer >> linesFor: aQueryString [

	^ self windowLines , self changeLines
]

{ #category : 'accessing' }
ChatPharoSessionLayer >> maximumChanges [

	^ 12
]

{ #category : 'accessing' }
ChatPharoSessionLayer >> maximumWindows [

	^ 12
]

{ #category : 'private' }
ChatPharoSessionLayer >> openWindowLabels [

	^ self currentWorld systemWindows collect: [ :each | each label ]
]

{ #category : 'private' }
ChatPharoSessionLayer >> recentCodeChanges [

	| entries |
	entries := EpMonitor current log entries.
	^ (entries last: (self maximumChanges min: entries size))
		  collect: [ :each | each content ]
		  thenSelect: [ :each | each isCodeChange ]
]

{ #category : 'accessing' }
ChatPharoSessionLayer >> title [

	^ 'Session context (what the user is doing now)'
]

{ #category : 'private' }
ChatPharoSessionLayer >> windowLines [

	| labels |
	labels := self openWindowLabels.
	labels ifEmpty: [ ^ #(  ) ].
	^ (OrderedCollection with: '- Focused window: ' , labels first)
		  addAll: ((labels allButFirst first: (self maximumWindows min: labels size - 1)) collect: [ :each |
					   '- Other open window: ' , each ]);
		  yourself
]
