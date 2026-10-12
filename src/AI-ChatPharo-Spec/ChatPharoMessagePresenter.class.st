"
Renders one ChatPharoMessage using Microdown for rich text.

```smalltalk
(ChatPharoMessage new
	content: 'Bonjour';
	answer: 'Salut';
	yourself) presenter open
```
"
Class {
	#name : 'ChatPharoMessagePresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'model',
		'contentPresenter',
		'answerPresenter',
		'goodFeedbackButton',
		'badFeedbackButton',
		'copyButton',
		'reasoningButton',
		'usageLabel'
	],
	#category : 'AI-ChatPharo-Spec-Core',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Core'
}

{ #category : 'layout' }
ChatPharoMessagePresenter >> answerLayout [

	^ SpOverlayLayout new
		  child: answerPresenter;
		  addOverlay: copyButton withConstraints: [ :c |
			  c
				  vAlignStart;
				  hAlignEnd ];
		  yourself
]

{ #category : 'accessing' }
ChatPharoMessagePresenter >> answerText [

	^ model answer ifNil: [ '' ]
]

{ #category : 'layout' }
ChatPharoMessagePresenter >> bottomMargin [

	^ 10
]

{ #category : 'initialization' }
ChatPharoMessagePresenter >> connectPresenters [

	goodFeedbackButton action: [
		model feedback: true.
		self updateFeedbackButtons ].
	badFeedbackButton action: [
		model feedback: false.
		self updateFeedbackButtons ].
	reasoningButton action: [ self showReasoning ].
	self updateContents
]

{ #category : 'layout' }
ChatPharoMessagePresenter >> defaultLayout [
	"The user's words, the answer, then a footer with the reasoning, the token usage and the feedback.
	 A section with nothing to show takes no room: a pending answer or a system notice is not padded."

	| layout |
	layout := SpBoxLayout newVertical.
	self hasUserText ifTrue: [
		layout
			add: 'User' withConstraints: [ :c | c height: self labelHeight ];
			add: contentPresenter withConstraints: [ :c | c height: (self heightForText: self userText) ] ].
	self hasAnswer ifTrue: [
		layout
			add: model assistantLabel withConstraints: [ :c | c height: self labelHeight ];
			add: self answerLayout withConstraints: [ :c | c height: (self heightForText: self answerText) ] ].
	self hasFooter ifTrue: [ layout add: self footerLayout withConstraints: [ :c | c height: self footerHeight ] ].
	^ layout
]

{ #category : 'accessing' }
ChatPharoMessagePresenter >> estimatedHeightFor: aString [

	^ self heightForText: aString
]

{ #category : 'accessing' }
ChatPharoMessagePresenter >> estimatedLineCountFor: aString [

	^ ((aString ifNil: [ '' ]) lines ifEmpty: [ #( '' ) ]) inject: 0 into: [ :sum :line |
		  sum + ((line size / self wrapColumn) ceiling max: 1) ]
]

{ #category : 'layout' }
ChatPharoMessagePresenter >> footerHeight [

	^ 30
]

{ #category : 'layout' }
ChatPharoMessagePresenter >> footerLayout [

	| footer |
	footer := SpBoxLayout newHorizontal
		          spacing: 8;
		          yourself.
	self hasReasoning ifTrue: [ footer add: reasoningButton expand: false ].
	footer add: usageLabel expand: false.
	ChatPharoSettings default feedbackButtonsEnabled ifTrue: [
		footer
			addLast: goodFeedbackButton expand: false;
			addLast: badFeedbackButton expand: false ].
	^ footer
]

{ #category : 'testing' }
ChatPharoMessagePresenter >> hasAnswer [

	^ self answerText notEmpty
]

{ #category : 'testing' }
ChatPharoMessagePresenter >> hasFooter [

	^ self hasAnswer and: [
		  self hasReasoning or: [ self usageText notEmpty or: [ ChatPharoSettings default feedbackButtonsEnabled ] ] ]
]

{ #category : 'testing' }
ChatPharoMessagePresenter >> hasReasoning [

	^ model thinking isEmptyOrNil not
]

{ #category : 'testing' }
ChatPharoMessagePresenter >> hasUserText [

	^ self userText notEmpty
]

{ #category : 'accessing' }
ChatPharoMessagePresenter >> height [
	"The room I need in the transcript: exactly the sum of what #defaultLayout lays out."

	| total |
	total := 0.
	self hasUserText ifTrue: [ total := total + self labelHeight + (self heightForText: self userText) ].
	self hasAnswer ifTrue: [ total := total + self labelHeight + (self heightForText: self answerText) ].
	self hasFooter ifTrue: [ total := total + self footerHeight ].
	^ total + self bottomMargin
]

{ #category : 'layout' }
ChatPharoMessagePresenter >> heightForText: aString [
	"Room for aString once rendered: its wrapped lines plus the padding of the text widget.
	 There is no upper bound: the transcript scrolls, a message does not scroll inside itself."

	^ (self estimatedLineCountFor: aString) * self lineHeight + self textPadding
]

{ #category : 'initialization' }
ChatPharoMessagePresenter >> initializePresenters [

	contentPresenter := MicrodownPresenter new.
	answerPresenter := MicrodownPresenter new.

	goodFeedbackButton := self newButton
		label: 'Good';
		help: 'Mark code as valid';
		action: [
			model feedback: true.
			self updateFeedbackButtons
		];
		yourself.

	badFeedbackButton := self newButton
		label: 'Bad';
		help: 'Mark code as invalid';
		action: [
			model feedback: false.
			self updateFeedbackButtons
		];
		yourself.

	copyButton := self newButton
		icon: (self iconNamed: #smallCopy);
		label: '';
		help: 'Copy answer to clipboard';
		action: [
			Clipboard clipboardText: (model answer ifNil: [ '' ]).
			UIManager default inform: 'Copied to clipboard'
		];
		yourself.

	reasoningButton := self newButton
		                   label: 'Reasoning';
		                   icon: (self iconNamed: #smallInfo);
		                   help: 'Show what the model thought and which tools it ran for this answer';
		                   yourself.
	usageLabel := self newLabel
		              label: self usageText;
		              yourself.
	copyButton visible: true.
	self updateFeedbackButtons.

]

{ #category : 'layout' }
ChatPharoMessagePresenter >> initializeWindow: aWindowPresenter [
	
	super initializeWindow: aWindowPresenter.
	
	aWindowPresenter
		title: 'Message presenter';
		initialExtent: 400@200
]

{ #category : 'layout' }
ChatPharoMessagePresenter >> labelHeight [

	^ 22
]

{ #category : 'layout' }
ChatPharoMessagePresenter >> lineHeight [

	^ 20
]

{ #category : 'updating' }
ChatPharoMessagePresenter >> refresh [
	"My message changed, typically its answer arrived: show it and take the room it needs."

	self updateContents.
	self layout: self defaultLayout
]

{ #category : 'accessing - model' }
ChatPharoMessagePresenter >> setModelBeforeInitialization: anObject [

	model := anObject
]

{ #category : 'actions' }
ChatPharoMessagePresenter >> showReasoning [
	"Open what the model thought and which tools it ran for this answer. It stays available
	 after the answer arrived, unlike the transient 'Thinking…' indicator."

	| viewer |
	viewer := SpTextPresenter new
		          text: model thinking;
		          beNotEditable;
		          yourself.
	viewer open
		title: 'ChatPharo · Reasoning and tool calls';
		resize: 760 @ 520
]

{ #category : 'layout' }
ChatPharoMessagePresenter >> textPadding [

	^ 16
]

{ #category : 'updating' }
ChatPharoMessagePresenter >> updateContents [

	contentPresenter document: (Microdown parse: self userText).
	answerPresenter document: (Microdown parse: self answerText).
	usageLabel label: self usageText
]

{ #category : 'updating' }
ChatPharoMessagePresenter >> updateFeedbackButtons [

	| feedback |
	feedback := model feedback.

	goodFeedbackButton enabled: (feedback isNil or: [ feedback not ]).
	badFeedbackButton enabled: (feedback isNil or: [ feedback ]).
]

{ #category : 'accessing' }
ChatPharoMessagePresenter >> usageText [

	| total |
	total := model totalTokens ifNil: [ 0 ].
	total = 0 ifTrue: [ ^ '' ].
	^ '{1} tokens in · {2} out' format: {
			  (model inputTokens ifNil: [ 0 ]).
			  (model outputTokens ifNil: [ 0 ]) }
]

{ #category : 'accessing' }
ChatPharoMessagePresenter >> userText [

	^ model content ifNil: [ '' ]
]

{ #category : 'layout' }
ChatPharoMessagePresenter >> wrapColumn [
	"Characters per rendered line at the default window width."

	^ 95
]
