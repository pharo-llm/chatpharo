Class {
	#name : 'ChatPharoThinkingPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'thinkingButton',
		'animationProcess',
		'currentPhase',
		'thinkingContent',
		'thinkingStartedAt',
		'thinkingElapsedSeconds',
		'executedTools',
		'detailWindow'
	],
	#category : 'AI-ChatPharo-Spec-Ethics',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Ethics'
}

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> addExecutedTool: aToolName [
	"Record a tool execution and update the display"

	aToolName ifNil: [ ^ self ].
	executedTools add: aToolName.
	self updateButtonLabel.
	detailWindow ifNotNil: [ :w |
		w presenter updateDetails ]
]

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

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> clearExecutedTools [
	"Clear the list of executed tools"

	executedTools removeAll.
	self updateButtonLabel
]

{ #category : 'layout' }
ChatPharoThinkingPresenter >> defaultLayout [

	^ SpBoxLayout newHorizontal
		  vAlignCenter;
		  add: thinkingButton expand: true;
		  yourself
]

{ #category : 'layout' }
ChatPharoThinkingPresenter >> executedTools [

	^ executedTools
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
	thinkingElapsedSeconds := 0.
	executedTools := OrderedCollection new
]

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> initializePresenters [

thinkingButton := self newButton
		label: 'Thinking...';
		icon: (self iconNamed: #smallInfo);
		help: 'Click to view thinking details, tools, and stats';
		action: [ self openThinkingDetails ];
		yourself
]

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> isFinished [

	^ currentPhase = #finished
]

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> modelNameText [

	| currentAgent modelName |
	currentAgent := self agent.
	modelName := (currentAgent respondsTo: #model)
		             ifTrue: [ currentAgent model ]
		             ifFalse: [ '' ].
	modelName ifNil: [ modelName := '' ].
^ modelName asString trimBoth
]

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> openThinkingDetails [
	| detailPresenter |
	detailPresenter := ChatPharoThinkingDetailPresenter new.
	detailPresenter
		thinkingPresenter: self.
	detailWindow := detailPresenter open.
	detailWindow whenClosedDo: [ detailWindow := nil ]
]

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> phase: aSymbol [

	currentPhase := aSymbol.
	aSymbol = #finished ifTrue: [
		self updateElapsedThinkingTime ].
	self updateButtonLabel.
	detailWindow ifNotNil: [ :w | w presenter updateDetails ]
]

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> phaseText [

	^ currentPhase
		caseOf: {
			([ #thinking ]  -> [ 'Thinking' ]).
			([ #executing ] -> [ 'Executing tools' ]).
			([ #analyzing ] -> [ 'Analyzing' ]).
			([ #searching ] -> [ 'Searching code' ]).
			([ #finished ]  -> [ 'Done' ]) }
		otherwise: [ 'Thinking' ]
]

{ #category : 'asserting' }
ChatPharoThinkingPresenter >> shouldShowThinkingUI [
	"Only show thinking UI if we have an agent that supports it"
	
	^ self agent isNotNil and: [ self agent supportsThinkingContent ]
]

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> startAnimation [
animationProcess ifNotNil: [ animationProcess terminate ].
	thinkingStartedAt := DateAndTime now.
	thinkingElapsedSeconds := 0.
	self clearExecutedTools.
	animationProcess := [
		| dots |
		dots := 0.
		[ true ] whileTrue: [
			dots := dots + 1 \\ 4.
			thinkingElapsedSeconds := (DateAndTime now - thinkingStartedAt) asSeconds rounded max: 0.
			self updateButtonLabel.
			detailWindow ifNotNil: [ :w |
				w presenter updateDetails ].
			(Delay forMilliseconds: 400) wait ] ] fork
]

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> stopAnimation [
	"Stop the animated dots"

	animationProcess ifNotNil: [
			animationProcess terminate.
animationProcess := nil ]
]

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> thinkingContent [
	"Return the current thinking content"

	^ thinkingContent ifNil: [ '' ]
]

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> thinkingContent: aString [
	"Set the thinking content"

	thinkingContent := aString.
		detailWindow ifNotNil: [ :w |
		w presenter updateDetails ]
]

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> thinkingElapsedSeconds [

	^ thinkingElapsedSeconds
]

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> updateButtonLabel [
	"Update the single button label with compact status"

	| label |
	label := String streamContents: [ :stream |
		stream nextPutAll: self phaseText.
		thinkingElapsedSeconds > 0 ifTrue: [
			stream
				nextPutAll: ' (';
				nextPutAll: thinkingElapsedSeconds asString;
				nextPutAll: 's)' ].
		executedTools ifNotEmpty: [
			stream
				nextPutAll: ' | ';
				nextPutAll: executedTools size asString;
				nextPutAll: ' tool';
				nextPutAll: (executedTools size > 1 ifTrue: [ 's' ] ifFalse: [ '' ]) ] ].
	thinkingButton label: label
]

{ #category : 'initialization' }
ChatPharoThinkingPresenter >> updateElapsedThinkingTime [
	"Capture how long thinking took so we can show it when finished"

	thinkingStartedAt ifNil: [
		thinkingElapsedSeconds := 0.
		^ self ].

	thinkingElapsedSeconds := (((DateAndTime now - thinkingStartedAt) asSeconds rounded) max: 0)
]
