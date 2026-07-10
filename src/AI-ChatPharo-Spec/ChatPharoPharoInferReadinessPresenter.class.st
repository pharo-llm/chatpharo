"
Progress dialog used while preparing the PharoInfer native runtime.
"
Class {
	#name : 'ChatPharoPharoInferReadinessPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'titleLabel',
		'progressBar',
		'statusLabel',
		'isComplete',
		'onComplete'
	],
	#category : 'AI-ChatPharo-Spec-Agent',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Agent'
}

{ #category : 'opening' }
ChatPharoPharoInferReadinessPresenter class >> openAndPrepareThen: aBlock [

	| presenter |
	presenter := self new.
	presenter onComplete: aBlock.
	presenter openModal.
	^ presenter
]

{ #category : 'opening' }
ChatPharoPharoInferReadinessPresenter class >> openIfNeededThen: aBlock [

	ChatPharoPharoInferRuntime shouldPrepareAtStartup ifFalse: [
		ChatPharoPharoInferRuntime configureInstalledLibrary.
		aBlock value.
		^ nil ].
	^ self openAndPrepareThen: aBlock
]

{ #category : 'closing' }
ChatPharoPharoInferReadinessPresenter >> askOkToClose [

	isComplete ifFalse: [
		self inform: 'Please wait for PharoInfer preparation to complete.'.
		^ false ].
	^ true
]

{ #category : 'layout' }
ChatPharoPharoInferReadinessPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 16;
		  borderWidth: 24;
		  add: titleLabel expand: false;
		  add: progressBar expand: false;
		  add: statusLabel expand: false;
		  yourself
]

{ #category : 'initialization' }
ChatPharoPharoInferReadinessPresenter >> initialize [

	super initialize.
	isComplete := false
]

{ #category : 'initialization' }
ChatPharoPharoInferReadinessPresenter >> initializePresenters [

	super initializePresenters.
	titleLabel := self newLabel
		              label: 'Preparing PharoInfer Runtime';
		              yourself.
	progressBar := self newProgressBar
		               progress: 0;
		               yourself.
	statusLabel := self newLabel
		               label: 'Preparing native library...';
		               yourself
]

{ #category : 'initialization' }
ChatPharoPharoInferReadinessPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		title: 'Building ChatPharo Image Runtime';
		initialExtent: 520 @ 150;
		centered
]

{ #category : 'accessing' }
ChatPharoPharoInferReadinessPresenter >> onComplete: aBlock [

	onComplete := aBlock
]

{ #category : 'opening' }
ChatPharoPharoInferReadinessPresenter >> openModal [

	| window |
	window := self open.
	self prepareRuntime.
	^ window
]

{ #category : 'running' }
ChatPharoPharoInferReadinessPresenter >> prepareRuntime [

	[
		| succeeded |
		succeeded := ChatPharoPharoInferRuntime ensureReadyWithProgressDo: [
			             :message
			             :progress |
			             self defer: [
				             statusLabel label: message.
				             progressBar progress: progress ] ].
		self defer: [
			isComplete := true.
			progressBar progress: 1.0.
			statusLabel label: (succeeded
					 ifTrue: [ 'PharoInfer native runtime is ready.' ]
					 ifFalse: [ ChatPharoPharoInferRuntime statusText ]).
			500 milliSeconds wait.
			self window close.
			onComplete ifNotNil: [ onComplete value ] ] ] fork
]
