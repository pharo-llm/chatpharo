"
I am one step of a `ChatPharoPlan`: what will be done, and where it stands.

My life cycle is

	proposed → approved → in progress → done | failed
	proposed → rejected

The user decides the first transition (approve or reject); the model reports
the others while it works. A step the user did not approve can never be
started: `start` answers false and leaves me untouched.
"
Class {
	#name : 'ChatPharoPlanStep',
	#superclass : 'Object',
	#instVars : [
		'description',
		'status',
		'note'
	],
	#category : 'AI-ChatPharo-Plan',
	#package : 'AI-ChatPharo-Plan'
}

{ #category : 'instance creation' }
ChatPharoPlanStep class >> description: aString [

	^ self new
		  setDescription: aString;
		  yourself
]

{ #category : 'accessing' }
ChatPharoPlanStep class >> statusLabels [

	^ Dictionary new
		  at: #proposed put: 'waiting for validation';
		  at: #approved put: 'approved';
		  at: #rejected put: 'rejected';
		  at: #inProgress put: 'in progress';
		  at: #done put: 'done';
		  at: #failed put: 'failed';
		  yourself
]

{ #category : 'validation' }
ChatPharoPlanStep >> approve [

	status := #approved
]

{ #category : 'converting' }
ChatPharoPlanStep >> asDictionaryAt: anIndex [

	^ Dictionary new
		  at: 'step' put: anIndex;
		  at: 'description' put: description;
		  at: 'status' put: self statusLabel;
		  at: 'note' put: note;
		  yourself
]

{ #category : 'progress' }
ChatPharoPlanStep >> complete: aNote [

	self wasApproved ifFalse: [ ^ false ].
	status := #done.
	note := aNote.
	^ true
]

{ #category : 'accessing' }
ChatPharoPlanStep >> description [

	^ description
]

{ #category : 'progress' }
ChatPharoPlanStep >> fail: aNote [

	self wasApproved ifFalse: [ ^ false ].
	status := #failed.
	note := aNote.
	^ true
]

{ #category : 'initialization' }
ChatPharoPlanStep >> initialize [

	super initialize.
	status := #proposed.
	note := ''
]

{ #category : 'testing' }
ChatPharoPlanStep >> isApproved [
	"Whether the user currently approves me, whatever progress was made since."

	^ self wasApproved
]

{ #category : 'testing' }
ChatPharoPlanStep >> isFinished [

	^ #( #rejected #done #failed ) includes: status
]

{ #category : 'testing' }
ChatPharoPlanStep >> isRejected [

	^ status = #rejected
]

{ #category : 'accessing' }
ChatPharoPlanStep >> note [

	^ note
]

{ #category : 'validation' }
ChatPharoPlanStep >> reject [

	status := #rejected
]

{ #category : 'initialization' }
ChatPharoPlanStep >> setDescription: aString [

	description := aString
]

{ #category : 'progress' }
ChatPharoPlanStep >> start [
	"Answer whether I may be worked on; only a step the user approved may."

	self wasApproved ifFalse: [ ^ false ].
	status := #inProgress.
	^ true
]

{ #category : 'accessing' }
ChatPharoPlanStep >> status [

	^ status
]

{ #category : 'accessing' }
ChatPharoPlanStep >> statusLabel [

	^ self class statusLabels at: status
]

{ #category : 'testing' }
ChatPharoPlanStep >> wasApproved [

	^ #( #approved #inProgress #done #failed ) includes: status
]
