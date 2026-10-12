"
I play the user reviewing a plan in tests: I approve the steps whose positions
I was given, reject the others (or leave them undecided), and leave feedback.
"
Class {
	#name : 'ChatPharoPlanTestReviewer',
	#superclass : 'Object',
	#instVars : [
		'approvedIndexes',
		'feedback',
		'rejectsOthers'
	],
	#category : 'AI-ChatPharo-Tests-Mock',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Mock'
}

{ #category : 'accessing' }
ChatPharoPlanTestReviewer >> approvedIndexes: aCollection [

	approvedIndexes := aCollection
]

{ #category : 'accessing' }
ChatPharoPlanTestReviewer >> feedback: aString [

	feedback := aString
]

{ #category : 'initialization' }
ChatPharoPlanTestReviewer >> initialize [

	super initialize.
	approvedIndexes := #(  ).
	feedback := ''.
	rejectsOthers := true
]

{ #category : 'accessing' }
ChatPharoPlanTestReviewer >> leaveOthersUndecided [

	rejectsOthers := false
]

{ #category : 'reviewing' }
ChatPharoPlanTestReviewer >> review: aPlan [

	aPlan steps doWithIndex: [ :each :index |
		(approvedIndexes includes: index)
			ifTrue: [ each approve ]
			ifFalse: [ rejectsOthers ifTrue: [ each reject ] ] ].
	aPlan feedback: feedback
]
