Class {
	#name : 'ChatPharoNavigationToolsTest',
	#superclass : 'TestCase',
	#instVars : [
		'tools'
	],
	#category : 'AI-ChatPharo-Tests-Tools',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
ChatPharoNavigationToolsTest >> call: aToolName with: arguments [

	^ (tools tools detect: [ :each | each name = aToolName ]) applyTo: arguments
]

{ #category : 'running' }
ChatPharoNavigationToolsTest >> setUp [

	super setUp.
	tools := ChatPharoNavigationTools new
]

{ #category : 'tests' }
ChatPharoNavigationToolsTest >> testFindClassReferences [

	| result |
	result := self call: 'find_class_references' with: (Dictionary with: 'class_name' -> 'ChatPharoNavigationTools').
	self assert: ((result at: 'references') anySatisfy: [ :each | (each at: 'class') = self class name ])
]

{ #category : 'tests' }
ChatPharoNavigationToolsTest >> testFindClassesIgnoresCase [

	| result |
	result := self call: 'find_classes' with: (Dictionary with: 'name_part' -> 'chatpharonavigationtools').
	self assert: ((result at: 'classes') collect: [ :each | each at: 'class' ]) asArray equals: #( #ChatPharoNavigationTools #ChatPharoNavigationToolsTest )
]

{ #category : 'tests' }
ChatPharoNavigationToolsTest >> testFindImplementors [

	| result |
	result := self call: 'find_implementors' with: (Dictionary with: 'selector' -> 'findSendersTool').
	self assert: (result at: 'count') equals: 1.
	self assert: ((result at: 'implementors') first at: 'class') equals: #ChatPharoNavigationTools.
	self assert: ((result at: 'implementors') first at: 'side') equals: 'instance'
]

{ #category : 'tests' }
ChatPharoNavigationToolsTest >> testFindSenders [

	| result |
	result := self call: 'find_senders' with: (Dictionary with: 'selector' -> 'findSendersTool').
	self assert: ((result at: 'senders') anySatisfy: [ :each |
			 (each at: 'class') = #ChatPharoNavigationTools and: [ (each at: 'selector') = #tools ] ]).
	self deny: (result at: 'truncated')
]

{ #category : 'tests' }
ChatPharoNavigationToolsTest >> testGetMethodSourceOfClassSideMethod [

	| result |
	result := self call: 'get_method_source' with: (Dictionary
			           with: 'class_name' -> 'ChatPharoToolProvider'
			           with: 'selector' -> 'allTools'
			           with: 'side' -> 'class').
	self assert: ((result at: 'source') beginsWith: 'allTools').
	self assert: (result at: 'side') equals: 'class'
]

{ #category : 'tests' }
ChatPharoNavigationToolsTest >> testLargeResultIsCappedAndSaysSo [

	| result |
	result := self call: 'find_implementors' with: (Dictionary with: 'selector' -> 'initialize').
	self assert: (result at: 'implementors') size equals: tools resultLimit.
	self assert: (result at: 'truncated').
	self assert: (result at: 'count') > tools resultLimit
]

{ #category : 'tests' }
ChatPharoNavigationToolsTest >> testNavigationToolsAreOfferedToTheModel [

	| names |
	names := ChatPharoToolbox new builtInTools collect: [ :each | each name ].
	#( 'find_senders' 'find_implementors' 'find_class_references' 'get_method_source' 'run_tests' ) do: [ :each |
		self assert: (names includes: each) ]
]

{ #category : 'tests' }
ChatPharoNavigationToolsTest >> testRunTestsReportsCounts [

	| result |
	result := self call: 'run_tests' with: (Dictionary with: 'class_name' -> 'ChatPharoReasoningExtractionTest').
	self assert: (result at: 'all_passed').
	self assert: (result at: 'run') equals: ChatPharoReasoningExtractionTest testSelectors size
]

{ #category : 'tests' }
ChatPharoNavigationToolsTest >> testRunTestsWithoutATestIsAnError [

	self assert: ((self call: 'run_tests' with: (Dictionary with: 'class_name' -> 'Object')) includesKey: 'error')
]

{ #category : 'tests' }
ChatPharoNavigationToolsTest >> testUnknownClassIsReported [

	self assert: ((self call: 'find_class_references' with: (Dictionary with: 'class_name' -> 'NoSuchClassAnywhere')) includesKey: 'error')
]
