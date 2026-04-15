"
Core sandbox execution engine for safely evaluating AI-generated code.
Provides:
* Process-based isolation with configurable timeout
* Code validation before execution (blocks dangerous patterns)
* File system restriction
* Comprehensive error handling
Usage:
```smalltalk
ChatPharoSandbox new
    timeout: 5000;
    restrictFileSystem: true;
    evaluate: '1 + 2'.
"
Class {
	#name : 'ChatPharoSandbox',
	#superclass : 'Object',
	#instVars : [
		'timeout',
		'restrictFileSystem',
		'restrictNetwork',
		'restrictSystemAccess',
		'blockedSelectors',
		'blockedClasses',
		'lastError',
		'lastResult',
		'executionLog'
	],
	#classInstVars : [
		'defaultBlockedSelectors',
		'defaultBlockedClasses'
	],
	#category : 'AI-ChatPharo-Sandbox',
	#package : 'AI-ChatPharo-Sandbox'
}

{ #category : 'accessing' }
ChatPharoSandbox class >> defaultBlockedClasses [
	"Classes that are blocked by default for security reasons"

	^ defaultBlockedClasses ifNil: [
		  defaultBlockedClasses := Set withAll: #(
			   "File system access"
			   FileStream
			   FileReference
			   FileLocator
			   File
			   FileDirectory
			   DiskStore
			   MemoryStore
			   "Process and system control"
			   OSProcess
			   OSPlatform
			   OSEnvironment
			   ExternalProcess
			   UnixProcess
			   LibC
			   "Image and snapshot operations"
			   SmalltalkImage
			   SourceFiles
			   MCWorkingCopy
			   "Low-level operations"
			   ExternalAddress
			   ExternalData
			   FFIExternalObject
			   "Socket and network primitives"
			   Socket
			   SocketStream ) ]
]

{ #category : 'accessing' }
ChatPharoSandbox class >> defaultBlockedSelectors [
	"Selectors that are blocked by default for security reasons"

	^ defaultBlockedSelectors ifNil: [
		  defaultBlockedSelectors := Set withAll: #(
			   "File operations"
			   writeStream
			   readStream
			   binaryWriteStream
			   binaryReadStream
			   openForWrite
			   openForAppend
			   delete
			   deleteIfAbsent:
			   deleteAll
			   ensureCreateDirectory
			   copyTo:
			   moveTo:
			   renameTo:
			   "Process control"
			   terminate
			   terminateActive
			   terminateRealActive
			   suspend
			   primitiveResume
			   fork
			   forkAt:
			   forkNamed:
			   newProcess
			   "System operations"
			   snapshot
			   snapshotAndQuit
			   quitPrimitive
			   quit
			   exit
			   exit:
			   primQuitNoSave
			   "Dangerous evaluation"
			   perform:
			   perform:with:
			   perform:withArguments:
			   perform:with:with:
			   perform:with:with:with:
			   valueWithReceiver:arguments:
			   tryPrimitive:withArgs:
			   "Class manipulation"
			   removeFromSystem
			   removeFromSystemUnlogged
			   removeSelector:
			   compile:
			   compile:classified:
			   addInstVarNamed:
			   removeInstVarNamed:
			   "Global manipulation"
			   at:put:
			   removeKey:
			   removeKey:ifAbsent: ) ]
]

{ #category : 'accessing' }
ChatPharoSandbox class >> resetDefaults [
	"Reset cached default values"

	<script>
	defaultBlockedSelectors := nil.
	defaultBlockedClasses := nil
]

{ #category : 'accessing' }
ChatPharoSandbox class >> withDefaults [
	"Create a sandbox with default security settings"

	^ self new
		  useDefaults;
		  yourself
]

{ #category : 'adding' }
ChatPharoSandbox >> addBlockedClass: aClassName [
	aClassName ifNil: [ ^ self ].
	blockedClasses add: aClassName asSymbol
]

{ #category : 'adding' }
ChatPharoSandbox >> addBlockedSelector: aSelector [

aSelector ifNil: [ ^ self ].
	blockedSelectors add: aSelector asSymbol
]

{ #category : 'adding' }
ChatPharoSandbox >> blockedClasses [

	^ blockedClasses
]

{ #category : 'adding' }
ChatPharoSandbox >> blockedClasses: aCollection [

	blockedClasses := aCollection asSet
]

{ #category : 'adding' }
ChatPharoSandbox >> blockedSelectors [

	^ blockedSelectors
]

{ #category : 'adding' }
ChatPharoSandbox >> blockedSelectors: aCollection [

	blockedSelectors := aCollection asSet
]

{ #category : 'adding' }
ChatPharoSandbox >> buildSandboxedContext [
	"Build a restricted evaluation context"

	| context |
	context := Dictionary new.
	context at: #sandbox put: self.
	^ context
]

{ #category : 'adding' }
ChatPharoSandbox >> evaluate: codeString [
	"Evaluate code in the sandbox with all security measures applied.
	Returns a ChatPharoSandboxResult with success/failure and details."

	| validationResult |
	lastError := nil.
	lastResult := nil.
	executionLog := OrderedCollection new.

	self log: 'Starting sandbox evaluation'.

	"Step 1: Validate code before execution"
	validationResult := self validateCode: codeString.
	validationResult isValid ifFalse: [
		self log: 'Validation failed: ' , validationResult errorMessage.
		^ ChatPharoSandboxResult
			  failure: validationResult errorMessage
			  violations: validationResult violations ].

	self log: 'Validation passed, executing code'.

	"Step 2: Execute with timeout and error handling"
	^ self executeWithProtection: codeString
]

{ #category : 'adding' }
ChatPharoSandbox >> executeWithProtection: codeString [
	"Execute code with timeout and comprehensive error handling"

	| result semaphore process completed timeoutMs |
	completed := false.
	semaphore := Semaphore new.
	timeoutMs := timeout ifNil: [ 5000 ].

	process := [
	            [
	            result := Smalltalk compiler evaluate: codeString.
	            lastResult := result.
	            completed := true ]
		            on: Error
		            do: [ :error |
			            lastError := error messageText.
			            self log: 'Execution error: ' , lastError.
			            completed := true ].
	            semaphore signal ] newProcess.

	process priority: Processor userBackgroundPriority.
	process resume.

	"Wait with timeout"
	(semaphore waitTimeoutMilliseconds: timeoutMs) ifTrue: [
		process terminate.
		self log: 'Execution timed out after ' , timeoutMs asString , 'ms'.
		^ ChatPharoSandboxResult
			  failure: 'Execution timed out after ' , timeoutMs asString , 'ms'
			  violations: #(  ) ].

	completed ifFalse: [
		process isTerminated ifFalse: [ process terminate ].
		^ ChatPharoSandboxResult
			  failure: 'Execution did not complete'
			  violations: #(  ) ].

	lastError ifNotNil: [
		^ ChatPharoSandboxResult
			  failure: lastError
			  violations: #(  ) ].

	self log: 'Execution completed successfully'.
	^ ChatPharoSandboxResult success: lastResult
]

{ #category : 'adding' }
ChatPharoSandbox >> executionLog [

	^ executionLog
]

{ #category : 'adding' }
ChatPharoSandbox >> initialize [

	super initialize.
	timeout := 5000. "5 seconds default"
	restrictFileSystem := true.
	restrictNetwork := true.
	restrictSystemAccess := true.
	blockedSelectors := Set new.
	blockedClasses := Set new.
	executionLog := OrderedCollection new
]

{ #category : 'adding' }
ChatPharoSandbox >> lastError [

	^ lastError
]

{ #category : 'adding' }
ChatPharoSandbox >> lastResult [

	^ lastResult
]

{ #category : 'adding' }
ChatPharoSandbox >> log: aMessage [
	"Add a message to the execution log"

	executionLog add: (DateAndTime now asString , ': ' , aMessage)
]

{ #category : 'adding' }
ChatPharoSandbox >> restrictFileSystem [

	^ restrictFileSystem
]

{ #category : 'adding' }
ChatPharoSandbox >> restrictFileSystem: aBoolean [

	restrictFileSystem := aBoolean
]

{ #category : 'adding' }
ChatPharoSandbox >> restrictNetwork [

	^ restrictNetwork
]

{ #category : 'adding' }
ChatPharoSandbox >> restrictNetwork: aBoolean [

	restrictNetwork := aBoolean
]

{ #category : 'adding' }
ChatPharoSandbox >> restrictSystemAccess [

	^ restrictSystemAccess
]

{ #category : 'adding' }
ChatPharoSandbox >> restrictSystemAccess: aBoolean [

	restrictSystemAccess := aBoolean
]

{ #category : 'adding' }
ChatPharoSandbox >> timeout [

	^ timeout
]

{ #category : 'adding' }
ChatPharoSandbox >> timeout: milliseconds [

	timeout := milliseconds
]

{ #category : 'adding' }
ChatPharoSandbox >> useDefaults [
	"Apply default security settings"

	blockedSelectors := self class defaultBlockedSelectors copy.
	blockedClasses := self class defaultBlockedClasses copy
]

{ #category : 'adding' }
ChatPharoSandbox >> validateCode: codeString [
	"Validate code for dangerous patterns before execution.
	Returns a ChatPharoSandboxValidation with isValid and violations."

	| violations ast |
	violations := OrderedCollection new.

	"First check syntax"
	[
	ast := OCParser parseExpression: codeString ]
		on: OCCodeError
		do: [ :error |
			^ ChatPharoSandboxValidation
				  invalid: ('Syntax error at position {1}: {2}' format: {
							   error position.
							   error messageText })
				  violations: { 'syntax_error' } ].

	"Check for blocked class references"
	blockedClasses do: [ :className |
		(codeString includesSubstring: className asString) ifTrue: [
			violations add:
				('Blocked class reference: ' , className asString) ] ].

	"Check for blocked selectors (simple substring check)"
	blockedSelectors do: [ :selector |
		(codeString includesSubstring: selector asString) ifTrue: [
			violations add: ('Blocked selector: ' , selector asString) ] ].

	"File system restrictions"
	(restrictFileSystem and: [
		 (codeString includesSubstring: 'FileReference') or: [
			 (codeString includesSubstring: 'FileLocator') or: [
				 (codeString includesSubstring: 'FileStream') or: [
					 codeString includesSubstring: 'File ' ] ] ] ]) ifTrue: [
		violations add: 'File system access is restricted' ].

	"Network restrictions"
	(restrictNetwork and: [
		 (codeString includesSubstring: 'ZnClient') or: [
			 (codeString includesSubstring: 'Socket') or: [
				 codeString includesSubstring: 'ZnUrl' ] ] ]) ifTrue: [
		violations add: 'Network access is restricted' ].

	"System access restrictions"
	(restrictSystemAccess and: [
		 (codeString includesSubstring: 'Smalltalk snapshot') or: [
			 (codeString includesSubstring: 'Smalltalk quit') or: [
				 (codeString includesSubstring: 'SmalltalkImage') or: [
					 (codeString includesSubstring: 'Processor ') or: [
						 codeString includesSubstring: 'OSProcess' ] ] ] ] ]) ifTrue: [
		violations add: 'System-level access is restricted' ].

	violations isEmpty
		ifTrue: [ ^ ChatPharoSandboxValidation valid ]
		ifFalse: [
			^ ChatPharoSandboxValidation
				  invalid: ('Security violations found: ' , violations first)
				  violations: violations asArray ]
]
