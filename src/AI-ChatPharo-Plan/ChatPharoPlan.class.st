"
I am a plan the model proposed for a request: a title and ordered
`ChatPharoPlanStep`s, plus what the user said when reviewing it.

The model proposes me with the `propose_plan` tool, the user validates each
step, and the model then executes the approved steps only, reporting progress.
`ChatPharoPlanBoard` keeps me so the Task Manager can show where every plan
stands.

```smalltalk
ChatPharoPlan title: 'Add logging' steps: #( 'Create Logger class' 'Call it from Foo>>bar' )
```
"
Class {
	#name : 'ChatPharoPlan',
	#superclass : 'Object',
	#instVars : [
		'id',
		'title',
		'steps',
		'feedback'
	],
	#category : 'AI-ChatPharo-Plan',
	#package : 'AI-ChatPharo-Plan'
}

{ #category : 'instance creation' }
ChatPharoPlan class >> title: aString steps: descriptions [

	^ self new
		  setTitle: aString steps: (descriptions collect: [ :each | ChatPharoPlanStep description: each ]);
		  yourself
]

{ #category : 'validation' }
ChatPharoPlan >> approveAll [

	steps do: [ :each | each approve ]
]

{ #category : 'accessing' }
ChatPharoPlan >> approvedSteps [

	^ steps select: [ :each | each isApproved ]
]

{ #category : 'converting' }
ChatPharoPlan >> asDictionary [
	"What the model reads back after a review or a progress update."

	^ Dictionary new
		  at: 'plan_id' put: id;
		  at: 'title' put: title;
		  at: 'user_feedback' put: feedback;
		  at: 'steps' put: (steps withIndexCollect: [ :each :index | each asDictionaryAt: index ]) asArray;
		  at: 'instruction' put: self instruction;
		  yourself
]

{ #category : 'accessing' }
ChatPharoPlan >> feedback [

	^ feedback
]

{ #category : 'accessing' }
ChatPharoPlan >> feedback: aString [

	feedback := aString
]

{ #category : 'accessing' }
ChatPharoPlan >> id [

	^ id
]

{ #category : 'accessing' }
ChatPharoPlan >> id: aString [

	id := aString
]

{ #category : 'initialization' }
ChatPharoPlan >> initialize [

	super initialize.
	steps := OrderedCollection new.
	feedback := ''
]

{ #category : 'converting' }
ChatPharoPlan >> instruction [

	self approvedSteps ifEmpty: [
		^ 'The user rejected this plan. Do not execute any of it. Read user_feedback, then propose a revised plan or ask the user what they want.' ].
	^ 'Execute only the approved steps, in order. Call update_plan_step with status "in_progress" before each step and "done" or "failed" after it. Never execute a rejected step; take user_feedback into account.'
]

{ #category : 'testing' }
ChatPharoPlan >> isFinished [

	^ steps allSatisfy: [ :each | each isFinished ]
]

{ #category : 'accessing' }
ChatPharoPlan >> progressLabel [

	^ '{1}/{2} done' format: {
			  (steps count: [ :each | each status = #done ]).
			  steps size }
]

{ #category : 'validation' }
ChatPharoPlan >> rejectAll [

	steps do: [ :each | each reject ]
]

{ #category : 'validation' }
ChatPharoPlan >> rejectUnvalidatedSteps [
	"A step the user did not explicitly approve is not approved."

	steps reject: [ :each | each isApproved ] thenDo: [ :each | each reject ]
]

{ #category : 'initialization' }
ChatPharoPlan >> setTitle: aString steps: aCollection [

	title := aString.
	steps := aCollection asOrderedCollection
]

{ #category : 'accessing' }
ChatPharoPlan >> stepAt: anIndex ifAbsent: aBlock [

	^ steps at: anIndex ifAbsent: aBlock
]

{ #category : 'accessing' }
ChatPharoPlan >> steps [

	^ steps
]

{ #category : 'accessing' }
ChatPharoPlan >> title [

	^ title
]
