Class {
	#name : 'ChatPharoSandboxTest',
	#superclass : 'TestCase',
	#instVars : [
		'sandbox'
	],
	#category : 'AI-ChatPharo-Tests-Sandbox',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Sandbox'
}

{ #category : 'running' }
ChatPharoSandboxTest >> setUp [

	super setUp.
	sandbox := ChatPharoSandbox new
]

{ #category : 'running' }
ChatPharoSandboxTest >> testAddBlockedClassAddsSymbol [

	sandbox addBlockedClass: 'EvilClass'.
	self assert: (sandbox blockedClasses includes: #EvilClass)
]

{ #category : 'running' }
ChatPharoSandboxTest >> testAddBlockedSelectorAddsSymbol [

	sandbox addBlockedSelector: 'dangerous:'.
	self assert: (sandbox blockedSelectors includes: #dangerous:)
]

{ #category : 'running' }
ChatPharoSandboxTest >> testBlockedClassesSetterUsesSet [

	sandbox blockedClasses: #(FileStream FileStream).
	self assert: sandbox blockedClasses size equals: 1
]

{ #category : 'running' }
ChatPharoSandboxTest >> testBlockedSelectorsSetterUsesSet [

	sandbox blockedSelectors: #(perform: perform:).
	self assert: sandbox blockedSelectors size equals: 1
]

{ #category : 'running' }
ChatPharoSandboxTest >> testEvaluateFailureForRuntimeError [

	| result |
	sandbox restrictFileSystem: false.
	sandbox restrictNetwork: false.
	sandbox restrictSystemAccess: false.
	result := sandbox evaluate: '1 / 0'.
	self assert: result isFailure.
	self assert: sandbox lastError notNil
]

{ #category : 'running' }
ChatPharoSandboxTest >> testEvaluateFailureForValidationViolation [

	| result |
	result := sandbox evaluate: 'FileReference new'.
	self assert: result isFailure.
	self assert: result hasViolations
]

{ #category : 'running' }
ChatPharoSandboxTest >> testEvaluateSuccessReturnsResult [

	| result |
	sandbox restrictFileSystem: false.
	sandbox restrictNetwork: false.
	sandbox restrictSystemAccess: false.
	result := sandbox evaluate: '1 + 2'.
	self assert: result isSuccess.
	self assert: result value equals: 3
]

{ #category : 'running' }
ChatPharoSandboxTest >> testExecutionLogRecordsMessages [

	sandbox restrictFileSystem: false.
	sandbox restrictNetwork: false.
	sandbox restrictSystemAccess: false.
	sandbox evaluate: '1 + 2'.
	self assert: (sandbox executionLog anySatisfy: [ :entry | entry includesSubstring: 'Starting sandbox evaluation' ]).
	self assert: (sandbox executionLog anySatisfy: [ :entry | entry includesSubstring: 'Execution completed successfully' ])
]

{ #category : 'running' }
ChatPharoSandboxTest >> testInitializeDefaults [

	self assert: sandbox timeout equals: 5000.
	self assert: sandbox restrictFileSystem.
	self assert: sandbox restrictNetwork.
	self assert: sandbox restrictSystemAccess
]

{ #category : 'running' }
ChatPharoSandboxTest >> testTimeoutReturnsFailure [

	| result |
	sandbox restrictFileSystem: false.
	sandbox restrictNetwork: false.
	sandbox restrictSystemAccess: false.
	sandbox timeout: 1.
	result := sandbox evaluate: '(Delay forMilliseconds: 50) wait'.
	self assert: result isFailure.
	self assert: (result errorMessage includesSubstring: 'Execution timed out')
]

{ #category : 'running' }
ChatPharoSandboxTest >> testUseDefaultsCopiesBlockedLists [

	sandbox useDefaults.
	self assert: (sandbox blockedClasses includes: #FileStream).
	self assert: (sandbox blockedSelectors includes: #writeStream)
]

{ #category : 'tests' }
ChatPharoSandboxTest >> testValidateCodeAllowsProcessorScheduler [

	| validation |
	validation := sandbox validateCode: 'ProcessorScheduler active priority'.
	self assert: validation isValid
]

{ #category : 'running' }
ChatPharoSandboxTest >> testValidateCodeDetectsBlockedClassReference [

	| validation |
	sandbox blockedClasses: #(EvilClass).
	validation := sandbox validateCode: 'EvilClass new'.
	self assert: validation isInvalid.
	self assert: (validation violations anySatisfy: [ :v | v includesSubstring: 'EvilClass' ])
]

{ #category : 'running' }
ChatPharoSandboxTest >> testValidateCodeDetectsBlockedSelector [

	| validation |
	sandbox blockedSelectors: #(dangerous:).
	validation := sandbox validateCode: 'Object new dangerous: 1'.
	self assert: validation isInvalid.
	self assert: (validation violations anySatisfy: [ :v | v includesSubstring: 'dangerous:' ])
]

{ #category : 'tests' }
ChatPharoSandboxTest >> testValidateCodeDetectsDirectProcessorAccess [

	| validation |
	validation := sandbox validateCode: 'Processor activeProcess terminate'.
	self assert: validation isInvalid
]

{ #category : 'running' }
ChatPharoSandboxTest >> testValidateCodeDetectsFileSystemRestriction [

	| validation |
	validation := sandbox validateCode: 'FileReference new'.
	self assert: validation isInvalid.
	self assert: (validation violations includes: 'File system access is restricted')
]

{ #category : 'running' }
ChatPharoSandboxTest >> testValidateCodeDetectsNetworkRestriction [

	| validation |
	validation := sandbox validateCode: 'ZnClient new'.
	self assert: validation isInvalid.
	self assert: (validation violations includes: 'Network access is restricted')
]

{ #category : 'running' }
ChatPharoSandboxTest >> testValidateCodeDetectsSyntaxError [

	| validation |
	validation := sandbox validateCode: '1 +'.
	self assert: validation isInvalid.
	self assert: (validation violations includes: 'syntax_error')
]

{ #category : 'running' }
ChatPharoSandboxTest >> testValidateCodeDetectsSystemRestriction [

	| validation |
	validation := sandbox validateCode: 'Smalltalk snapshot'.
	self assert: validation isInvalid.
	self assert: (validation violations includes: 'System-level access is restricted')
]

{ #category : 'running' }
ChatPharoSandboxTest >> testValidateCodeReturnsValidForSimpleExpression [

	| validation |
	sandbox restrictFileSystem: false.
	sandbox restrictNetwork: false.
	sandbox restrictSystemAccess: false.
	validation := sandbox validateCode: '1 + 2'.
	self assert: validation isValid
]

{ #category : 'running' }
ChatPharoSandboxTest >> testValidateCodeSkipsFileSystemRestrictionWhenDisabled [

	| validation |
	sandbox restrictFileSystem: false.
	validation := sandbox validateCode: 'FileReference new'.
	self deny: (validation violations includes: 'File system access is restricted')
]

{ #category : 'running' }
ChatPharoSandboxTest >> testValidateCodeSkipsNetworkRestrictionWhenDisabled [

	| validation |
	sandbox restrictNetwork: false.
	validation := sandbox validateCode: 'ZnClient new'.
	self deny: (validation violations includes: 'Network access is restricted')
]

{ #category : 'running' }
ChatPharoSandboxTest >> testValidateCodeSkipsSystemRestrictionWhenDisabled [

	| validation |
	sandbox restrictSystemAccess: false.
	validation := sandbox validateCode: 'Smalltalk snapshot'.
	self deny: (validation violations includes: 'System-level access is restricted')
]
