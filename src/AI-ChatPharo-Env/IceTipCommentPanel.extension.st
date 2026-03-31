Extension { #name : 'IceTipCommentPanel' }

{ #category : '*AI-ChatPharo-Env' }
IceTipCommentPanel >> chatpharo [

	self inform: 'chatpharo'
]

{ #category : '*AI-ChatPharo-Env' }
IceTipCommentPanel >> initializePresenters [

	| fixesHelpString |
	pushCheckbox := self newCheckBox.

	optionsButton := self newToolbar
		displayMode: self application toolbarDisplayMode;
		add: (self newToolbarToggleButton
			icon: (self application iconNamed: #smallSave);
			label: 'Save image';
			help: 'Save image when committing';
			state: self isSaving;
			whenChangedDo: [ :aBoolean |
				self saveOnCommit: aBoolean ];
			yourself);
		add: (self newToolbarToggleButton
			icon: (self application iconNamed: #smallError);
			label: 'Run critics';
			help: 'Run critics when committing';
			state: self isRunningCriticsOnCommit;
			whenChangedDo: [ :aBoolean |
				self runCriticsOnCommit: aBoolean ];
			yourself);
		add: (self newToolbarButton
			icon: ChatPharoIcons chatPharoIcon;
			label: 'ChatPharo';
			help: 'ask ChatPharo to generate';
			action: [ self chatpharo ];
			yourself);
		yourself.

	self repositoryModel branchModel hasUpstream
		ifTrue: [
			pushCheckbox
				label: ('Push changes to {1}' format: { self repositoryRemoteName });
				state: self isPushing;
				whenChangedDo: [ :state | self pushOnCommit: state ] ]
		ifFalse: [
			pushCheckbox
				label: 'Cannot push new branch automatically. Use the `Push` option';
				enabled: false ].

	commentText := self newText
		text:
			String cr ,
			'# Please enter the commit message for your changes.
# Lines starting with # will be ignored, and an empty message aborts the commit.
# On branch ' , repositoryModel branchName , ', Fixes #
#Please use one of those
#feat:
#fix:
#refactor:
#chore:
#comment:';
		yourself.

	fixesHelpString := 'Enter the number of the issue that you fixed. Github will close it when it will be committed or merged in the default branch'.
	fixesLabel := self newLabel
		label: 'Fixes #';
		help: fixesHelpString;
		yourself.

	fixesField := self newNumberInput
		help: fixesHelpString;
		placeholder: 'issue number';
		beInteger;
		yourself.

	actionButtonBar := self newButtonBar.
	actionButtonBar add: (commitButton := self newButton
		label: 'Commit';
		icon: (self iconNamed: #smallOk);
		help: ('Commit your changes to {1}' format: { self repositoryName });
		yourself)
]
