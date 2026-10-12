"
I give the model the code navigation a Pharo developer uses all day:
senders, implementors, references to a class, one method's source, class name
search, and running tests.

Without me a model can only read whole classes or grep method sources, which
neither scales nor answers ""who calls this?"".

Results are capped (`resultLimit`) and say when they were truncated, so one
query on `#printOn:` cannot flood the conversation.
"
Class {
	#name : 'ChatPharoNavigationTools',
	#superclass : 'ChatPharoToolProvider',
	#category : 'AI-ChatPharo-Tools-System Browser',
	#package : 'AI-ChatPharo-Tools',
	#tag : 'System Browser'
}

{ #category : 'private' }
ChatPharoNavigationTools >> classNamed: aName [

	^ self class environment at: aName asSymbol ifAbsent: [ nil ]
]

{ #category : 'private' }
ChatPharoNavigationTools >> describeMethod: aMethod [

	^ Dictionary new
		  at: 'class' put: aMethod methodClass instanceSide name;
		  at: 'side' put: (self sideOf: aMethod methodClass);
		  at: 'selector' put: aMethod selector;
		  at: 'protocol' put: aMethod protocolName;
		  at: 'package' put: aMethod package name;
		  yourself
]

{ #category : 'private' }
ChatPharoNavigationTools >> describeMethods: methods under: aKey [
	"Answer the capped, sorted description of methods, saying how many there really are."

	| sorted |
	sorted := methods asArray sorted: [ :a :b | a name <= b name ].
	^ Dictionary new
		  at: aKey put: ((sorted first: (self resultLimit min: sorted size)) collect: [ :each | self describeMethod: each ]);
		  at: 'count' put: sorted size;
		  at: 'truncated' put: sorted size > self resultLimit;
		  yourself
]

{ #category : 'tools' }
ChatPharoNavigationTools >> findClassReferencesTool [

	^ self
		  toolNamed: 'find_class_references'
		  description: 'Finds the methods that refer to a class by name. Use it before renaming or removing a class, or to learn how a class is used.'
		  properties: (Dictionary with: 'class_name' -> (self property: 'string' description: 'Name of the class'))
		  required: #( 'class_name' )
		  do: [ :arguments | self referencesToClassNamed: (arguments at: 'class_name') ]
]

{ #category : 'tools' }
ChatPharoNavigationTools >> findClassesTool [

	^ self
		  toolNamed: 'find_classes'
		  description: 'Finds classes whose name contains the given text, ignoring case. Answers each class with its package.'
		  properties: (Dictionary with: 'name_part' -> (self property: 'string' description: 'Text the class name must contain'))
		  required: #( 'name_part' )
		  do: [ :arguments | self classesMatching: (arguments at: 'name_part') ]
]

{ #category : 'tools' }
ChatPharoNavigationTools >> findImplementorsTool [

	^ self
		  toolNamed: 'find_implementors'
		  description: 'Finds all the methods that implement a selector (the "implementors"), in every class of the image.'
		  properties: (Dictionary with: 'selector' -> (self property: 'string' description: 'The selector, for example printOn: or at:put:'))
		  required: #( 'selector' )
		  do: [ :arguments | self implementorsOf: (arguments at: 'selector') ]
]

{ #category : 'tools' }
ChatPharoNavigationTools >> findSendersTool [

	^ self
		  toolNamed: 'find_senders'
		  description: 'Finds all the methods that send a selector (the "senders"). Use it to see who calls a method before changing or removing it.'
		  properties: (Dictionary with: 'selector' -> (self property: 'string' description: 'The selector, for example printOn: or at:put:'))
		  required: #( 'selector' )
		  do: [ :arguments | self sendersOf: (arguments at: 'selector') ]
]

{ #category : 'tools' }
ChatPharoNavigationTools >> getMethodSourceTool [

	^ self
		  toolNamed: 'get_method_source'
		  description: 'Gets the source code of one method. Cheaper than reading the whole class.'
		  properties: (Dictionary
				   with: 'class_name' -> (self property: 'string' description: 'Name of the class')
				   with: 'selector' -> (self property: 'string' description: 'Selector of the method')
				   with: 'side' -> (self property: 'string' description: '"instance" (default) or "class"'))
		  required: #( 'class_name' 'selector' )
		  do: [ :arguments |
			  self
				  sourceOf: (arguments at: 'selector')
				  inClassNamed: (arguments at: 'class_name')
				  side: (arguments at: 'side' ifAbsent: [ 'instance' ]) ]
]

{ #category : 'tools' }
ChatPharoNavigationTools >> runTestsTool [

	^ (self
		   toolNamed: 'run_tests'
		   description: 'Runs the SUnit tests of a test class, or of every test class in a package, and answers the counts with the failing and erroring tests. Use it to verify a change.'
		   properties: (Dictionary
				    with: 'class_name' -> (self property: 'string' description: 'A TestCase subclass to run')
				    with: 'package' -> (self property: 'string' description: 'A package whose test classes are all run'))
		   required: #(  )
		   do: [ :arguments | self runTestsFor: arguments ])
		  beMutating;
		  yourself
]

{ #category : 'private' }
ChatPharoNavigationTools >> classesMatching: aString [

	| matches |
	matches := (self class environment allClasses select: [ :each | each name includesSubstring: aString caseSensitive: false ])
		           sorted: [ :a :b | a name <= b name ].
	^ Dictionary new
		  at: 'classes' put: ((matches first: (self resultLimit min: matches size)) collect: [ :each |
					   Dictionary with: 'class' -> each name with: 'package' -> each package name ]);
		  at: 'count' put: matches size;
		  at: 'truncated' put: matches size > self resultLimit;
		  yourself
]

{ #category : 'private' }
ChatPharoNavigationTools >> implementorsOf: aSelector [

	^ self describeMethods: (SystemNavigation default allImplementorsOf: aSelector asSymbol) under: 'implementors'
]

{ #category : 'private' }
ChatPharoNavigationTools >> referencesToClassNamed: aName [

	^ (self classNamed: aName)
		  ifNil: [ self unknownClass: aName ]
		  ifNotNil: [ :class | self describeMethods: class usingMethods under: 'references' ]
]

{ #category : 'accessing' }
ChatPharoNavigationTools >> resultLimit [

	^ 100
]

{ #category : 'private' }
ChatPharoNavigationTools >> runTestsFor: arguments [

	| suite |
	suite := self testSuiteFor: arguments.
	suite ifNil: [ ^ Dictionary with: 'error' -> 'Give the class_name of a TestCase subclass or a package that contains test classes.' ].
	^ self summarize: suite run
]

{ #category : 'private' }
ChatPharoNavigationTools >> sendersOf: aSelector [

	^ self describeMethods: (SystemNavigation default allSendersOf: aSelector asSymbol) under: 'senders'
]

{ #category : 'private' }
ChatPharoNavigationTools >> sideOf: aClass [

	^ aClass isInstanceSide
		  ifTrue: [ 'instance' ]
		  ifFalse: [ 'class' ]
]

{ #category : 'private' }
ChatPharoNavigationTools >> sourceOf: aSelector inClassNamed: aName side: aSide [

	| class |
	class := self classNamed: aName.
	class ifNil: [ ^ self unknownClass: aName ].
	aSide = 'class' ifTrue: [ class := class classSide ].
	^ class
		  compiledMethodAt: aSelector asSymbol
		  ifPresent: [ :method | (self describeMethod: method) at: 'source' put: method sourceCode; yourself ]
		  ifAbsent: [ Dictionary with: 'error' -> (class name , ' does not implement ' , aSelector) ]
]

{ #category : 'private' }
ChatPharoNavigationTools >> summarize: aTestResult [

	^ Dictionary new
		  at: 'run' put: aTestResult runCount;
		  at: 'passed' put: aTestResult passedCount;
		  at: 'failures' put: (aTestResult failures collect: [ :each | each printString ]) asArray;
		  at: 'errors' put: (aTestResult errors collect: [ :each | each printString ]) asArray;
		  at: 'all_passed' put: aTestResult hasPassed;
		  yourself
]

{ #category : 'accessing' }
ChatPharoNavigationTools >> summary [

	^ 'Senders, implementors, class references, single method source, class search and test runs.'
]

{ #category : 'private' }
ChatPharoNavigationTools >> testClassesInPackageNamed: aName [

	^ (self class packageOrganizer packageNamed: aName ifAbsent: [ ^ #(  ) ]) definedClasses select: [ :each |
		  each isTestCase and: [ each isAbstract not ] ]
]

{ #category : 'private' }
ChatPharoNavigationTools >> testSuiteFor: arguments [
	"Answer the suite the arguments designate, or nil when they designate no test."

	| classes suite |
	classes := OrderedCollection new.
	arguments at: 'class_name' ifPresent: [ :name |
		(self classNamed: name) ifNotNil: [ :class | class isTestCase ifTrue: [ classes add: class ] ] ].
	arguments at: 'package' ifPresent: [ :name | classes addAll: (self testClassesInPackageNamed: name) ].
	classes ifEmpty: [ ^ nil ].
	suite := TestSuite named: 'ChatPharo run_tests'.
	classes do: [ :each | suite addTests: each buildSuite tests ].
	^ suite
]

{ #category : 'accessing' }
ChatPharoNavigationTools >> title [

	^ 'Code navigation'
]

{ #category : 'accessing' }
ChatPharoNavigationTools >> tools [

	^ {
		  self findSendersTool.
		  self findImplementorsTool.
		  self findClassReferencesTool.
		  self findClassesTool.
		  self getMethodSourceTool.
		  self runTestsTool }
]

{ #category : 'private' }
ChatPharoNavigationTools >> unknownClass: aName [

	^ Dictionary with: 'error' -> ('There is no class named ' , aName)
]
