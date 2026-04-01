"
Presenter for configuring ChatPharo sandbox security settings.

Provides controls to:
* Enable/disable sandbox mode.
* Configure sandbox timeout.
* Toggle file system, network, and system access restrictions.
* Run a quick sandbox self-test and display status/results.
"
Class {
	#name : 'ChatPharoSecuritySettingsPresenter',
	#superclass : 'SpPresenter',
	#instVars : [
		'model',
		'sandboxEnabledCheckBox',
		'timeoutInput',
		'restrictFileSystemCheckBox',
		'restrictNetworkCheckBox',
		'restrictSystemAccessCheckBox',
		'testButton',
		'testResultText',
		'statusLabel'
	],
	#category : 'AI-ChatPharo-Spec-Core',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Core'
}

{ #category : 'layout' }
ChatPharoSecuritySettingsPresenter >> connectPresenters [

	sandboxEnabledCheckBox whenChangedDo: [ :state |
		model sandboxEnabled: state.
		self updateStatus ].

	timeoutInput whenNumberChangedDo: [ :number |
		number ifNotNil: [ model sandboxTimeout: number asInteger ] ].

	restrictFileSystemCheckBox whenChangedDo: [ :state |
		state ifFalse: [
			(self confirm:
				 'Disabling file system restrictions allows AI-generated code to read/write files. Continue?')
				ifFalse: [
					restrictFileSystemCheckBox state: true.
					^ self ] ].
		model sandboxRestrictFileSystem: state ].

	restrictNetworkCheckBox whenChangedDo: [ :state |
		state ifFalse: [
			(self confirm:
				 'Disabling network restrictions allows AI-generated code to make network requests. Continue?')
				ifFalse: [
					restrictNetworkCheckBox state: true.
					^ self ] ].
		model sandboxRestrictNetwork: state ].

	restrictSystemAccessCheckBox whenChangedDo: [ :state |
		state ifFalse: [
			(self confirm:
				 'Disabling system access restrictions allows AI-generated code to perform dangerous operations. Continue?')
				ifFalse: [
					restrictSystemAccessCheckBox state: true.
					^ self ] ].
		model sandboxRestrictSystemAccess: state ].

	testButton action: [ self runSandboxTest ]
]

{ #category : 'layout' }
ChatPharoSecuritySettingsPresenter >> defaultLayout [

	^ SpBoxLayout newTopToBottom
		  spacing: 10;
		  add: (SpBoxLayout newHorizontal
				   add: (self newLabel label: 'Sandbox Security Settings')
				   yourself)
		  expand: false;
		  add: self sandboxSection expand: false;
		  add: self restrictionsSection expand: false;
		  add: self testSection;
		  yourself
]

{ #category : 'layout' }
ChatPharoSecuritySettingsPresenter >> initializePresenters [ 

	super initializePresenters.

	"Sandbox enable checkbox"
	sandboxEnabledCheckBox := self newCheckBox
		                          label: 'Enable Sandbox Mode';
		                          state: model sandboxEnabled;
		                          yourself.

	"Timeout input"
	timeoutInput := self newNumberInput
		                placeholder: 'Timeout in ms (e.g. 5000)';
		                number: model sandboxTimeout;
		                minimum: 100;
		                maximum: 60000;
		                yourself.

	"Restriction checkboxes"
	restrictFileSystemCheckBox := self newCheckBox
		                             label: 'Restrict File System Access';
		                             state: model sandboxRestrictFileSystem;
		                             yourself.

	restrictNetworkCheckBox := self newCheckBox
		                          label: 'Restrict Network Access';
		                          state: model sandboxRestrictNetwork;
		                          yourself.

	restrictSystemAccessCheckBox := self newCheckBox
		                               label:
			                               'Restrict System Access (snapshots, quit, etc.)';
		                               state: model sandboxRestrictSystemAccess;
		                               yourself.

	"Test button and result"
	testButton := self newButton
		              label: 'Test Sandbox';
		              icon: (self iconNamed: #smallDoIt);
		              yourself.

	testResultText := self newText
		                  beNotEditable;
		                  yourself.

	statusLabel := self newLabel label: 'Sandbox Status: Ready'.

	self connectPresenters
]

{ #category : 'layout' }
ChatPharoSecuritySettingsPresenter >> restrictionsSection [

	^ SpBoxLayout newTopToBottom
		  spacing: 5;
		  add: (self newLabel label: 'Security Restrictions:') expand: false;
		  add: restrictFileSystemCheckBox expand: false;
		  add: restrictNetworkCheckBox expand: false;
		  add: restrictSystemAccessCheckBox expand: false;
		  yourself
]

{ #category : 'layout' }
ChatPharoSecuritySettingsPresenter >> runSandboxTest [
	"Run a series of tests to verify sandbox functionality"

	| results sandbox |
	results := String streamContents: [ :stream |
		           stream nextPutAll: '=== Sandbox Test Results ==='.
		           stream cr.
		           stream cr.

		           "Test 1: Basic evaluation"
		           stream nextPutAll: '1. Basic evaluation test: '.
		           sandbox := model newConfiguredSandbox.
		           (sandbox evaluate: '1 + 2') isSuccess
			           ifTrue: [
				           stream
					           nextPutAll: 'PASSED';
					           cr ]
			           ifFalse: [
				           stream
					           nextPutAll: 'FAILED';
					           cr ].

		           "Test 2: Timeout test"
		           stream nextPutAll: '2. Timeout test (should timeout): '.
		           sandbox := model newConfiguredSandbox.
		           sandbox timeout: 100.
		           (sandbox evaluate: '[ true ] whileTrue: []') isFailure
			           ifTrue: [
				           stream
					           nextPutAll: 'PASSED (timed out as expected)';
					           cr ]
			           ifFalse: [
				           stream
					           nextPutAll: 'FAILED (did not timeout)';
					           cr ].

		           "Test 3: File system restriction"
		           model sandboxRestrictFileSystem ifTrue: [
			           stream nextPutAll: '3. File system restriction: '.
			           sandbox := model newConfiguredSandbox.
			           (sandbox evaluate: 'FileReference') isFailure
				           ifTrue: [
					           stream
						           nextPutAll: 'PASSED (blocked)';
						           cr ]
				           ifFalse: [
					           stream
						           nextPutAll: 'WARNING (not blocked at validation)';
						           cr ] ].

		           "Test 4: Error handling"
		           stream nextPutAll: '4. Error handling test: '.
		           sandbox := model newConfiguredSandbox.
		           (sandbox evaluate: '1 / 0') isFailure
			           ifTrue: [
				           stream
					           nextPutAll: 'PASSED (error caught)';
					           cr ]
			           ifFalse: [
				           stream
					           nextPutAll: 'FAILED';
					           cr ].

		           "Test 5: Syntax error"
		           stream nextPutAll: '5. Syntax error detection: '.
		           sandbox := model newConfiguredSandbox.
		           (sandbox evaluate: '1 +') isFailure
			           ifTrue: [
				           stream
					           nextPutAll: 'PASSED (syntax error caught)';
					           cr ]
			           ifFalse: [
				           stream
					           nextPutAll: 'FAILED';
					           cr ].

		           stream cr.
		           stream nextPutAll: '=== Test Complete ===' ].

	testResultText text: results.
	self updateStatus
]

{ #category : 'layout' }
ChatPharoSecuritySettingsPresenter >> sandboxSection [

	^ SpBoxLayout newTopToBottom
		  spacing: 5;
		  add: sandboxEnabledCheckBox expand: false;
		  add: (SpBoxLayout newHorizontal
				   spacing: 8;
				   add: 'Timeout (ms):' expand: false;
				   add: timeoutInput;
				   yourself)
		  expand: false;
		  add: statusLabel expand: false;
		  yourself
]

{ #category : 'layout' }
ChatPharoSecuritySettingsPresenter >> setModelBeforeInitialization: anObject [

	model := anObject
]

{ #category : 'layout' }
ChatPharoSecuritySettingsPresenter >> testSection [

	^ SpBoxLayout newTopToBottom
		  spacing: 5;
		  add: (SpBoxLayout newHorizontal
				   add: testButton expand: false;
				   yourself)
		  expand: false;
		  add: testResultText;
		  yourself
]

{ #category : 'layout' }
ChatPharoSecuritySettingsPresenter >> updateStatus [

	| status |
	status := model sandboxEnabled
		          ifTrue: [ 'Sandbox Status: ENABLED (Protected)' ]
		          ifFalse: [ 'Sandbox Status: DISABLED (Unrestricted)' ].
	statusLabel label: status
]
