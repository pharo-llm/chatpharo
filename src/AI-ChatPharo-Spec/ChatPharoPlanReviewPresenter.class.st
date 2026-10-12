"
I am the dialog in which the user validates a plan **step by step** before
ChatPharo executes anything.

Each step has its own check box: checked means approved, unchecked means
rejected. A feedback field lets the user say what to change or why a step is
refused; the model receives it with the verdict. Closing the window without
validating rejects every step.

I am the default `reviewer` of `ChatPharoPlanBoard`. Tools run in a background
process, so `review:` opens me on the UI process and makes the caller wait for
the user's decision.
"
Class {
	#name : 'ChatPharoPlanReviewPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'plan',
		'titleLabel',
		'stepsTable',
		'feedbackInput',
		'approveAllButton',
		'rejectAllButton',
		'validateButton',
		'validated'
	],
	#category : 'AI-ChatPharo-Spec-Plan',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Plan'
}

{ #category : 'reviewing' }
ChatPharoPlanReviewPresenter class >> review: aPlan [
	"Reviewer protocol of ChatPharoPlanBoard: answer once the user has decided on every step."

	| decided |
	UIManager default uiProcess == Processor activeProcess ifTrue: [ ^ (self on: aPlan) openModalReview ].
	decided := Semaphore new.
	UIManager default defer: [ [ (self on: aPlan) openModalReview ] ensure: [ decided signal ] ].
	decided wait
]

{ #category : 'actions' }
ChatPharoPlanReviewPresenter >> approveAll [

	plan approveAll.
	stepsTable refresh
]

{ #category : 'initialization' }
ChatPharoPlanReviewPresenter >> connectPresenters [

	approveAllButton action: [ self approveAll ].
	rejectAllButton action: [ self rejectAll ].
	validateButton action: [ self validate ]
]

{ #category : 'layout' }
ChatPharoPlanReviewPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 10;
		  borderWidth: 16;
		  add: titleLabel expand: false;
		  add: 'Tick the steps you approve. ChatPharo executes approved steps only.' expand: false;
		  add: stepsTable;
		  add: feedbackInput expand: false;
		  add: (SpBoxLayout newLeftToRight
				   spacing: 10;
				   add: approveAllButton expand: false;
				   add: rejectAllButton expand: false;
				   addLast: validateButton expand: false;
				   yourself)
		  expand: false;
		  yourself
]

{ #category : 'initialization' }
ChatPharoPlanReviewPresenter >> initializePresenters [

	validated := false.
	titleLabel := self newLabel
		              label: 'Plan: ' , plan title;
		              yourself.
	stepsTable := self newTable
		              addColumn: ((SpCheckBoxTableColumn title: 'Approve' evaluated: [ :step | step isApproved ])
				               onActivation: [ :step | step approve ];
				               onDeactivation: [ :step | step reject ];
				               width: 70;
				               yourself);
		              addColumn: ((SpIndexTableColumn title: '#')
				               width: 30;
				               yourself);
		              addColumn: (SpStringTableColumn title: 'Step' evaluated: [ :step | step description ]);
		              items: plan steps;
		              yourself.
	feedbackInput := self newTextInput
		                 placeholder: 'Feedback for ChatPharo: what to change, or why a step is rejected (optional)';
		                 yourself.
	approveAllButton := self newButton
		                    label: 'Approve all';
		                    icon: (self iconNamed: #smallOk);
		                    yourself.
	rejectAllButton := self newButton
		                   label: 'Reject all';
		                   icon: (self iconNamed: #smallCancel);
		                   yourself.
	validateButton := self newButton
		                  label: 'Validate';
		                  icon: (self iconNamed: #glamorousGo);
		                  help: 'Send your decision on each step to ChatPharo';
		                  yourself
]

{ #category : 'initialization' }
ChatPharoPlanReviewPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		title: 'ChatPharo · Validate plan';
		initialExtent: 720 @ 460;
		centered
]

{ #category : 'reviewing' }
ChatPharoPlanReviewPresenter >> openModalReview [
	"Wait for the user. A window closed without validating rejects the whole plan."

	self openModal.
	validated ifTrue: [ ^ self ].
	plan rejectAll.
	plan feedback: 'The user closed the plan review without validating it.'
]

{ #category : 'actions' }
ChatPharoPlanReviewPresenter >> rejectAll [

	plan rejectAll.
	stepsTable refresh
]

{ #category : 'accessing - model' }
ChatPharoPlanReviewPresenter >> setModelBeforeInitialization: aPlan [

	plan := aPlan
]

{ #category : 'actions' }
ChatPharoPlanReviewPresenter >> validate [

	validated := true.
	plan feedback: (feedbackInput text ifNil: [ '' ]) asString trimBoth.
	self window close
]
