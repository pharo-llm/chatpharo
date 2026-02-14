Class {
	#name : 'ChatPharoThinkingPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'statusLabel',
		'dotsLabel',
		'animationProcess',
		'currentPhase',
		'showDetailsButton',
		'thinkingContent',
		'thinkingStartedAt',
		'thinkingElapsedSeconds',
		'modelNameLabel'
	],
	#category : 'AI-ChatPharo-Spec-Ethics',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Ethics'
}

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> agent [
	"Get the agent from the owner chat presenter's model"
	| chatPresenter chatModel |
	
	chatPresenter := self owner.
	
	"Navigate up the presenter hierarchy to find ChatPharoChatPresenter"
	[ chatPresenter isNotNil and: [ chatPresenter class name ~= #ChatPharoChatPresenter ] ] 
		whileTrue: [ chatPresenter := chatPresenter owner ].
	
	chatPresenter ifNil: [ ^ nil ].
	
	"Access the model slot directly since there's no public getter"
	chatModel := chatPresenter instVarNamed: 'model'.
	
	^ chatModel ifNotNil: [ chatModel agent ]
]

{ #category : 'layout' }
ChatPharoThinkingPresenter >> defaultLayout [

	| layout |
	layout := SpBoxLayout newHorizontal
		          spacing: 5;
		          vAlignCenter;
		          add: modelNameLabel expand: false;
		          add: statusLabel expand: false;
		          add: dotsLabel expand: false;
		          yourself. 
	self shouldShowThinkingUI ifTrue: [ layout add: showDetailsButton expand: false ].

	^ layout
]

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> formattedElapsedThinkingTime [
	"Format elapsed thinking time in minutes and seconds"

	| minutes secondsLabel totalSeconds |
	totalSeconds := thinkingElapsedSeconds.
	minutes := totalSeconds // 60.
	secondsLabel := totalSeconds \\ 60.

	^ String streamContents: [ :stream |
		stream
			nextPutAll: minutes asString;
			nextPutAll: ' min ';
			nextPutAll: secondsLabel asString;
			nextPutAll: ' sec (';
			nextPutAll: totalSeconds asString;
			nextPutAll: 's total)' ]
]

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> initialize [

	super initialize.
	currentPhase := #thinking.
	thinkingStartedAt := nil.
	thinkingElapsedSeconds := 0
]

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> initializePresenters [

	statusLabel := self newLabel
		               label: 'Thinking';
		               yourself.
		modelNameLabel := self newLabel
			          label: self modelNameLabelText;
			          help: 'Current model used for this chat';
			          yourself.
			
	dotsLabel := self newLabel
		             label: '';
		             yourself.
	showDetailsButton := self newButton
		                     label: 'Show Details';
		                     action: [ self openThinkingDetails ];
		                     yourself
]

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> isFinished [

	^ currentPhase = #finished
]

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> modelNameLabelText [

	| currentAgent modelName |
	currentAgent := self agent.
	modelName := (currentAgent respondsTo: #model)
		             ifTrue: [ currentAgent model ]
		             ifFalse: [ '' ].
	modelName ifNil: [ modelName := '' ].
	modelName := modelName asString trimBoth.

	^ 'Model: ' , (modelName ifEmpty: [ 'Not selected' ])
]

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> openThinkingDetails [
	"Open a new window to display the detailed thinking content"
	| detailPresenter |
	
	"Don't open if agent doesn't support thinking"
	self shouldShowThinkingUI ifFalse: [ ^ self ].
	
	detailPresenter := ChatPharoThinkingDetailPresenter new.
	detailPresenter thinkingContent: self thinkingContent.
	detailPresenter open
]

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> phase: aSymbol [
	"Set the current phase and update display.
	Valid phases: #thinking, #executing, #analyzing, #searching, #finished"

	currentPhase := aSymbol.
	aSymbol = #finished ifTrue: [ self updateElapsedThinkingTime ].
	self updateStatusLabel
]

{ #category : 'asserting' }
ChatPharoThinkingPresenter >> shouldShowThinkingUI [
	"Only show thinking UI if we have an agent that supports it"
	
	^ self agent isNotNil and: [ self agent supportsThinkingContent ]
]

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> startAnimation [
	"Start the animated dots"

	animationProcess ifNotNil: [ animationProcess terminate ].
	thinkingStartedAt := DateAndTime now.
	thinkingElapsedSeconds := 0.
	animationProcess := [
		                    | dots |
		                    dots := 0.
		                    [ true ] whileTrue: [
				                    dots := dots + 1 \\ 4.
				                    dotsLabel label: ('.' repeat: dots).
				                    (Delay forMilliseconds: 400) wait ] ] fork
]

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> stopAnimation [
	"Stop the animated dots"

	animationProcess ifNotNil: [
		animationProcess terminate.
		animationProcess := nil ].
	dotsLabel label: ''
]

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> thinkingContent [
	"Return the current thinking content"

	^ thinkingContent ifNil: [ '' ]
]

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> thinkingContent: aString [
	"Set the thinking content"

	thinkingContent := aString
]

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> updateElapsedThinkingTime [
	"Capture how long thinking took so we can show it when finished"

	thinkingStartedAt ifNil: [
		thinkingElapsedSeconds := 0.
		^ self ].

	thinkingElapsedSeconds := (((DateAndTime now - thinkingStartedAt) asSeconds rounded) max: 0)
]

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> updateStatusLabel [
	"Update the status label based on current phase"

	| text |
	text := currentPhase
		        caseOf: {
				        ([ #thinking ] -> [ 'Thinking' ]).
				        ([ #executing ] -> [ 'Executing tools' ]).
				        ([ #analyzing ] -> [ 'Analyzing' ]).
				        ([ #searching ] -> [ 'Searching code' ]).
				        ([ #finished ] -> [ 'End of thinking (' , self formattedElapsedThinkingTime , ')' ]) }
		        otherwise: [ 'Thinking' ].
		modelNameLabel label: self modelNameLabelText.
	statusLabel label: text
]
