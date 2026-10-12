"
I keep the plans of the running image: I am what the **Task Manager** shows.

- `addPlan:` registers a plan and gives it an id the model uses to refer to it.
- `review:` hands a plan to my `reviewer`, the object that lets the user
  validate each step. The Spec UI is the default reviewer; tests and scripts
  install their own with `reviewer:`.
- I announce `ChatPharoPlanBoardChanged` so windows stay current.

```smalltalk
ChatPharoPlanBoard default plans.
ChatPharoPlanBoard default removeFinishedPlans
```
"
Class {
	#name : 'ChatPharoPlanBoard',
	#superclass : 'Object',
	#instVars : [
		'plans',
		'reviewer',
		'announcer',
		'lastId'
	],
	#classInstVars : [
		'default'
	],
	#category : 'AI-ChatPharo-Plan',
	#package : 'AI-ChatPharo-Plan'
}

{ #category : 'accessing' }
ChatPharoPlanBoard class >> default [

	^ default ifNil: [ default := self new ]
]

{ #category : 'accessing' }
ChatPharoPlanBoard class >> reset [

	<script>
	default := nil
]

{ #category : 'adding' }
ChatPharoPlanBoard >> addPlan: aPlan [

	lastId := lastId + 1.
	aPlan id: 'plan-' , lastId printString.
	plans add: aPlan.
	self notifyChanged.
	^ aPlan
]

{ #category : 'accessing' }
ChatPharoPlanBoard >> announcer [

	^ announcer
]

{ #category : 'initialization' }
ChatPharoPlanBoard >> initialize [

	super initialize.
	plans := OrderedCollection new.
	announcer := Announcer new.
	lastId := 0
]

{ #category : 'announcing' }
ChatPharoPlanBoard >> notifyChanged [

	announcer announce: ChatPharoPlanBoardChanged new
]

{ #category : 'accessing' }
ChatPharoPlanBoard >> planWithId: anId ifAbsent: aBlock [

	^ plans detect: [ :each | each id = anId ] ifNone: aBlock
]

{ #category : 'accessing' }
ChatPharoPlanBoard >> plans [

	^ plans
]

{ #category : 'removing' }
ChatPharoPlanBoard >> removeAllPlans [

	plans removeAll.
	self notifyChanged
]

{ #category : 'removing' }
ChatPharoPlanBoard >> removeFinishedPlans [

	plans removeAllSuchThat: [ :each | each isFinished ].
	self notifyChanged
]

{ #category : 'reviewing' }
ChatPharoPlanBoard >> review: aPlan [
	"Let the user validate each step of aPlan. Steps left undecided are rejected."

	self reviewer review: aPlan.
	aPlan rejectUnvalidatedSteps.
	self notifyChanged
]

{ #category : 'accessing' }
ChatPharoPlanBoard >> reviewer [

	^ reviewer ifNil: [ ChatPharoPlanReviewPresenter ]
]

{ #category : 'accessing' }
ChatPharoPlanBoard >> reviewer: aReviewer [
	"aReviewer answers #review: by approving or rejecting each step of the plan it is given."

	reviewer := aReviewer
]
