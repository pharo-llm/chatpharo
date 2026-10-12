"
I give the model the tools to work **plan first**:

- `propose_plan` — submit the steps of a multi-step task. The user validates
  each step; the reply says which steps are approved and carries the user's
  feedback.
- `update_plan_step` — report progress on an approved step (in progress, done,
  failed), which the Task Manager shows live.
- `get_plan` — read a plan back.

When ""Validate plans step by step"" is switched off in the settings, proposed
plans are approved automatically and only serve as a progress display.
"
Class {
	#name : 'ChatPharoPlanTools',
	#superclass : 'ChatPharoToolProvider',
	#instVars : [
		'board'
	],
	#category : 'AI-ChatPharo-Plan',
	#package : 'AI-ChatPharo-Plan'
}

{ #category : 'accessing' }
ChatPharoPlanTools >> board [

	^ board ifNil: [ board := ChatPharoPlanBoard default ]
]

{ #category : 'accessing' }
ChatPharoPlanTools >> board: aPlanBoard [

	board := aPlanBoard
]

{ #category : 'tools' }
ChatPharoPlanTools >> getPlanTool [

	^ self
		  toolNamed: 'get_plan'
		  description: 'Reads a plan back: its steps, their status and the feedback of the user.'
		  properties: (Dictionary with: 'plan_id' -> (self property: 'string' description: 'The plan_id answered by propose_plan'))
		  required: #( 'plan_id' )
		  do: [ :arguments | self withPlan: (arguments at: 'plan_id') do: [ :plan | plan asDictionary ] ]
]

{ #category : 'private' }
ChatPharoPlanTools >> progress: aStatus on: aStep note: aNote [
	"Answer whether aStep accepted the progress report."

	aStatus = 'in_progress' ifTrue: [ ^ aStep start ].
	aStatus = 'done' ifTrue: [ ^ aStep complete: aNote ].
	aStatus = 'failed' ifTrue: [ ^ aStep fail: aNote ].
	^ false
]

{ #category : 'private' }
ChatPharoPlanTools >> proposePlan: arguments [

	| plan |
	plan := ChatPharoPlan title: (arguments at: 'title' ifAbsent: [ 'Plan' ]) steps: (arguments at: 'steps').
	plan steps ifEmpty: [ ^ Dictionary with: 'error' -> 'A plan needs at least one step.' ].
	self board addPlan: plan.
	ChatPharoSettings default planValidationEnabled
		ifTrue: [ self board review: plan ]
		ifFalse: [
			plan approveAll.
			self board notifyChanged ].
	^ plan asDictionary
]

{ #category : 'tools' }
ChatPharoPlanTools >> proposePlanTool [

	^ self
		  toolNamed: 'propose_plan'
		  description: 'Proposes a plan to the user before doing a task that needs several actions or changes the image. The user validates each step. The reply tells which steps are approved or rejected and carries the feedback of the user. Execute approved steps only.'
		  properties: (Dictionary
				   with: 'title' -> (self property: 'string' description: 'What the plan achieves, in a few words')
				   with: 'steps' -> (Dictionary
						    with: 'type' -> 'array'
						    with: 'items' -> (Dictionary with: 'type' -> 'string')
						    with: 'description' -> 'The steps in execution order, each one short, concrete and independently verifiable'))
		  required: #( 'title' 'steps' )
		  do: [ :arguments | self proposePlan: arguments ]
]

{ #category : 'accessing' }
ChatPharoPlanTools >> summary [

	^ 'Propose a plan, let the user validate each step, and report progress to the Task Manager.'
]

{ #category : 'accessing' }
ChatPharoPlanTools >> title [

	^ 'Plans and tasks'
]

{ #category : 'accessing' }
ChatPharoPlanTools >> tools [

	^ {
		  self proposePlanTool.
		  self updatePlanStepTool.
		  self getPlanTool }
]

{ #category : 'private' }
ChatPharoPlanTools >> updatePlanStep: arguments [

	^ self withPlan: (arguments at: 'plan_id') do: [ :plan |
		  | step accepted |
		  step := plan stepAt: (arguments at: 'step') ifAbsent: [ ^ Dictionary with: 'error' -> 'This plan has no such step.' ].
		  accepted := self progress: (arguments at: 'status') on: step note: (arguments at: 'note' ifAbsent: [ '' ]).
		  self board notifyChanged.
		  accepted
			  ifTrue: [ plan asDictionary ]
			  ifFalse: [
				  Dictionary
					  with: 'error' -> 'Refused: the user did not approve this step, or the status is not one of in_progress, done, failed.'
					  with: 'plan' -> plan asDictionary ] ]
]

{ #category : 'tools' }
ChatPharoPlanTools >> updatePlanStepTool [

	^ self
		  toolNamed: 'update_plan_step'
		  description: 'Reports progress on one approved step of a plan. Call it with "in_progress" before working on the step and with "done" or "failed" after. Steps the user rejected cannot be started.'
		  properties: (Dictionary new
				   at: 'plan_id' put: (self property: 'string' description: 'The plan_id answered by propose_plan');
				   at: 'step' put: (self property: 'integer' description: 'Number of the step, starting at 1');
				   at: 'status' put: (Dictionary
						    with: 'type' -> 'string'
						    with: 'enum' -> #( 'in_progress' 'done' 'failed' )
						    with: 'description' -> 'New status of the step');
				   at: 'note' put: (self property: 'string' description: 'Optional: what was done, or why it failed');
				   yourself)
		  required: #( 'plan_id' 'step' 'status' )
		  do: [ :arguments | self updatePlanStep: arguments ]
]

{ #category : 'private' }
ChatPharoPlanTools >> withPlan: anId do: aBlock [

	^ aBlock value: (self board planWithId: anId ifAbsent: [ ^ Dictionary with: 'error' -> ('There is no plan with id ' , anId printString) ])
]
