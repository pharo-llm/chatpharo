"
I am the **ChatPharo Task Manager**: the window that shows what ChatPharo is
working on.

On the left, the plans the model proposed, with their progress. On the right,
the steps of the selected plan: which ones the user approved or rejected, which
one is in progress, what was done and what failed.

I listen to `ChatPharoPlanBoard`, so I update while the model works.

```smalltalk
ChatPharoTaskManagerPresenter new open
```
"
Class {
	#name : 'ChatPharoTaskManagerPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'board',
		'plansList',
		'stepsTable',
		'feedbackLabel',
		'removeFinishedButton',
		'removeAllButton'
	],
	#category : 'AI-ChatPharo-Spec-Plan',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Plan'
}

{ #category : 'accessing' }
ChatPharoTaskManagerPresenter >> board [

	^ board ifNil: [ board := ChatPharoPlanBoard default ]
]

{ #category : 'initialization' }
ChatPharoTaskManagerPresenter >> connectPresenters [

	plansList whenSelectionChangedDo: [ :selection | self showPlan: selection selectedItem ].
	removeFinishedButton action: [ self board removeFinishedPlans ].
	removeAllButton action: [ self board removeAllPlans ].
	self board announcer weak when: ChatPharoPlanBoardChanged send: #refreshLater to: self
]

{ #category : 'layout' }
ChatPharoTaskManagerPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 8;
		  borderWidth: 8;
		  add: (SpPanedLayout newLeftToRight
				   positionOfSlider: 30 percent;
				   add: plansList;
				   add: (SpBoxLayout newTopToBottom
						    spacing: 6;
						    add: stepsTable;
						    add: feedbackLabel expand: false;
						    yourself);
				   yourself);
		  add: (SpBoxLayout newLeftToRight
				   spacing: 8;
				   add: removeFinishedButton expand: false;
				   add: removeAllButton expand: false;
				   yourself)
		  expand: false;
		  yourself
]

{ #category : 'initialization' }
ChatPharoTaskManagerPresenter >> initializePresenters [

	plansList := self newList
		             display: [ :plan | plan title , '  (' , plan progressLabel , ')' ];
		             items: self board plans;
		             yourself.
	stepsTable := self newTable
		              addColumn: ((SpIndexTableColumn title: '#')
				               width: 30;
				               yourself);
		              addColumn: ((SpStringTableColumn title: 'Status' evaluated: [ :step | step statusLabel ])
				               width: 150;
				               yourself);
		              addColumn: (SpStringTableColumn title: 'Step' evaluated: [ :step | step description ]);
		              addColumn: ((SpStringTableColumn title: 'Note' evaluated: [ :step | step note ])
				               width: 200;
				               yourself);
		              yourself.
	feedbackLabel := self newLabel.
	removeFinishedButton := self newButton
		                        label: 'Clear finished';
		                        icon: (self iconNamed: #smallDelete);
		                        yourself.
	removeAllButton := self newButton
		                   label: 'Clear all';
		                   icon: (self iconNamed: #delete);
		                   yourself.
	self showPlan: nil
]

{ #category : 'initialization' }
ChatPharoTaskManagerPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		title: 'ChatPharo Task Manager';
		initialExtent: 900 @ 480;
		whenClosedDo: [ self board announcer unsubscribe: self ]
]

{ #category : 'updating' }
ChatPharoTaskManagerPresenter >> refresh [

	| selected |
	selected := plansList selectedItem.
	plansList items: self board plans.
	(self board plans includes: selected) ifTrue: [ plansList selectItem: selected ].
	self showPlan: plansList selectedItem
]

{ #category : 'updating' }
ChatPharoTaskManagerPresenter >> refreshLater [
	"The board changes from the process of the agent; widgets are updated on the UI process."

	self defer: [ self refresh ]
]

{ #category : 'updating' }
ChatPharoTaskManagerPresenter >> showPlan: aPlanOrNil [

	aPlanOrNil ifNil: [
		stepsTable items: #(  ).
		feedbackLabel label: 'Select a plan to see its steps.'.
		^ self ].
	stepsTable items: aPlanOrNil steps.
	feedbackLabel label: (aPlanOrNil feedback
			 ifEmpty: [ 'No feedback from the user on this plan.' ]
			 ifNotEmpty: [ :feedback | 'User feedback: ' , feedback ])
]
