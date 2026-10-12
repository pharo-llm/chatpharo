Class {
	#name : 'ChatPharoPlanToolsTest',
	#superclass : 'TestCase',
	#instVars : [
		'board',
		'tools'
	],
	#category : 'AI-ChatPharo-Tests-Plan',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Plan'
}

{ #category : 'private' }
ChatPharoPlanToolsTest >> call: aToolName with: arguments [

	^ (tools tools detect: [ :each | each name = aToolName ]) applyTo: arguments
]

{ #category : 'private' }
ChatPharoPlanToolsTest >> proposeTwoSteps [

	^ self call: 'propose_plan' with: (Dictionary with: 'title' -> 'Add logging' with: 'steps' -> #( 'Create Logger' 'Use it' ))
]

{ #category : 'private' }
ChatPharoPlanToolsTest >> reviewApprovingOnlyFirstStep [
	"A reviewer is anything answering #review: — here the user approves step 1 and explains why not step 2."

	board reviewer: (ChatPharoPlanTestReviewer new
			 approvedIndexes: #( 1 );
			 feedback: 'Do not touch Foo yet';
			 yourself)
]

{ #category : 'running' }
ChatPharoPlanToolsTest >> setUp [

	super setUp.
	board := ChatPharoPlanBoard new.
	tools := ChatPharoPlanTools new
		         board: board;
		         yourself.
	self reviewApprovingOnlyFirstStep
]

{ #category : 'running' }
ChatPharoPlanToolsTest >> tearDown [

	ChatPharoSettings resetDefault.
	super tearDown
]

{ #category : 'tests' }
ChatPharoPlanToolsTest >> testEachStepCarriesTheDecisionOfTheUser [

	| result |
	result := self proposeTwoSteps.
	self assert: ((result at: 'steps') collect: [ :each | each at: 'status' ]) equals: #( 'approved' 'rejected' ).
	self assert: (result at: 'user_feedback') equals: 'Do not touch Foo yet'.
	self assert: ((result at: 'instruction') includesSubstring: 'approved steps')
]

{ #category : 'tests' }
ChatPharoPlanToolsTest >> testFullyRejectedPlanTellsTheModelNotToExecuteIt [

	| result |
	board reviewer: (ChatPharoPlanTestReviewer new
			 approvedIndexes: #(  );
			 yourself).
	result := self proposeTwoSteps.
	self assert: ((result at: 'instruction') includesSubstring: 'Do not execute')
]

{ #category : 'tests' }
ChatPharoPlanToolsTest >> testPlanIsKeptOnTheBoardForTheTaskManager [

	self proposeTwoSteps.
	self assert: board plans size equals: 1.
	self assert: board plans first title equals: 'Add logging'.
	self assert: board plans first id equals: 'plan-1'
]

{ #category : 'tests' }
ChatPharoPlanToolsTest >> testProgressIsReportedOnApprovedSteps [

	| planId result |
	planId := self proposeTwoSteps at: 'plan_id'.
	self call: 'update_plan_step' with: (Dictionary with: 'plan_id' -> planId with: 'step' -> 1 with: 'status' -> 'in_progress').
	self assert: board plans first steps first status equals: #inProgress.
	result := self call: 'update_plan_step' with: (Dictionary new
			           at: 'plan_id' put: planId;
			           at: 'step' put: 1;
			           at: 'status' put: 'done';
			           at: 'note' put: 'Logger created';
			           yourself).
	self assert: (((result at: 'steps') first) at: 'status') equals: 'done'.
	self assert: board plans first steps first note equals: 'Logger created'.
	self assert: board plans first progressLabel equals: '1/2 done'
]

{ #category : 'tests' }
ChatPharoPlanToolsTest >> testRejectedStepCannotBeStarted [

	| planId result |
	planId := self proposeTwoSteps at: 'plan_id'.
	result := self call: 'update_plan_step' with: (Dictionary with: 'plan_id' -> planId with: 'step' -> 2 with: 'status' -> 'in_progress').
	self assert: (result includesKey: 'error').
	self assert: board plans first steps second status equals: #rejected
]

{ #category : 'tests' }
ChatPharoPlanToolsTest >> testStepsLeftUndecidedByTheReviewerAreRejected [

	| plan |
	board reviewer: (ChatPharoPlanTestReviewer new
			 approvedIndexes: #( 2 );
			 leaveOthersUndecided;
			 yourself).
	self proposeTwoSteps.
	plan := board plans first.
	self assert: plan steps first isRejected.
	self assert: plan steps second isApproved
]

{ #category : 'tests' }
ChatPharoPlanToolsTest >> testUnknownPlanIsAnError [

	self assert: ((self call: 'get_plan' with: (Dictionary with: 'plan_id' -> 'plan-99')) includesKey: 'error')
]

{ #category : 'tests' }
ChatPharoPlanToolsTest >> testWithoutValidationEveryStepIsApproved [

	| result |
	ChatPharoSettings default planValidationEnabled: false.
	board reviewer: (ChatPharoPlanTestReviewer new
			 approvedIndexes: #(  );
			 yourself).
	result := self proposeTwoSteps.
	self assert: ((result at: 'steps') collect: [ :each | each at: 'status' ]) equals: #( 'approved' 'approved' )
]
