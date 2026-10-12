"
Bridges the **running Pharo image itself** to the LLM via function calling.

* Wraps a *Refactoring Browser* environment and exposes read-only queries such as “get class comments”, “list packages”, “find methods containing a substring”… each exported as a `ChatPharoClient` tool.
* **Why** – empowers the LLM to answer questions about the live codebase while ChatPharo is running, without hard-coding any particular query set inside agents.
"
Class {
	#name : 'ChatPharoBrowserEnvironment',
	#superclass : 'Object',
	#instVars : [
		'browserEnvironment',
		'tools'
	],
	#category : 'AI-ChatPharo-Tools-System Browser',
	#package : 'AI-ChatPharo-Tools',
	#tag : 'System Browser'
}

{ #category : 'instance creation' }
ChatPharoBrowserEnvironment class >> browserEnvironment: env [ 

	^ self basicNew initializeWithEnvironment: env; yourself
]

{ #category : 'instance creation' }
ChatPharoBrowserEnvironment class >> new [ 

	^ self browserEnvironment: RBBrowserEnvironment default
]

{ #category : 'class-managments' }
ChatPharoBrowserEnvironment >> applyFunctionAddInstanceVariable: arguments [
	"Add an instance variable to an existing class."

	| className variableName theClass newInstVars |
	className := arguments at: 'class_name'.
	variableName := arguments at: 'variable_name'.

	theClass := self classNamed: className.
	theClass ifNil: [
		^ Dictionary with: 'error' -> ('Class not found: ' , className) ].

	"Check if variable already exists"
	(theClass instVarNames includes: variableName asSymbol) ifTrue: [
		^ Dictionary with: 'error' -> ('Instance variable already exists: ' , variableName) ].

	"Validate variable name"
	(variableName isEmpty or: [ variableName first isLetter not ]) ifTrue: [
		^ Dictionary with: 'error' -> 'Variable name must start with a letter' ].

	[
		newInstVars := theClass instVarNames copyWith: variableName asSymbol.
		theClass addInstVarNamed: variableName.

		^ Dictionary
			with: 'success' -> true
			with: 'class' -> className
			with: 'added_variable' -> variableName
			with: 'all_instance_variables' -> theClass instVarNames asArray
	] on: Error do: [ :error |
		^ Dictionary with: 'error' -> ('Failed to add instance variable: ' , error messageText) ]
]

{ #category : 'method-managments' }
ChatPharoBrowserEnvironment >> applyFunctionAddMethod: arguments [
	"Add or update a method in a class."

	| className sourceCode protocol side theClass targetClass |
	className := arguments at: 'class_name'.
	sourceCode := self normalizeLineEndingsToCr: (arguments at: 'source_code').
	protocol := arguments at: 'protocol' ifAbsent: [ 'as yet unclassified' ].
	side := arguments at: 'side' ifAbsent: [ 'instance' ].

	theClass := self classNamed: className.
	theClass ifNil: [ ^ Dictionary with: 'error' -> ('Class not found: ' , className) ]. "Determine which side (instance or class)"
	targetClass := side = 'class'
		               ifTrue: [ theClass class ]
		               ifFalse: [ theClass ].

	[
		| selector compiledMethod |
		selector := targetClass compile: sourceCode classified: protocol.
		selector ifNil: [ ^ Dictionary with: 'error' -> 'Failed to add method (compile returned nil)' ].
compiledMethod := targetClass compiledMethodAt: selector.

		^ Dictionary
			  with: 'success' -> true
			  with: 'class' -> className
			  with: 'side' -> side
			  with: 'selector' -> selector asString
			  with: 'protocol' -> protocol ]
		on: Error
		do: [ :error | ^ Dictionary with: 'error' -> ('Failed to add method: ' , error messageText) ]
]

{ #category : 'class-managments' }
ChatPharoBrowserEnvironment >> applyFunctionCreateClass: arguments [
	"Create a new class in the Pharo image."

	| className superclassName packageName tagName instVars classVars superclass definition newClass result |

	"Extract arguments safely"
	className := arguments at: 'class_name' ifAbsent: [ '' ].
	superclassName := arguments at: 'superclass' ifAbsent: [ 'Object' ].
	packageName := arguments at: 'package' ifAbsent: [ '' ].
	tagName := arguments at: 'tag' ifAbsent: [ nil ].
	instVars := arguments at: 'instance_variables' ifAbsent: [ #() ].
	classVars := arguments at: 'class_variables' ifAbsent: [ #() ].

	"Validate class name"
	(className isString
		and: [ className notEmpty
		and: [ className first isUppercase ] ]) ifFalse: [
		^ Dictionary new
			at: 'error' put: 'Class name must be a non-empty String starting with an uppercase letter';
			yourself ].

	"Check if class already exists"
	(Smalltalk globals includesKey: className asSymbol) ifTrue: [
		^ Dictionary new
			at: 'error' put: 'A class with this name already exists';
			yourself ].

	"Find superclass"
	superclass := Smalltalk globals
		at: superclassName asSymbol
		ifAbsent: [
			^ Dictionary new
				at: 'error' put: 'Superclass not found';
				yourself ].

	[
		"Create class using Fluid API"
		definition := superclass << className asSymbol.

		instVars notEmpty ifTrue: [
			definition := definition
				slots: (instVars collect: #asSymbol) ].

		classVars notEmpty ifTrue: [
			definition := definition
				sharedVariables: (classVars collect: #asSymbol) ].

		definition := definition package: packageName.

		tagName ifNotNil: [
			definition := definition tag: tagName ].

		newClass := definition install.

		result := Dictionary new.
		result
			at: 'success' put: true;
			at: 'class_name' put: className;
			at: 'superclass' put: superclassName;
			at: 'package' put: packageName;
			at: 'tag' put: (tagName ifNil: [ '' ]);
			at: 'instance_variables' put: instVars;
			at: 'class_variables' put: classVars.

		^ result
	]
	on: Error
	do: [ :error |
		^ Dictionary new
			at: 'error' put: error messageText;
			yourself ].

]

{ #category : 'class-managments' }
ChatPharoBrowserEnvironment >> applyFunctionCreatePackage: arguments [
	"Create a new package in the Pharo image."

	| packageName |
	packageName := arguments at: 'package_name'.

	"Validate package name"
	packageName isEmpty ifTrue: [
		^ Dictionary with: 'error' -> 'Package name cannot be empty' ].

	"Check if package already exists"
	(self packageNamed: packageName) ifNotNil: [
		^ Dictionary with: 'error' -> ('Package already exists: ' , packageName) ].

	[
		self class environment organization ensurePackage: packageName.

		^ Dictionary
			with: 'success' -> true
			with: 'package_name' -> packageName
			with: 'message' -> ('Successfully created package: ' , packageName)
	] on: Error do: [ :error |
		^ Dictionary with: 'error' -> ('Failed to create package: ' , error messageText) ]
]

{ #category : 'initialization' }
ChatPharoBrowserEnvironment >> applyFunctionDescribePackage: arguments [

        | packageName classes |
        packageName := arguments at: 'package'.
        classes := self classesInPackageNamed: packageName.

        classes ifNil: [
                ^ Dictionary
                          with: 'summary_per_class' -> Dictionary new
                          with:
                          'nonexistent_or_outside_scope_packages'
                          -> (Array with: packageName) ].

        ^ Dictionary
                  with: 'summary_per_class'
                  -> (Dictionary newFrom:
                                (classes collect: [ :class |
                                        class name
                                                ->
                                                        (Dictionary
                                                                with:
                                                                'comment'
                                                                        -> class comment
                                                                with:
                                                                'instance_methods'
                                                                        -> (class selectors sorted)
                                                                with:
                                                                'class_methods'
                                                                        -> (class class selectors sorted) ) ]))
                  with:
                  'nonexistent_or_outside_scope_packages' -> #()
]

{ #category : 'initialization' }
ChatPharoBrowserEnvironment >> applyFunctionFindMethodsWithSubstring: arguments [

	| substring methods |
	substring := arguments at: 'substring'.
	methods := self methodsWithSubstring: substring cappedAt: 50.

	^ Dictionary with: 'methods' -> (methods collect: [ :method |
				   Dictionary
					   with: 'class' -> method methodClass instanceSide name
					   with: 'side' -> (method methodClass hasClassSide
							    ifTrue: [ 'instance' ]
							    ifFalse: [ 'class' ])
					   with: 'protocol' -> method protocol
					   with: 'selector' -> method selector
					   with: 'source' -> method sourceCode ]) asArray
]

{ #category : 'initialization' }
ChatPharoBrowserEnvironment >> applyFunctionGetClassComments: arguments [

	^ self
		  response: 'comment_per_class'
		  collect: [ :class | class comment ]
		  forClassesNamed: (arguments at: 'classes')
]

{ #category : 'initialization' }
ChatPharoBrowserEnvironment >> applyFunctionGetClassDefinitions: arguments [

	^ self
		  response: 'definition_per_class'
		  collect: [ :class |
				  Dictionary
					  with: 'superclass'
						  ->
						  (class superclass ifNotNil: [ :superclass | superclass name ])
					  with: 'instance_variables' -> class instVarNames
					  with: 'class_variables' -> class classVarNames
					  with: 'package' -> class package name
					  with: 'tag' -> class packageTagName ]
		  forClassesNamed: (arguments at: 'classes')
]

{ #category : 'initialization' }
ChatPharoBrowserEnvironment >> applyFunctionGetClassMethods: arguments [

	| selectorsOnly |
	selectorsOnly := arguments at: 'selectors_only'.
	^ self
		  response: (selectorsOnly
				   ifTrue: [ 'selectors' ]
				   ifFalse: [ 'methods' ]) , '_per_protocol_per_side_per_class'
		  collect: [ :class |
				  Dictionary newFrom: ({
						   class.
						   class class } collect: [ :methodClass |
							   (methodClass isInstanceSide
								    ifTrue: [ 'instance' ]
								    ifFalse: [ 'class' ]) -> (Dictionary newFrom:
								    ((methodClass protocols sorted: [ :protocol1 :protocol2 |
									      protocol1 name < protocol2 name ]) collect: [ :protocol |
										     | selectorsInProtocol |
										     selectorsInProtocol := (methodClass
											                             selectorsInProtocol: protocol)
											                            sorted.
										     protocol name -> (selectorsOnly
											      ifTrue: [ selectorsInProtocol ]
											      ifFalse: [
													      selectorsInProtocol collect: [ :selector |
														      methodClass sourceCodeAt: selector ] ]) ])) ]) ]
		  forClassesNamed: (arguments at: 'classes')
]

{ #category : 'initialization' }
ChatPharoBrowserEnvironment >> applyFunctionGetClassSubclasses: arguments [

	| maxSubclasses |
	maxSubclasses := 100.
	^ self
		  response: 'subclasses_per_class'
		  collect: [ :class |
				   | names result |
				  names := ((class subclasses select: [ :subclass |
					             self browserEnvironment includesClass: subclass ])
					            collect: [ :subclass | subclass name ]) asSortedCollection
					           asArray.
				  result := Dictionary new.
				  result at: 'count' put: names size.
				  names size > maxSubclasses
					  ifTrue: [
							  result
								  at: 'subclasses' put: (names first: maxSubclasses);
								  at: 'truncated' put: true ]
					  ifFalse: [ result at: 'subclasses' put: names ].
				  result ]
		  forClassesNamed: (arguments at: 'classes')
]

{ #category : 'initialization' }
ChatPharoBrowserEnvironment >> applyFunctionGetClassesInPackages: arguments [

	| classesPerPackage notFoundPackages |
	classesPerPackage := Dictionary new.
	notFoundPackages := OrderedCollection new.

	(arguments at: 'packages') do: [ :packageName |
			(self classesInPackageNamed: packageName)
				ifNotNil: [ :classes |
						classesPerPackage
							at: packageName
							put:
								((classes sorted: [ :class1 :class2 |
									  class1 name < class2 name ]) collect: [ :class |
									 class name ]) ]
				ifNil: [ notFoundPackages add: packageName ] ].

	^ Dictionary
		  with: 'classes_per_package' -> classesPerPackage
		  with:
		  'nonexistent_or_outside_scope_packages'
		  -> notFoundPackages asArray
]

{ #category : 'comment-managments' }
ChatPharoBrowserEnvironment >> applyFunctionGetMethodComment: arguments [

	| className selector side theClass targetClass |
	className := arguments at: 'class_name' ifAbsent: [ nil ].
	selector := arguments at: 'selector' ifAbsent: [ nil ].
	side := arguments at: 'side' ifAbsent: [ 'instance' ].


	(className isNil or: [ className isEmpty ]) ifTrue: [
		^ Dictionary with: 'error' -> 'Missing required parameter: class_name' ].
	(selector isNil or: [ selector isEmpty ]) ifTrue: [
		^ Dictionary with: 'error' -> 'Missing required parameter: selector' ].
	
	
	theClass := self classNamed: className.
	theClass ifNil: [ ^ Dictionary with: 'error' -> ('Class not found: ' , className) ].

	targetClass := side = 'class'
		               ifTrue: [ theClass class ]
		               ifFalse: [ theClass ].

	(targetClass includesSelector: selector asSymbol) ifFalse: [ ^ Dictionary with: 'error' -> ('Method not found: ' , selector) ].

	[
		| method comment |
		method := targetClass >> selector asSymbol.
		comment := [ method comment ]
			           on: Error
			           do: [ :e | nil ].

		^ Dictionary
			  with: 'class' -> className
			  with: 'side' -> side
			  with: 'selector' -> selector
			  with: 'comment' -> (comment ifNil: [ '' ]) ]
		on: Error
		do: [ :error | ^ Dictionary with: 'error' -> ('Failed to get method comment: ' , error messageText) ]
]

{ #category : 'comment-managments' }
ChatPharoBrowserEnvironment >> applyFunctionGetPackageComments: arguments [
	"Get the comments of the specified packages."

	| commentPerPackage notFoundPackages |
	commentPerPackage := Dictionary new.
	notFoundPackages := OrderedCollection new.

	(arguments at: 'packages') do: [ :packageName |
		(self packageNamed: packageName)
			ifNotNil: [ :package |
				commentPerPackage
					at: packageName
					put: ([ package comment ] on: Error do: [ :e | '' ]) ]
			ifNil: [ notFoundPackages add: packageName ] ].

	^ Dictionary
		with: 'comment_per_package' -> commentPerPackage
		with: 'nonexistent_or_outside_scope_packages' -> notFoundPackages asArray
]

{ #category : 'initialization' }
ChatPharoBrowserEnvironment >> applyFunctionGetPackages: arguments [

	^ Dictionary with: 'packages'
		  ->
			  (self browserEnvironment packages collect: [ :package |
				   package name ]) sorted
]

{ #category : 'class-managments' }
ChatPharoBrowserEnvironment >> applyFunctionMoveClassToPackage: arguments [
	"Move a class to a different package."

	| className packageName tagName theClass |
	className := arguments at: 'class_name'.
	packageName := arguments at: 'package'.
	tagName := arguments at: 'tag' ifAbsent: [ nil ].

	theClass := self classNamed: className.
	theClass ifNil: [
		^ Dictionary with: 'error' -> ('Class not found: ' , className) ].

	[
		tagName
			ifNotNil: [ theClass package: packageName tag: tagName ]
			ifNil: [ theClass package: packageName ].

		^ Dictionary
			with: 'success' -> true
			with: 'class' -> className
			with: 'new_package' -> packageName
			with: 'new_tag' -> (tagName ifNil: [ '' ])
	] on: Error do: [ :error |
		^ Dictionary with: 'error' -> ('Failed to move class: ' , error messageText) ]
]

{ #category : 'method-managments' }
ChatPharoBrowserEnvironment >> applyFunctionMoveMethodToProtocol: arguments [

	| className selector protocol side theClass targetClass |
	className := arguments at: 'class_name' ifAbsent: [ nil ] .
	selector := arguments at: 'selector' ifAbsent: [ nil ].
	protocol := arguments at: 'protocol' ifAbsent: [ nil ].
	side := arguments at: 'side' ifAbsent: [ 'instance' ].

(className isNil or: [ className isEmpty ]) ifTrue: [
		^ Dictionary with: 'error' -> 'Missing required parameter: class_name' ].
	(selector isNil or: [ selector isEmpty ]) ifTrue: [
		^ Dictionary with: 'error' -> 'Missing required parameter: selector' ].
	(protocol isNil or: [ protocol isEmpty ]) ifTrue: [
		^ Dictionary with: 'error' -> 'Missing required parameter: protocol' ].
	
	theClass := self classNamed: className.
	theClass ifNil: [ ^ Dictionary with: 'error' -> ('Class not found: ' , className) ]. 
	targetClass := side = 'class'
		               ifTrue: [ theClass class ]
		               ifFalse: [ theClass ].
	(targetClass includesSelector: selector asSymbol) ifFalse: [ ^ Dictionary with: 'error' -> ('Method not found: ' , selector) ].

	[
		targetClass organization classify: selector asSymbol under: protocol.

		^ Dictionary
			  with: 'success' -> true
			  with: 'class' -> className
			  with: 'side' -> side
			  with: 'selector' -> selector
			  with: 'new_protocol' -> protocol ]
		on: Error
		do: [ :error | ^ Dictionary with: 'error' -> ('Failed to move method: ' , error messageText) ]
]

{ #category : 'class-managments' }
ChatPharoBrowserEnvironment >> applyFunctionRemoveClass: arguments [
	"Remove a class from the Pharo image."

	| className theClass |
	className := arguments at: 'class_name'.

	theClass := self classNamed: className.
	theClass ifNil: [
		^ Dictionary with: 'error' -> ('Class not found: ' , className) ].

	"Check for subclasses"
	theClass subclasses ifNotEmpty: [ :subs |
		^ Dictionary
			with: 'error' -> 'Cannot remove class with subclasses'
			with: 'subclasses' -> (subs collect: [ :s | s name ]) ].

	[
		theClass removeFromSystem.

		^ Dictionary
			with: 'success' -> true
			with: 'removed_class' -> className
			with: 'message' -> ('Successfully removed class: ' , className)
	] on: Error do: [ :error |
		^ Dictionary with: 'error' -> ('Failed to remove class: ' , error messageText) ]
]

{ #category : 'class-managments' }
ChatPharoBrowserEnvironment >> applyFunctionRemoveInstanceVariable: arguments [

	| className variableName theClass |
		className := arguments at: 'class_name' ifAbsent: [ nil ].
	variableName := arguments at: 'variable_name' ifAbsent: [ nil ].

	(className isNil or: [ className isEmpty ]) ifTrue: [
		^ Dictionary with: 'error' -> 'Missing required parameter: class_name' ].
	(variableName isNil or: [ variableName isEmpty ]) ifTrue: [
		^ Dictionary with: 'error' -> 'Missing required parameter: variable_name' ].
	className := arguments at: 'class_name'.
	variableName := arguments at: 'variable_name'.

	theClass := self classNamed: className.
	theClass ifNil: [ ^ Dictionary with: 'error' -> ('Class not found: ' , className) ]. "Check if variable exists"
	(theClass instVarNames includes: variableName asSymbol) ifFalse: [
		^ Dictionary with: 'error' -> ('Instance variable not found: ' , variableName) ].

	[
		theClass removeInstVarNamed: variableName.

		^ Dictionary
			  with: 'success' -> true
			  with: 'class' -> className
			  with: 'removed_variable' -> variableName
			  with: 'remaining_instance_variables' -> theClass instVarNames asArray ]
		on: Error
		do: [ :error | ^ Dictionary with: 'error' -> ('Failed to remove instance variable: ' , error messageText) ]
]

{ #category : 'method-managments' }
ChatPharoBrowserEnvironment >> applyFunctionRemoveMethod: arguments [

	| className selector side theClass targetClass |
	className := arguments at: 'class_name' ifAbsent: [ nil ].
	selector := arguments at: 'selector' ifAbsent: [ nil ].
	side := arguments at: 'side' ifAbsent: [ 'instance' ].

	(className isNil or: [ className isEmpty ]) ifTrue: [
		^ Dictionary with: 'error' -> 'Missing required parameter: class_name' ].
	(selector isNil or: [ selector isEmpty ]) ifTrue: [
		^ Dictionary with: 'error' -> 'Missing required parameter: selector' ].
	
	theClass := self classNamed: className.
	theClass ifNil: [ ^ Dictionary with: 'error' -> ('Class not found: ' , className) ]. 
	targetClass := side = 'class'
		               ifTrue: [ theClass class ]
		               ifFalse: [ theClass ]. 
	(targetClass includesSelector: selector asSymbol) ifFalse: [ ^ Dictionary with: 'error' -> ('Method not found: ' , selector) ].

	[
		targetClass removeSelector: selector asSymbol.

		^ Dictionary
			  with: 'success' -> true
			  with: 'class' -> className
			  with: 'side' -> side
			  with: 'removed_selector' -> selector ]
		on: Error
		do: [ :error | ^ Dictionary with: 'error' -> ('Failed to remove method: ' , error messageText) ]
]

{ #category : 'class-managments' }
ChatPharoBrowserEnvironment >> applyFunctionRenameClass: arguments [

	| oldName newName theClass refactoring |
	oldName := arguments at: 'old_name' ifAbsent: [ nil ].
	newName := arguments at: 'new_name' ifAbsent: [ nil ].

	(oldName isNil or: [ oldName isEmpty ]) ifTrue: [
		^ Dictionary with: 'error' -> 'Missing required parameter: old_name' ].
	(newName isNil or: [ newName isEmpty ]) ifTrue: [
		^ Dictionary with: 'error' -> 'Missing required parameter: new_name' ].
	theClass := self classNamed: oldName.
	theClass ifNil: [ ^ Dictionary with: 'error' -> ('Class not found: ' , oldName) ]. 
	(newName isEmpty or: [ newName first isUppercase not ]) ifTrue: [
		^ Dictionary with: 'error' -> 'New class name must start with an uppercase letter' ]. 
	(Smalltalk globals includesKey: newName asSymbol) ifTrue: [
		^ Dictionary with: 'error' -> ('A class with name ' , newName , ' already exists') ]. 
	[
		refactoring := ReRenameClassRefactoring rename: theClass to: newName asSymbol.
		refactoring execute.

		^ Dictionary
			  with: 'success' -> true
			  with: 'old_name' -> oldName
			  with: 'new_name' -> newName
			  with: 'message' -> ('Successfully renamed ' , oldName , ' to ' , newName) ]
		on: Error
		do: [ :error | ^ Dictionary with: 'error' -> ('Refactoring failed: ' , error messageText) ]
]

{ #category : 'class-managments' }
ChatPharoBrowserEnvironment >> applyFunctionRenameClassesInPackage: arguments [

	| packageName searchPattern replacePattern classes renamedClasses errors dryRun |
	packageName := arguments at: 'package' ifAbsent: [ nil ].
	searchPattern := arguments at: 'search_pattern' ifAbsent: [ nil ].
	replacePattern := arguments at: 'replace_pattern' ifAbsent: [ nil ].
	dryRun := arguments at: 'dry_run' ifAbsent: [ false ]. 
		(packageName isNil or: [ packageName isEmpty ]) ifTrue: [
		^ Dictionary with: 'error' -> 'Missing required parameter: package' ].
	(searchPattern isNil or: [ searchPattern isEmpty ]) ifTrue: [
		^ Dictionary with: 'error' -> 'Missing required parameter: search_pattern' ].
	replacePattern ifNil: [
		^ Dictionary with: 'error' -> 'Missing required parameter: replace_pattern' ].
	
	
	classes := self classesInPackageNamed: packageName.
	classes ifNil: [ ^ Dictionary with: 'error' -> ('Package not found: ' , packageName) ].

	renamedClasses := OrderedCollection new.
	errors := OrderedCollection new. 
	classes do: [ :theClass |
			| oldName newName |
			oldName := theClass name asString.

			(oldName includesSubstring: searchPattern) ifTrue: [
					newName := oldName copyReplaceAll: searchPattern with: replacePattern. 
					(newName isEmpty or: [ newName first isUppercase not ])
						ifTrue: [ errors add: (Dictionary with: 'old_name' -> oldName with: 'error' -> 'New name would not start with uppercase') ]
						ifFalse: [
								(Smalltalk globals includesKey: newName asSymbol)
									ifTrue: [
									errors add:
										(Dictionary with: 'old_name' -> oldName with: 'new_name' -> newName with: 'error' -> 'Target name already exists') ]
									ifFalse: [
											dryRun
												ifTrue: [
												renamedClasses add:
													(Dictionary with: 'old_name' -> oldName with: 'new_name' -> newName with: 'status' -> 'would_rename') ]
												ifFalse: [
														[
															| refactoring |
															refactoring := ReRenameClassRefactoring rename: theClass to: newName asSymbol.
															refactoring execute.

															renamedClasses add:
																(Dictionary with: 'old_name' -> oldName with: 'new_name' -> newName with: 'status' -> 'renamed') ]
															on: Error
															do: [ :error |
															errors add: (Dictionary with: 'old_name' -> oldName with: 'new_name' -> newName with: 'error' -> error messageText) ] ] ] ] ] ].

	^ Dictionary new
		  at: 'package' put: packageName;
		  at: 'search_pattern' put: searchPattern;
		  at: 'replace_pattern' put: replacePattern;
		  at: 'dry_run' put: dryRun;
		  at: 'renamed_classes' put: renamedClasses asArray;
		  at: 'errors' put: errors asArray;
		  at: 'total_matched' put: renamedClasses size + errors size;
		  at: 'successful' put: renamedClasses size;
		  yourself
]

{ #category : 'method-managments' }
ChatPharoBrowserEnvironment >> applyFunctionRenameMethod: arguments [

	| className oldSelector newSelector side theClass targetClass |
	className := arguments at: 'class_name' ifAbsent: [ nil ].
	oldSelector := arguments at: 'old_selector' ifAbsent: [ nil ].
	newSelector := arguments at: 'new_selector' ifAbsent: [ nil ].
	side := arguments at: 'side' ifAbsent: [ 'instance' ].

	(className isNil or: [ className isEmpty ]) ifTrue: [
		^ Dictionary with: 'error' -> 'Missing required parameter: class_name' ].
	(oldSelector isNil or: [ oldSelector isEmpty ]) ifTrue: [
		^ Dictionary with: 'error' -> 'Missing required parameter: old_selector' ].
	(newSelector isNil or: [ newSelector isEmpty ]) ifTrue: [
		^ Dictionary with: 'error' -> 'Missing required parameter: new_selector' ].
	
	theClass := self classNamed: className.
	theClass ifNil: [ ^ Dictionary with: 'error' -> ('Class not found: ' , className) ].
	targetClass := side = 'class'
		               ifTrue: [ theClass class ]
		               ifFalse: [ theClass ]. 
	(targetClass includesSelector: oldSelector asSymbol) ifFalse: [
		^ Dictionary with: 'error' -> ('Method not found: ' , oldSelector) ].
	(targetClass includesSelector: newSelector asSymbol) ifTrue: [
		^ Dictionary with: 'error' -> ('Selector already exists: ' , newSelector) ].

	[
		| refactoring |
		refactoring := ReRenameMethodRefactoring
			               renameMethod: oldSelector asSymbol
			               in: targetClass
			               to: newSelector asSymbol
			               permutation: (1 to: oldSelector asSymbol numArgs).
		refactoring execute.

		^ Dictionary
			  with: 'success' -> true
			  with: 'class' -> className
			  with: 'side' -> side
			  with: 'old_selector' -> oldSelector
			  with: 'new_selector' -> newSelector ]
		on: Error
		do: [ :error | ^ Dictionary with: 'error' -> ('Failed to rename method: ' , error messageText) ]
]

{ #category : 'class-managments' }
ChatPharoBrowserEnvironment >> applyFunctionSetClassComment: arguments [

	| className comment theClass |
		className := arguments at: 'class_name' ifAbsent: [ nil ].
	comment := arguments at: 'comment' ifAbsent: [ nil ].

	(className isNil or: [ className isEmpty ]) ifTrue: [
		^ Dictionary with: 'error' -> 'Missing required parameter: class_name' ].
	comment ifNil: [
		^ Dictionary with: 'error' -> 'Missing required parameter: comment' ].
	className := arguments at: 'class_name'.
	comment := arguments at: 'comment'.

	theClass := self classNamed: className.
	theClass ifNil: [ ^ Dictionary with: 'error' -> ('Class not found: ' , className) ].

	[
		theClass comment: comment.

		^ Dictionary with: 'success' -> true with: 'class' -> className with: 'comment' -> comment ]
		on: Error
		do: [ :error | ^ Dictionary with: 'error' -> ('Failed to set class comment: ' , error messageText) ]
]

{ #category : 'comment-managments' }
ChatPharoBrowserEnvironment >> applyFunctionSetMethodComment: arguments [

	| className selector side comment theClass targetClass method sourceCode newSource protocol commentLiteral |
	className := arguments at: 'class_name' ifAbsent: [ nil ].
	selector := arguments at: 'selector' ifAbsent: [ nil ].
	comment := arguments at: 'comment' ifAbsent: [ nil ].
	side := arguments at: 'side' ifAbsent: [ 'instance' ].

	(className isNil or: [ className isEmpty ]) ifTrue: [
		^ Dictionary with: 'error' -> 'Missing required parameter: class_name' ].
	(selector isNil or: [ selector isEmpty ]) ifTrue: [
		^ Dictionary with: 'error' -> 'Missing required parameter: selector' ].
	comment ifNil: [
		^ Dictionary with: 'error' -> 'Missing required parameter: comment' ].
	
	theClass := self classNamed: className.
	theClass ifNil: [ ^ Dictionary with: 'error' -> ('Class not found: ' , className) ].

	targetClass := side = 'class'
		               ifTrue: [ theClass class ]
		               ifFalse: [ theClass ].

	(targetClass includesSelector: selector asSymbol) ifFalse: [ ^ Dictionary with: 'error' -> ('Method not found: ' , selector) ].

	[
		| existingComment |
		method := targetClass >> selector asSymbol.
		sourceCode := method sourceCode.
		protocol := method protocol.
		existingComment := [ method comment ]
			                   on: Error
			                   do: [ :e | nil ]. "Build the new comment string literal"
		commentLiteral := '"' , (comment copyReplaceAll: '"' with: '""') , '"'.

		existingComment isNil
			ifTrue: [ "No existing comment - insert after method signature line"
					| signatureEnd bodyStart |
					"Find the end of the first line (method signature)"
					signatureEnd := sourceCode indexOf: Character cr ifAbsent: [ sourceCode indexOf: Character lf ifAbsent: [ sourceCode size ] ].
					bodyStart := sourceCode copyFrom: signatureEnd + 1 to: sourceCode size.
					newSource := (sourceCode copyFrom: 1 to: signatureEnd) , String cr , String tab , commentLiteral , bodyStart ]
			ifFalse: [ "Replace existing comment"
					| existingLiteral |
					existingLiteral := '"' , (existingComment copyReplaceAll: '"' with: '""') , '"'.
					(sourceCode includesSubstring: existingLiteral)
						ifTrue: [ newSource := sourceCode copyReplaceAll: existingLiteral with: commentLiteral ]
						ifFalse: [ "Fallback: insert after signature if we can't find the old comment"
								| signatureEnd bodyStart |
								signatureEnd := sourceCode
									                indexOf: Character cr
									                ifAbsent: [ sourceCode indexOf: Character lf ifAbsent: [ sourceCode size ] ].
								bodyStart := sourceCode copyFrom: signatureEnd + 1 to: sourceCode size.
								newSource := (sourceCode copyFrom: 1 to: signatureEnd) , String cr , String tab , commentLiteral , bodyStart ] ].

		newSource := self normalizeLineEndingsToCr: newSource.
		targetClass compile: newSource classified: protocol.

		^ Dictionary
			  with: 'success' -> true
			  with: 'class' -> className
			  with: 'side' -> side
			  with: 'selector' -> selector
			  with: 'comment' -> comment ]
		on: Error
		do: [ :error | ^ Dictionary with: 'error' -> ('Failed to set method comment: ' , error messageText) ]
]

{ #category : 'comment-managments' }
ChatPharoBrowserEnvironment >> applyFunctionSetPackageComment: arguments [
	"Set or update the comment of a package."

	| packageName comment package |
	packageName := arguments at: 'package_name'.
	comment := arguments at: 'comment'.

	package := self packageNamed: packageName.
	package ifNil: [
		^ Dictionary with: 'error' -> ('Package not found: ' , packageName) ].

	[
		package comment: comment.

		^ Dictionary
			with: 'success' -> true
			with: 'package' -> packageName
			with: 'comment' -> comment
	] on: Error do: [ :error |
		^ Dictionary with: 'error' -> ('Failed to set package comment: ' , error messageText) ]
]

{ #category : 'accessing' }
ChatPharoBrowserEnvironment >> browserEnvironment [

	^ browserEnvironment
]

{ #category : 'accessing' }
ChatPharoBrowserEnvironment >> browserEnvironment: anObject [

	browserEnvironment := anObject
]

{ #category : 'initialization' }
ChatPharoBrowserEnvironment >> classNamed: className [

	| direct normalised |
	className ifNil: [ ^ nil ].
	direct := self browserEnvironment at: className asString asSymbol ifAbsent: [ nil ].
	direct ifNotNil: [ ^ direct ].

	normalised := className asLowercase.
	^ self browserEnvironment classes detect: [ :cls | cls name asString asLowercase = normalised ] ifNone: [ nil ]
]

{ #category : 'initialization' }
ChatPharoBrowserEnvironment >> classesInPackageNamed: packageName [

	^ (self packageNamed: packageName) ifNotNil: [ :package |
			  package definedClasses select: [ :class |
				  self browserEnvironment includesClass: class ] ]
]

{ #category : 'class-managments' }
ChatPharoBrowserEnvironment >> functionAddInstanceVariable [
	"Tool to add an instance variable to a class."

	^ ChatPharoClient
		name: 'add_instance_variable'
		description: 'Adds an instance variable to an existing class. This modifies the live system.'
		parameters: (Dictionary
			with: 'type' -> 'object'
			with: 'properties' -> (Dictionary
				with: 'class_name' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The name of the class to modify')
				with: 'variable_name' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The name of the instance variable to add (must start with a letter)'))
			with: 'required' -> #( 'class_name' 'variable_name' ))
		block: [ :arguments |
			self applyFunctionAddInstanceVariable: arguments ]
]

{ #category : 'method-managments' }
ChatPharoBrowserEnvironment >> functionAddMethod [
	"Tool to add or update a method in a class."

	^ ChatPharoClient
		name: 'add_method'
		description: 'Adds or updates a method in a class. If the method already exists, it will be replaced. The source_code should be complete Smalltalk method source including the method signature. This modifies the live system.'
		parameters: (Dictionary
			with: 'type' -> 'object'
			with: 'properties' -> (Dictionary
				with: 'class_name' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The name of the class to add the method to')
				with: 'source_code' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The complete Smalltalk method source code, including the method signature (e.g., "methodName: arg\n\t^ arg * 2")')
				with: 'protocol' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The protocol (category) to place the method in (default: "as yet unclassified")')
				with: 'side' -> (Dictionary
					with: 'type' -> 'string'
					with: 'enum' -> #( 'instance' 'class' )
					with: 'description' -> 'Whether to add an instance method or class method (default: "instance")'))
			with: 'required' -> #( 'class_name' 'source_code' ))
		block: [ :arguments |
			self applyFunctionAddMethod: arguments ]
]

{ #category : 'class-managments' }
ChatPharoBrowserEnvironment >> functionCreateClass [
	"Tool to create a new class."

	^ ChatPharoClient
		name: 'create_class'
		description: 'Creates a new class in the Pharo image. You can specify the superclass, instance variables, class variables, package, and tag. This modifies the live system.'
		parameters: (Dictionary
			with: 'type' -> 'object'
			with: 'properties' -> (Dictionary
				with: 'class_name' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The name for the new class (must start with uppercase)')
				with: 'superclass' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The name of the superclass (default: "Object")')
				with: 'package' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The package to place the class in')
				with: 'tag' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'Optional tag (subcategory) within the package')
				with: 'instance_variables' -> (Dictionary
					with: 'type' -> 'array'
					with: 'items' -> (Dictionary with: 'type' -> 'string')
					with: 'description' -> 'Array of instance variable names')
				with: 'class_variables' -> (Dictionary
					with: 'type' -> 'array'
					with: 'items' -> (Dictionary with: 'type' -> 'string')
					with: 'description' -> 'Array of class variable names'))
			with: 'required' -> #( 'class_name' 'package' ))
		block: [ :arguments |
			self applyFunctionCreateClass: arguments ]
]

{ #category : 'class-managments' }
ChatPharoBrowserEnvironment >> functionCreatePackage [
	"Tool to create a new package."

	^ ChatPharoClient
		name: 'create_package'
		description: 'Creates a new package in the Pharo image. This modifies the live system.'
		parameters: (Dictionary
			with: 'type' -> 'object'
			with: 'properties' -> (Dictionary
				with: 'package_name' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The name for the new package'))
			with: 'required' -> #( 'package_name' ))
		block: [ :arguments |
			self applyFunctionCreatePackage: arguments ]
]

{ #category : 'temporal-tools' }
ChatPharoBrowserEnvironment >> functionCreateTemporalTool [
	"Meta-tool that lets the model create a new temporal tool at runtime."

	^ ChatPharoClient
		name: 'create_temporal_tool'
		description: 'Creates a new temporal tool that you (the AI model) can use during this conversation. The tool will be available for calling in subsequent interactions. Use this when you need a reusable helper function for the current task. The code receives an "arguments" dictionary. Remember to delete temporal tools when you no longer need them.'
		parameters: (Dictionary
			with: 'type' -> 'object'
			with: 'properties' -> (Dictionary
				with: 'tool_name' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'Unique name for the tool (alphanumeric and underscores only)')
				with: 'description' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'Human-readable description of what the tool does')
				with: 'parameters_schema' -> (Dictionary
					with: 'type' -> 'object'
					with: 'description' -> 'JSON Schema for the tool parameters (with type, properties, required fields). If omitted, the tool takes no parameters.')
				with: 'code' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'Smalltalk code for the tool body. It receives an "arguments" dictionary variable. Must return a value (preferably a Dictionary for structured results).'))
			with: 'required' -> #( 'tool_name' 'description' 'code' ))
		block: [ :arguments |
			ChatPharoTemporalToolRegistry current
				createToolNamed: (arguments at: 'tool_name')
				description: (arguments at: 'description')
				parameters: (arguments at: 'parameters_schema' ifAbsent: [ nil ])
				code: (arguments at: 'code') ]
]

{ #category : 'temporal-tools' }
ChatPharoBrowserEnvironment >> functionDeleteAllTemporalTools [
	"Meta-tool that lets the model delete all temporal tools at once."

	^ ChatPharoClient
		name: 'delete_all_temporal_tools'
		description: 'Deletes all temporal tools that were created during this conversation. Use this for cleanup when your task is complete.'
		parameters: (Dictionary
			with: 'type' -> 'object'
			with: 'properties' -> Dictionary new
			with: 'required' -> #())
		block: [ :arguments |
			ChatPharoTemporalToolRegistry current deleteAllTools ]
]

{ #category : 'temporal-tools' }
ChatPharoBrowserEnvironment >> functionDeleteTemporalTool [
	"Meta-tool that lets the model delete a specific temporal tool."

	^ ChatPharoClient
		name: 'delete_temporal_tool'
		description: 'Deletes a temporal tool by name. Use this to clean up tools you no longer need.'
		parameters: (Dictionary
			with: 'type' -> 'object'
			with: 'properties' -> (Dictionary
				with: 'tool_name' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The name of the temporal tool to delete'))
			with: 'required' -> #( 'tool_name' ))
		block: [ :arguments |
			ChatPharoTemporalToolRegistry current
				deleteToolNamed: (arguments at: 'tool_name') ]
]

{ #category : 'accessing' }
ChatPharoBrowserEnvironment >> functionDescribePackage [

        ^ ChatPharoClient
                  name: 'describe_package'
                  description:
                  'Returns each class in the given package with its comment and list of methods.'
                  parameters: (Dictionary
                                   with: 'type' -> 'object'
                                   with:
                                           'properties' -> (Dictionary with: 'package' -> (Dictionary
                                                             with: 'type' -> 'string'
                                                             with: 'description' -> 'Name of the package'))
                                   with: 'required' -> #( 'package' ))
                  block: [ :arguments |
                  self applyFunctionDescribePackage: arguments ]
]

{ #category : 'initialization' }
ChatPharoBrowserEnvironment >> functionFindMethodsWithSubstring [

	^ ChatPharoClient
		  name: 'find_methods_with_substring'
		  description:
		  'Finds methods whose source includes the given substring. Results are capped at 50 methods.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with:
					   'properties' -> (Dictionary with: 'substring' -> (Dictionary
							     with: 'type' -> 'string'
							     with: 'description' -> 'The substring to find'))
				   with: 'required' -> #( 'substring' ))
		  block: [ :arguments |
		  self applyFunctionFindMethodsWithSubstring: arguments ]
]

{ #category : 'initialization' }
ChatPharoBrowserEnvironment >> functionGetClassComments [

	^ ChatPharoClient
		  name: 'get_class_comments'
		  description: 'Gets the comment of each class.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with:
					   'properties' -> (Dictionary with: 'classes' -> (Dictionary
							     with: 'type' -> 'array'
							     with: 'items' -> (Dictionary with: 'type' -> 'string')
							     with: 'description' -> 'Names of the classes'))
				   with: 'required' -> #( 'classes' ))
		  block: [ :arguments |
		  self applyFunctionGetClassComments: arguments ]
]

{ #category : 'initialization' }
ChatPharoBrowserEnvironment >> functionGetClassDefinitions [

	^ ChatPharoClient
		  name: 'get_class_definitions'
		  description:
		  'Gets the definitions of each class: its superclass, its instance variables, its class variables, the package it is in and its tag.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with:
					   'properties' -> (Dictionary with: 'classes' -> (Dictionary
							     with: 'type' -> 'array'
							     with: 'items' -> (Dictionary with: 'type' -> 'string')
							     with: 'description' -> 'Names of the classes'))
				   with: 'required' -> #( 'classes' ))
		  block: [ :arguments |
		  self applyFunctionGetClassDefinitions: arguments ]
]

{ #category : 'initialization' }
ChatPharoBrowserEnvironment >> functionGetClassMethods [

	^ ChatPharoClient
		  name: 'get_class_methods'
		  description:
		  'Gets the source code, or just the selectors, of each method for the given classes, organized per protocol and grouped by instance side and class side.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> (Dictionary
						    with: 'classes' -> (Dictionary
								     with: 'type' -> 'array'
								     with: 'items' -> (Dictionary with: 'type' -> 'string')
								     with: 'description' -> 'Names of the classes')
						    with: 'selectors_only'
							    ->
								    (Dictionary with: 'type' -> 'boolean' with: 'description'
									     ->
										     ('Whether to get the full source of each method, or only its selector; '
										      ,
										      'prefer selectors only to get an overview of a class')))
				   with: 'required' -> #( 'classes' 'selectors_only' ))
		  block: [ :arguments |
		  self applyFunctionGetClassMethods: arguments ]
]

{ #category : 'initialization' }
ChatPharoBrowserEnvironment >> functionGetClassSubclasses [

	^ ChatPharoClient
		  name: 'get_class_subclasses'
		  description:
			  'Gets the direct subclasses of each given class that are in scope. '
			  ,
			  'For each class, returns a dictionary with ''count'' (total number '
			  ,
			  'of direct subclasses) and ''subclasses'' (sorted names). If the '
			  ,
			  'list is capped to keep the response small, ''truncated'' is set to '
			  , 'true and only a prefix of the subclasses is included.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with:
					   'properties' -> (Dictionary with: 'classes' -> (Dictionary
							     with: 'type' -> 'array'
							     with: 'items' -> (Dictionary with: 'type' -> 'string')
							     with: 'description' -> 'Names of the classes'))
				   with: 'required' -> #( 'classes' ))
		  block: [ :arguments |
		  self applyFunctionGetClassSubclasses: arguments ]
]

{ #category : 'initialization' }
ChatPharoBrowserEnvironment >> functionGetClassesInPackages [

	^ ChatPharoClient
		  name: 'get_classes_in_packages'
		  description: 'Gets the classes in each given package.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with:
					   'properties' -> (Dictionary with: 'packages' -> (Dictionary
							     with: 'type' -> 'array'
							     with: 'items' -> (Dictionary with: 'type' -> 'string')
							     with: 'description' -> 'Names of the packages'))
				   with: 'required' -> #( 'packages' ))
		  block: [ :arguments |
		  self applyFunctionGetClassesInPackages: arguments ]
]

{ #category : 'comment-managments' }
ChatPharoBrowserEnvironment >> functionGetMethodComment [
	"Tool to get the comment of a method."

	^ ChatPharoClient
		name: 'get_method_comment'
		description: 'Gets the comment (the first string literal in the method body) of a method.'
		parameters: (Dictionary
			with: 'type' -> 'object'
			with: 'properties' -> (Dictionary
				with: 'class_name' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The name of the class containing the method')
				with: 'selector' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The selector of the method')
				with: 'side' -> (Dictionary
					with: 'type' -> 'string'
					with: 'enum' -> #( 'instance' 'class' )
					with: 'description' -> 'Whether this is an instance or class method (default: "instance")'))
			with: 'required' -> #( 'class_name' 'selector' ))
		block: [ :arguments |
			self applyFunctionGetMethodComment: arguments ]
]

{ #category : 'comment-managments' }
ChatPharoBrowserEnvironment >> functionGetPackageComments [
	"Tool to get the comments of packages."

	^ ChatPharoClient
		name: 'get_package_comments'
		description: 'Gets the comment (documentation) of each specified package.'
		parameters: (Dictionary
			with: 'type' -> 'object'
			with: 'properties' -> (Dictionary
				with: 'packages' -> (Dictionary
					with: 'type' -> 'array'
					with: 'items' -> (Dictionary with: 'type' -> 'string')
					with: 'description' -> 'Names of the packages'))
			with: 'required' -> #( 'packages' ))
		block: [ :arguments |
			self applyFunctionGetPackageComments: arguments ]
]

{ #category : 'initialization' }
ChatPharoBrowserEnvironment >> functionGetPackages [

	^ ChatPharoClient
		  name: 'get_packages'
		  description: 'Gets all of the packages.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> Dictionary new
				   with: 'required' -> #(  ))
		  block: [ :arguments | self applyFunctionGetPackages: arguments ]
]

{ #category : 'initialization' }
ChatPharoBrowserEnvironment >> functionGetSandboxStatus [
	"Returns current sandbox configuration"

	^ ChatPharoClient
		  name: 'get_sandbox_status'
		  description:
		  'Gets the current sandbox security configuration. Use this to understand what restrictions are in place before executing code.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> Dictionary new
				   with: 'required' -> #(  ))
		  block: [ :arguments |
				  | settings |
				  settings := ChatPharoSettings default.
				  Dictionary
					  with: 'sandbox_enabled' -> settings sandboxEnabled
					  with: 'timeout_ms' -> settings sandboxTimeout
					  with: 'restrict_file_system' -> settings sandboxRestrictFileSystem
					  with: 'restrict_network' -> settings sandboxRestrictNetwork
					  with: 'restrict_system_access' -> settings sandboxRestrictSystemAccess ]
]

{ #category : 'temporal-tools' }
ChatPharoBrowserEnvironment >> functionListTemporalTools [
	"Meta-tool that lets the model see which temporal tools currently exist."

	^ ChatPharoClient
		name: 'list_temporal_tools'
		description: 'Lists all temporal tools currently registered in this session, with their names, descriptions, and creation times.'
		parameters: (Dictionary
			with: 'type' -> 'object'
			with: 'properties' -> Dictionary new
			with: 'required' -> #())
		block: [ :arguments |
			ChatPharoTemporalToolRegistry current listTools ]
]

{ #category : 'class-managments' }
ChatPharoBrowserEnvironment >> functionMoveClassToPackage [
	"Tool to move a class to a different package."

	^ ChatPharoClient
		name: 'move_class_to_package'
		description: 'Moves an existing class to a different package. You can optionally specify a tag within the package. This modifies the live system.'
		parameters: (Dictionary
			with: 'type' -> 'object'
			with: 'properties' -> (Dictionary
				with: 'class_name' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The name of the class to move')
				with: 'package' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The target package name')
				with: 'tag' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'Optional tag (subcategory) within the target package'))
			with: 'required' -> #( 'class_name' 'package' ))
		block: [ :arguments |
			self applyFunctionMoveClassToPackage: arguments ]
]

{ #category : 'method-managments' }
ChatPharoBrowserEnvironment >> functionMoveMethodToProtocol [
	"Tool to move a method to a different protocol."

	^ ChatPharoClient
		name: 'move_method_to_protocol'
		description: 'Moves a method to a different protocol (category) within its class. This modifies the live system.'
		parameters: (Dictionary
			with: 'type' -> 'object'
			with: 'properties' -> (Dictionary
				with: 'class_name' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The name of the class containing the method')
				with: 'selector' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The method selector to move')
				with: 'protocol' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The target protocol name')
				with: 'side' -> (Dictionary
					with: 'type' -> 'string'
					with: 'enum' -> #( 'instance' 'class' )
					with: 'description' -> 'Whether this is an instance or class method (default: "instance")'))
			with: 'required' -> #( 'class_name' 'selector' 'protocol' ))
		block: [ :arguments |
			self applyFunctionMoveMethodToProtocol: arguments ]
]

{ #category : 'class-managments' }
ChatPharoBrowserEnvironment >> functionRemoveClass [
	"Tool to remove a class from the system."

	^ ChatPharoClient
		name: 'remove_class'
		description: 'Removes a class from the Pharo image. The class must not have any subclasses. This permanently deletes the class and all its methods from the live system.'
		parameters: (Dictionary
			with: 'type' -> 'object'
			with: 'properties' -> (Dictionary
				with: 'class_name' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The name of the class to remove'))
			with: 'required' -> #( 'class_name' ))
		block: [ :arguments |
			self applyFunctionRemoveClass: arguments ]
]

{ #category : 'class-managments' }
ChatPharoBrowserEnvironment >> functionRemoveInstanceVariable [
	"Tool to remove an instance variable from a class."

	^ ChatPharoClient
		name: 'remove_instance_variable'
		description: 'Removes an instance variable from an existing class. Make sure the variable is not used by any methods before removing. This modifies the live system.'
		parameters: (Dictionary
			with: 'type' -> 'object'
			with: 'properties' -> (Dictionary
				with: 'class_name' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The name of the class to modify')
				with: 'variable_name' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The name of the instance variable to remove'))
			with: 'required' -> #( 'class_name' 'variable_name' ))
		block: [ :arguments |
			self applyFunctionRemoveInstanceVariable: arguments ]
]

{ #category : 'method-managments' }
ChatPharoBrowserEnvironment >> functionRemoveMethod [
	"Tool to remove a method from a class."

	^ ChatPharoClient
		name: 'remove_method'
		description: 'Removes a method from a class. This permanently deletes the method from the live system.'
		parameters: (Dictionary
			with: 'type' -> 'object'
			with: 'properties' -> (Dictionary
				with: 'class_name' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The name of the class containing the method')
				with: 'selector' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The selector of the method to remove')
				with: 'side' -> (Dictionary
					with: 'type' -> 'string'
					with: 'enum' -> #( 'instance' 'class' )
					with: 'description' -> 'Whether this is an instance or class method (default: "instance")'))
			with: 'required' -> #( 'class_name' 'selector' ))
		block: [ :arguments |
			self applyFunctionRemoveMethod: arguments ]
]

{ #category : 'initialization' }
ChatPharoBrowserEnvironment >> functionRenameClass [
	"Tool to rename a single class using Pharo's Refactoring Browser."

	^ ChatPharoClient
		name: 'rename_class'
		description: 'Renames a class in the Pharo image. This will update all references to the class throughout the codebase. Use with care as this modifies the live system.'
		parameters: (Dictionary
			with: 'type' -> 'object'
			with: 'properties' -> (Dictionary
				with: 'old_name' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The current name of the class to rename')
				with: 'new_name' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The new name for the class (must start with uppercase)'))
			with: 'required' -> #( 'old_name' 'new_name' ))
		block: [ :arguments |
			self applyFunctionRenameClass: arguments ]
]

{ #category : 'initialization' }
ChatPharoBrowserEnvironment >> functionRenameClassesInPackage [
	"Tool to rename multiple classes in a package using pattern matching."

	^ ChatPharoClient
		name: 'rename_classes_in_package'
		description: 'Renames multiple classes in a package by replacing a substring pattern in their names. For example, replace "Old" with "New" to rename "OldFoo" to "NewFoo". Use dry_run=true first to preview changes. This modifies the live system.'
		parameters: (Dictionary
			with: 'type' -> 'object'
			with: 'properties' -> (Dictionary
				with: 'package' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The name of the package containing the classes to rename')
				with: 'search_pattern' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The substring to search for in class names')
				with: 'replace_pattern' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The string to replace the search pattern with')
				with: 'dry_run' -> (Dictionary
					with: 'type' -> 'boolean'
					with: 'description' -> 'If true, only preview what would be renamed without actually performing the rename. Always use dry_run first to verify the changes.'))
			with: 'required' -> #( 'package' 'search_pattern' 'replace_pattern' ))
		block: [ :arguments |
			self applyFunctionRenameClassesInPackage: arguments ]
]

{ #category : 'method-managments' }
ChatPharoBrowserEnvironment >> functionRenameMethod [
	"Tool to rename a method using refactoring."

	^ ChatPharoClient
		name: 'rename_method'
		description: 'Renames a method using Pharo''s refactoring engine. This will update all senders of the method throughout the codebase. This modifies the live system.'
		parameters: (Dictionary
			with: 'type' -> 'object'
			with: 'properties' -> (Dictionary
				with: 'class_name' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The name of the class containing the method')
				with: 'old_selector' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The current selector of the method')
				with: 'new_selector' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The new selector for the method')
				with: 'side' -> (Dictionary
					with: 'type' -> 'string'
					with: 'enum' -> #( 'instance' 'class' )
					with: 'description' -> 'Whether this is an instance or class method (default: "instance")'))
			with: 'required' -> #( 'class_name' 'old_selector' 'new_selector' ))
		block: [ :arguments |
			self applyFunctionRenameMethod: arguments ]
]

{ #category : 'initialization' }
ChatPharoBrowserEnvironment >> functionSandboxEvaluate [
	"Evaluates code in sandbox with explicit restrictions - always sandboxed regardless of global setting"

	^ ChatPharoClient
		  name: 'sandbox_evaluate'
		  description:
		  'Evaluates a Smalltalk expression in a sandboxed environment with timeout and security restrictions. Always runs in sandbox mode regardless of global settings. Use this for testing potentially risky code safely.'
		  parameters: (Dictionary
				   with: 'type' -> 'object'
				   with: 'properties' -> (Dictionary
						    with: 'expression' -> (Dictionary
								     with: 'type' -> 'string'
								     with:
								     'description'
								     -> 'The Smalltalk expression to evaluate')
						    with: 'timeout_ms' -> (Dictionary
								     with: 'type' -> 'integer'
								     with:
								     'description'
								     -> 'Optional timeout in milliseconds (default: 5000)'))
				   with: 'required' -> #( 'expression' ))
		  block: [ :arguments |
				  | expression sandbox result timeoutMs |
				  expression := arguments at: 'expression'.
				  timeoutMs := arguments at: 'timeout_ms' ifAbsent: [ 5000 ].

				  sandbox := ChatPharoSandbox withDefaults.
				  sandbox timeout: timeoutMs.

				  result := sandbox evaluate: expression.
				  result isSuccess
					  ifTrue: [
							  Dictionary
								  with: 'success' -> true
								  with: 'value' -> result value asString
								  with: 'sandboxed' -> true ]
					  ifFalse: [
							  result hasViolations
								  ifTrue: [
									  Dictionary
										  with: 'success' -> false
										  with: 'blocked' -> true
										  with: 'reason' -> result errorMessage
										  with: 'violations' -> result violations ]
								  ifFalse: [
									  Dictionary
										  with: 'success' -> false
										  with: 'error' -> result errorMessage ] ] ]
]

{ #category : 'class-managments' }
ChatPharoBrowserEnvironment >> functionSetClassComment [
	"Tool to set or update a class comment."

	^ ChatPharoClient
		name: 'set_class_comment'
		description: 'Sets or updates the comment (documentation) of a class. This modifies the live system.'
		parameters: (Dictionary
			with: 'type' -> 'object'
			with: 'properties' -> (Dictionary
				with: 'class_name' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The name of the class to document')
				with: 'comment' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The comment text for the class'))
			with: 'required' -> #( 'class_name' 'comment' ))
		block: [ :arguments |
			self applyFunctionSetClassComment: arguments ]
]

{ #category : 'comment-managments' }
ChatPharoBrowserEnvironment >> functionSetMethodComment [
	"Tool to set or update a method comment."

	^ ChatPharoClient
		name: 'set_method_comment'
		description: 'Sets or updates the comment of a method. In Pharo, a method comment is the first string literal in the method body (enclosed in double quotes). This will replace an existing comment or insert a new one after the method signature. This modifies the live system.'
		parameters: (Dictionary
			with: 'type' -> 'object'
			with: 'properties' -> (Dictionary
				with: 'class_name' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The name of the class containing the method')
				with: 'selector' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The selector of the method')
				with: 'comment' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The comment text for the method (without surrounding double quotes)')
				with: 'side' -> (Dictionary
					with: 'type' -> 'string'
					with: 'enum' -> #( 'instance' 'class' )
					with: 'description' -> 'Whether this is an instance or class method (default: "instance")'))
			with: 'required' -> #( 'class_name' 'selector' 'comment' ))
		block: [ :arguments |
			self applyFunctionSetMethodComment: arguments ]
]

{ #category : 'comment-managments' }
ChatPharoBrowserEnvironment >> functionSetPackageComment [
	"Tool to set or update a package comment."

	^ ChatPharoClient
		name: 'set_package_comment'
		description: 'Sets or updates the comment (documentation) of a package. This modifies the live system.'
		parameters: (Dictionary
			with: 'type' -> 'object'
			with: 'properties' -> (Dictionary
				with: 'package_name' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The name of the package to document')
				with: 'comment' -> (Dictionary
					with: 'type' -> 'string'
					with: 'description' -> 'The comment text for the package'))
			with: 'required' -> #( 'package_name' 'comment' ))
		block: [ :arguments |
			self applyFunctionSetPackageComment: arguments ]
]

{ #category : 'initialization' }
ChatPharoBrowserEnvironment >> initializeWithEnvironment: env [

	browserEnvironment := env.
	tools := {
		         self functionGetPackages.
		         self functionGetClassesInPackages.
		         self functionGetClassDefinitions.
		         self functionGetClassComments.
		         self functionGetClassMethods.
		         self functionGetClassSubclasses.
		         self functionFindMethodsWithSubstring.
		         self functionDescribePackage. 
		
		         self functionRenameClassesInPackage. 
		         self functionCreatePackage. 
		         self functionCreateClass.
		         self functionRemoveClass.
		         self functionRenameClass.
				   self functionAddMethod.
		         self functionRemoveMethod.
		         self functionRenameMethod.

		         self functionMoveClassToPackage.
		         self functionAddInstanceVariable.
		         self functionRemoveInstanceVariable.
		
		         self functionSetClassComment.
		   			self functionGetPackageComments.
		         self functionSetPackageComment.
		         self functionGetMethodComment.
		         self functionSetMethodComment.
		
		         self functionMoveMethodToProtocol.
		
		         self functionGetSandboxStatus.
		         self functionSandboxEvaluate. 
		
		         self functionCreateTemporalTool.
		         self functionDeleteTemporalTool.
		         self functionDeleteAllTemporalTools.
		         self functionListTemporalTools.
		
		         ChatPharoClient toolCheckSyntax.
		         ChatPharoClient toolOpenPlayground.
		
		
		} asOrderedCollection.
	(Smalltalk hasClassNamed: #ChatPharoSkillEnvironment) ifTrue: [
		tools addAll: (Smalltalk at: #ChatPharoSkillEnvironment) new tools ].
(Smalltalk hasClassNamed: #ChatPharoFinderEnvironment) ifTrue: [
		tools addAll: (Smalltalk at: #ChatPharoFinderEnvironment) new tools ].
	tools addAll: ChatPharoToolProvider allTools
]

{ #category : 'initialization' }
ChatPharoBrowserEnvironment >> methodsWithSubstring: substring cappedAt: maximumNumberOfMethods [

	| methods |
	methods := OrderedCollection new.
	self browserEnvironment methodsDo: [ :method |
			(method sourceCode includesSubstring: substring) ifTrue: [
					methods add: method.
					methods size = maximumNumberOfMethods ifTrue: [ ^ methods ] ] ].
	^ methods
]

{ #category : 'method-managments' }
ChatPharoBrowserEnvironment >> normalizeLineEndingsToCr: aString [
	"Normalize incoming code to Pharo-style CR line endings."

	| normalized |
	normalized := aString copyReplaceAll: String crlf with: String cr.
	^ normalized copyReplaceAll: String lf with: String cr
]

{ #category : 'initialization' }
ChatPharoBrowserEnvironment >> packageNamed: packageName [

	| direct normalised |
	packageName ifNil: [ ^ nil ].
	direct := self browserEnvironment packageAt: packageName ifAbsent: [ nil ].
	direct ifNotNil: [ ^ direct ].

	normalised := packageName asLowercase.
	^ self browserEnvironment packages detect: [ :pkg | pkg name asLowercase = normalised ] ifNone: [ nil ]
]

{ #category : 'initialization' }
ChatPharoBrowserEnvironment >> response: resultKey collect: block forClassesNamed: classNames [

	| resultPerClass classesNotFound |
	resultPerClass := Dictionary new.
	classesNotFound := OrderedCollection new.

	classNames do: [ :className |
			(self classNamed: className)
				ifNotNil: [ :class |
				resultPerClass at: className put: (block value: class) ]
				ifNil: [ classesNotFound add: className ] ].

	^ Dictionary
		  with: resultKey -> resultPerClass
		  with:
		  'nonexistent_or_outside_scope_classes' -> classesNotFound asArray
]

{ #category : 'accessing' }
ChatPharoBrowserEnvironment >> tools [

	^ tools
]

{ #category : 'accessing' }
ChatPharoBrowserEnvironment >> tools: anObject [

	tools := anObject
]
