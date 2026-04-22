"
A rich Spec dialog the user sees before ChatPharo executes a mutating
tool on the live image. It replaces the minimal `UIManager default`
fallback with a proper Pharo-native confirmation UI:

- A headline with the action and the target (""Create class Foo in
  AI-ChatPharo-Examples"").
- The raw tool name, so power users can recognise what the model asked
  for.
- An arguments panel showing every argument the model sent, so the user
  can verify no surprise is hidden in a method body or a class name.
- Three buttons:
    Allow               - run the tool this one time.
    Always in this chat - run and remember for the rest of the session.
    Deny                - cancel the tool. The model receives a
                          structured cancellation payload.

The class registers itself as the gate on `ChatPharoToolConfirmation`
when it is loaded (class-side `#initialize`), so merely loading the
Spec package is enough to upgrade the dialog. Tools dispatching from
forked processes call in via the class-side
`confirmToolNamed:arguments:action:summary:`, which defers the UI work
to the UI thread and blocks on a `Semaphore` until the user answers —
this is the same pattern `ChatPharoDefaultsProgressPresenter` uses for
progress updates, kept consistent across the codebase.
"
Class {
	#name : 'ChatPharoToolConfirmationPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'toolName',
		'actionLabel',
		'summaryString',
		'argumentsDict',
		'headlineLabel',
		'toolNameLabel',
		'descriptionText',
		'argumentsTable',
		'allowButton',
		'alwaysButton',
		'denyButton',
		'rememberChoiceCheckBox',
		'decision'
	],
	#category : 'AI-ChatPharo-Spec-Confirmation',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Confirmation'
}

{ #category : 'gate' }
ChatPharoToolConfirmationPresenter class >> confirmToolNamed: aToolName arguments: anArguments action: actionLabel summary: summaryString [
	"Gate entry point invoked by ChatPharoToolConfirmation. Tool calls
	 usually run in a forked background process, so we bring the dialog
	 onto the UI thread via `UIManager default defer:` and block the
	 caller on a Semaphore until the user clicks a button.

	 Edge case: if we are *already* on the UI process (e.g. called from a
	 menu handler), deferring + waiting would deadlock, so we just run
	 the dialog synchronously.

	 Returns a ChatPharoToolConfirmationDecision. Never nil."

	self isOnUIProcess ifTrue: [
		^ self runConfirmationFor: aToolName
			arguments: anArguments
			action: actionLabel
			summary: summaryString ].

	^ self deferConfirmationFor: aToolName
		arguments: anArguments
		action: actionLabel
		summary: summaryString
]

{ #category : 'gate' }
ChatPharoToolConfirmationPresenter class >> deferConfirmationFor: aToolName arguments: anArguments action: actionLabel summary: summaryString [
	"Defer the dialog onto the UI thread and block the caller on a
	 semaphore until the user answers."

	| semaphore answerHolder |
	semaphore := Semaphore new.
	answerHolder := Array new: 1.

	UIManager default defer: [
		[
			answerHolder at: 1 put: (self
				runConfirmationFor: aToolName
				arguments: anArguments
				action: actionLabel
				summary: summaryString) ]
			on: Error
			do: [ :e |
				answerHolder at: 1 put: (ChatPharoToolConfirmationDecision
					denyWithReason: 'Confirmation dialog crashed: ', e messageText) ].
		semaphore signal ].

	semaphore wait.
	^ (answerHolder at: 1) ifNil: [ ChatPharoToolConfirmationDecision deny ]
]

{ #category : 'class initialization' }
ChatPharoToolConfirmationPresenter class >> initialize [
	"Install this presenter as the active gate on ChatPharoToolConfirmation
	 as soon as the class is loaded. This is the single line responsible
	 for swapping the UIManager-based fallback for the rich Spec dialog."

	ChatPharoToolConfirmation default gate: self
]

{ #category : 'gate' }
ChatPharoToolConfirmationPresenter class >> isOnUIProcess [
	"Return true if we are currently executing on the Morphic UI process.
	 Defensive: if the UIManager cannot report a UI process (headless,
	 or exotic image), fall back to false and let the deferred path
	 handle things."

	^ [
		| uiProcess |
		uiProcess := UIManager default uiProcess.
		uiProcess notNil and: [ Processor activeProcess == uiProcess ] ]
		on: Error
		do: [ false ]
]

{ #category : 'gate' }
ChatPharoToolConfirmationPresenter class >> runConfirmationFor: aToolName arguments: anArguments action: actionLabel summary: summaryString [
	"Build the presenter and open it modally. Meant to be called from the
	 UI process — synchronously returns a decision."

	| presenter |
	presenter := self new
		toolName: aToolName;
		actionLabel: actionLabel;
		summaryString: summaryString;
		argumentsDict: anArguments;
		yourself.
	presenter openModalDialog.
	^ presenter decision
]

{ #category : 'actions' }
ChatPharoToolConfirmationPresenter >> accept [

	decision := rememberChoiceCheckBox state
		            ifTrue: [ ChatPharoToolConfirmationDecision always ]
		            ifFalse: [ ChatPharoToolConfirmationDecision allow ].
	self closeWindow
]

{ #category : 'actions' }
ChatPharoToolConfirmationPresenter >> acceptAlways [

	decision := ChatPharoToolConfirmationDecision always.
	self closeWindow
]

{ #category : 'accessing' }
ChatPharoToolConfirmationPresenter >> actionLabel [

	^ actionLabel ifNil: [ 'Run tool' ]
]

{ #category : 'accessing' }
ChatPharoToolConfirmationPresenter >> actionLabel: aString [

		actionLabel := aString.
	headlineLabel ifNotNil: [ headlineLabel label: self actionLabel ]
]

{ #category : 'accessing' }
ChatPharoToolConfirmationPresenter >> argumentsDict [

	^ argumentsDict ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
ChatPharoToolConfirmationPresenter >> argumentsDict: aDictionary [

	argumentsDict := aDictionary.
	argumentsTable ifNotNil: [ argumentsTable items: self argumentsRows ]
]

{ #category : 'private' }
ChatPharoToolConfirmationPresenter >> argumentsRows [
	"The table rows, each an Association key -> rendered value."

	^ self argumentsDict keys asSortedCollection asOrderedCollection
		collect: [ :key | key -> (self renderValue: (self argumentsDict at: key)) ]
]

{ #category : 'private' }
ChatPharoToolConfirmationPresenter >> closeWindow [
	"Close the modal. `askOkToClose` already returns true, so just delete."

	self window ifNotNil: [ :w | w close ]
]

{ #category : 'actions' }
ChatPharoToolConfirmationPresenter >> connectPresenters [

	allowButton action: [ self accept ].
	alwaysButton action: [ self acceptAlways ].
	denyButton action: [ self reject ]
]

{ #category : 'accessing' }
ChatPharoToolConfirmationPresenter >> decision [

	^ decision
]

{ #category : 'layout' }
ChatPharoToolConfirmationPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 10;
		  borderWidth: 20;
		  add: headlineLabel expand: false;
		  add: toolNameLabel expand: false;
		  add: descriptionText expand: false;
		  add: 'Arguments' expand: false;
		  add: argumentsTable;
		  add: rememberChoiceCheckBox expand: false;
		  add: (SpBoxLayout newLeftToRight
				   spacing: 10;
				   addLast: denyButton expand: false;
				   addLast: alwaysButton expand: false;
				   addLast: allowButton expand: false;
				   yourself)
		  expand: false;
		  yourself
]

{ #category : 'initialization' }
ChatPharoToolConfirmationPresenter >> initialize [

	super initialize.
	decision := nil
]

{ #category : 'initialization' }
ChatPharoToolConfirmationPresenter >> initializePresenters [

	super initializePresenters.

	headlineLabel := self newLabel
		label: self actionLabel;
		yourself.

	toolNameLabel := self newLabel
		label: 'tool: ', (toolName ifNil: [ '' ]);
		yourself.

	descriptionText := self newText
		text: (summaryString ifNil: [
			'ChatPharo wants to modify your image. Review the arguments below before authorising this call.' ]);
		beNotEditable;
		yourself.

	argumentsTable := self newTable
		addColumn: (SpStringTableColumn title: 'Argument' evaluated: [ :assoc | assoc key asString ]);
		addColumn: (SpStringTableColumn title: 'Value' evaluated: [ :assoc | assoc value ]);
		items: self argumentsRows;
		yourself.

	allowButton := self newButton
		label: 'Allow';
		icon: (self iconNamed: #smallOk);
		yourself.

	alwaysButton := self newButton
		label: 'Always Allow';
		icon: (self iconNamed: #glamorousSpawn);
		yourself.

	rememberChoiceCheckBox := self newCheckBox
		label: 'Do not ask again in this chat';
		state: false;
		yourself.

	denyButton := self newButton
		label: 'Deny';
		icon: (self iconNamed: #smallCancel);
		yourself
]

{ #category : 'initialization' }
ChatPharoToolConfirmationPresenter >> initializeWindow: aWindowPresenter [

	super initializeWindow: aWindowPresenter.
	aWindowPresenter
		title: 'ChatPharo · Confirm ', self actionLabel;
		initialExtent: 640 @ 460;
		centered
]

{ #category : 'opening' }
ChatPharoToolConfirmationPresenter >> openModalDialog [
	"Open the dialog modally and wait until the user has picked a button.
	 If the user closes the window without picking, we treat it as Deny."

	self openModal.
	decision ifNil: [
		decision := ChatPharoToolConfirmationDecision
			denyWithReason: 'The user closed the confirmation dialog without deciding.' ]
]

{ #category : 'actions' }
ChatPharoToolConfirmationPresenter >> reject [

	decision := rememberChoiceCheckBox state
		            ifTrue: [
			            ChatPharoToolConfirmationDecision
				            denyAlwaysWithReason: 'The user denied this tool and selected "do not ask again" for this chat.' ]
		            ifFalse: [
			            ChatPharoToolConfirmationDecision
				            denyWithReason: 'The user denied the tool call from the confirmation dialog.' ].
	self closeWindow
]

{ #category : 'private' }
ChatPharoToolConfirmationPresenter >> renderValue: aValue [
	"Render an argument value as a single (possibly long) String so that
	 the Spec table cell can display it. Long values are clipped to keep
	 the dialog legible."

	| limit text |
	aValue isNil ifTrue: [ ^ '(none)' ].
	aValue isString ifTrue: [
		limit := 400.
		text := aValue copyReplaceAll: String cr with: ' / '.
		text := text copyReplaceAll: String lf with: ' / '.
		text size > limit ifTrue: [
			^ (text copyFrom: 1 to: limit) , ' … (' , aValue size asString , ' chars)' ].
		^ text ].
	(aValue isKindOf: Collection) ifTrue: [
		^ '[' , (', ' join: (aValue collect: [ :e | self renderValue: e ])) , ']' ].
	^ aValue printString
]

{ #category : 'accessing' }
ChatPharoToolConfirmationPresenter >> summaryString [

	^ summaryString
]

{ #category : 'accessing' }
ChatPharoToolConfirmationPresenter >> summaryString: aString [

		summaryString := aString.
	descriptionText ifNotNil: [
		descriptionText text: (summaryString ifNil: [
			'ChatPharo wants to modify your image. Review the arguments below before authorising this call.' ]) ]
]

{ #category : 'accessing' }
ChatPharoToolConfirmationPresenter >> toolName [

	^ toolName
]

{ #category : 'accessing' }
ChatPharoToolConfirmationPresenter >> toolName: aString [

	
	toolName := aString.
	toolNameLabel ifNotNil: [ toolNameLabel label: 'tool: ', (toolName ifNil: [ '' ]) ]
]
