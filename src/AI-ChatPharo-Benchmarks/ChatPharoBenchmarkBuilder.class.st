"
Extracts a `ChatPharoBenchmark` from a **live Pharo package**.

This is the ""dynamic"" half of the system: the benchmark follows whatever
the package currently contains. Rebuild at any time and the gold data is
refreshed — no hand-maintained dataset.

Selection is configurable:

* `packageNamed:` — which package to harvest (required).
* `includeClassSide` — default false (instance side is more interesting to
  benchmark; class-side methods are often trivial builders).
* `includeProtocol:` / `excludeProtocol:` — filter by Pharo method protocol
  (e.g. skip `'initialization'` or `'tests'`).
* `selectorFilter:` — arbitrary block `[ :selector | Boolean ]`.
* `maxCases:` — cap the number of cases (useful for a smoke run).
* `maxSourceSize:` — skip methods whose source is too long for useful
  benchmarking.
* `minSourceSize:` — skip trivial getters/setters (set to 0 to keep them).
* `promptTemplate:` — override the `ChatPharoBenchmarkPromptTemplate`.
* `kind:` — which kind of cases to emit (`#methodGeneration`, `#methodExplanation`, …).

Case identity
-------------
Every case gets a deterministic id: `<package>/<Class>/<selector>/<kind>`.
Re-running the builder on an unchanged package yields identical ids, so
historical reports remain comparable across versions — and diffs are meaningful
when the package does change.

Example
-------
```smalltalk
bench := ChatPharoBenchmarkBuilder new
    packageNamed: 'AI-ChatPharo-Tools';
    kind: #methodGeneration;
    excludeProtocol: 'initialization';
    maxCases: 50;
    build.
```
"
Class {
	#name : 'ChatPharoBenchmarkBuilder',
	#superclass : 'Object',
	#instVars : [
		'packageName',
		'includeClassSide',
		'includeProtocols',
		'excludeProtocols',
		'selectorFilter',
		'maxCases',
		'maxSourceSize',
		'minSourceSize',
		'promptTemplate',
		'kind',
		'includeClasses',
		'excludeClasses'
	],
	#category : 'AI-ChatPharo-Benchmarks',
	#package : 'AI-ChatPharo-Benchmarks',
	#tag : 'Builder'
}

{ #category : 'instance creation' }
ChatPharoBenchmarkBuilder class >> fromPackage: aPackageName [

	^ self new
		  packageNamed: aPackageName;
		  yourself
]

{ #category : 'building' }
ChatPharoBenchmarkBuilder >> build [
	"Walk the package and produce a fresh `ChatPharoBenchmark`.
	 Raises if the package cannot be resolved."

	| package bench classes |
	packageName ifNil: [ ^ self error: 'packageName is required' ].
	package := self resolvePackage: packageName.
	package ifNil: [ ^ self error: 'Package not found: ' , packageName asString ].

	bench := ChatPharoBenchmark new
		         name: packageName , '-' , kind asString;
		         sourcePackage: packageName;
		         description: 'Benchmark dynamically extracted from Pharo package ' , packageName;
		         version: DateAndTime now asString;
		         yourself.
	bench metadata
		at: 'builderOptions' put: self asOptionsDictionary;
		at: 'pharoImageVersion' put: (Smalltalk globals at: #SystemVersion ifAbsent: [ 'unknown' ]) asString.

	classes := self classesOf: package.
	classes do: [ :cls |
		(self acceptsClass: cls) ifTrue: [ self addCasesFromClass: cls toBench: bench ] ].

	^ bench
]

{ #category : 'building' }
ChatPharoBenchmarkBuilder >> addCasesFromClass: aClass toBench: aBenchmark [

	| candidates count |
	count := aBenchmark cases size.
	candidates := self methodsOf: aClass.
	candidates do: [ :method |
		(maxCases notNil and: [ aBenchmark cases size >= maxCases ]) ifTrue: [ ^ self ].
		(self acceptsMethod: method)
			ifTrue: [
				| case |
				case := self caseFromMethod: method ofClass: aClass.
				case ifNotNil: [ aBenchmark addCase: case ] ] ].
	count = aBenchmark cases size ifTrue: [ ^ self ]
]

{ #category : 'private' }
ChatPharoBenchmarkBuilder >> asOptionsDictionary [

	^ Dictionary new
		  at: 'packageName' put: packageName;
		  at: 'kind' put: kind asString;
		  at: 'includeClassSide' put: includeClassSide;
		  at: 'includeProtocols' put: (includeProtocols ifNil: [ #(  ) ]) asArray;
		  at: 'excludeProtocols' put: (excludeProtocols ifNil: [ #(  ) ]) asArray;
		  at: 'maxCases' put: maxCases;
		  at: 'maxSourceSize' put: maxSourceSize;
		  at: 'minSourceSize' put: minSourceSize;
		  yourself
]

{ #category : 'private' }
ChatPharoBenchmarkBuilder >> acceptsClass: aClass [

	includeClasses ifNotNil: [
		(includeClasses includes: aClass name asString) ifFalse: [ ^ false ] ].
	excludeClasses ifNotNil: [
		(excludeClasses includes: aClass name asString) ifTrue: [ ^ false ] ].
	^ true
]

{ #category : 'private' }
ChatPharoBenchmarkBuilder >> acceptsMethod: aMethod [

	| source protocol |
	source := self sourceOf: aMethod.
	source ifNil: [ ^ false ].
	(minSourceSize notNil and: [ source size < minSourceSize ]) ifTrue: [ ^ false ].
	(maxSourceSize notNil and: [ source size > maxSourceSize ]) ifTrue: [ ^ false ].

	protocol := (aMethod respondsTo: #protocol)
		            ifTrue: [ aMethod protocol asString ]
		            ifFalse: [ '' ].
	includeProtocols ifNotNil: [
		(includeProtocols includes: protocol) ifFalse: [ ^ false ] ].
	excludeProtocols ifNotNil: [
		(excludeProtocols includes: protocol) ifTrue: [ ^ false ] ].

	selectorFilter ifNotNil: [
		(selectorFilter value: aMethod selector) ifFalse: [ ^ false ] ].

	^ true
]

{ #category : 'private' }
ChatPharoBenchmarkBuilder >> caseFromMethod: aMethod ofClass: aClass [

	| case source protocol ivars comment id |
	source := self sourceOf: aMethod.
	source ifNil: [ ^ nil ].
	protocol := (aMethod respondsTo: #protocol)
		            ifTrue: [ aMethod protocol asString ]
		            ifFalse: [ 'accessing' ].
	ivars := aClass instanceSide instVarNames asArray
		         collect: [ :each | each asString ].
	comment := [ aClass instanceSide comment ifNil: [ '' ] ]
		           on: Error
		           do: [ '' ].
	id := (String streamContents: [ :s |
			       s
				       nextPutAll: packageName;
				       nextPutAll: '/';
				       nextPutAll: aClass name asString;
				       nextPutAll: '/';
				       nextPutAll: aMethod selector asString;
				       nextPutAll: '/';
				       nextPutAll: kind asString ]).
	case := ChatPharoBenchmarkCase new
		        id: id;
		        kind: kind;
		        className: aClass name asString;
		        selector: aMethod selector asString;
		        protocol: protocol;
		        superclassName: aClass instanceSide superclass name asString;
		        instanceVariableNames: ivars;
		        classComment: (comment first: (comment size min: 1500));
		        goldSource: source;
		        tags: (Array with: protocol);
		        yourself.
	case prompt: (self promptTemplate renderFor: case).
	^ case
]

{ #category : 'private' }
ChatPharoBenchmarkBuilder >> classesOf: aPackage [

	(aPackage respondsTo: #definedClasses) ifTrue: [ ^ aPackage definedClasses ].
	(aPackage respondsTo: #classes) ifTrue: [ ^ aPackage classes ].
	^ #(  )
]

{ #category : 'accessing' }
ChatPharoBenchmarkBuilder >> excludeClasses: aCollection [

	excludeClasses := aCollection asArray collect: [ :each | each asString ]
]

{ #category : 'accessing' }
ChatPharoBenchmarkBuilder >> excludeProtocol: aString [

	excludeProtocols := (excludeProtocols ifNil: [ OrderedCollection new ])
		                    add: aString;
		                    yourself
]

{ #category : 'accessing' }
ChatPharoBenchmarkBuilder >> excludeProtocols: aCollection [

	excludeProtocols := aCollection asArray
]

{ #category : 'accessing' }
ChatPharoBenchmarkBuilder >> includeClassSide [

	^ includeClassSide
]

{ #category : 'accessing' }
ChatPharoBenchmarkBuilder >> includeClassSide: aBoolean [

	includeClassSide := aBoolean
]

{ #category : 'accessing' }
ChatPharoBenchmarkBuilder >> includeClasses: aCollection [

	includeClasses := aCollection asArray collect: [ :each | each asString ]
]

{ #category : 'accessing' }
ChatPharoBenchmarkBuilder >> includeProtocol: aString [

	includeProtocols := (includeProtocols ifNil: [ OrderedCollection new ])
		                    add: aString;
		                    yourself
]

{ #category : 'accessing' }
ChatPharoBenchmarkBuilder >> includeProtocols: aCollection [

	includeProtocols := aCollection asArray
]

{ #category : 'initialization' }
ChatPharoBenchmarkBuilder >> initialize [

	super initialize.
	includeClassSide := false.
	includeProtocols := nil.
	excludeProtocols := #( 'initialization' 'tests' 'testing' 'printing' ).
	minSourceSize := 40.
	maxSourceSize := 4000.
	kind := #methodGeneration
]

{ #category : 'accessing' }
ChatPharoBenchmarkBuilder >> kind [

	^ kind
]

{ #category : 'accessing' }
ChatPharoBenchmarkBuilder >> kind: aSymbol [

	kind := aSymbol asSymbol
]

{ #category : 'accessing' }
ChatPharoBenchmarkBuilder >> maxCases [

	^ maxCases
]

{ #category : 'accessing' }
ChatPharoBenchmarkBuilder >> maxCases: anInteger [

	maxCases := anInteger
]

{ #category : 'accessing' }
ChatPharoBenchmarkBuilder >> maxSourceSize [

	^ maxSourceSize
]

{ #category : 'accessing' }
ChatPharoBenchmarkBuilder >> maxSourceSize: anInteger [

	maxSourceSize := anInteger
]

{ #category : 'private' }
ChatPharoBenchmarkBuilder >> methodsOf: aClass [

	| inst cls |
	inst := (aClass instanceSide respondsTo: #methods)
		        ifTrue: [ aClass instanceSide methods ]
		        ifFalse: [ #(  ) ].
	includeClassSide ifFalse: [ ^ inst ].
	cls := (aClass classSide respondsTo: #methods)
		       ifTrue: [ aClass classSide methods ]
		       ifFalse: [ #(  ) ].
	^ inst , cls
]

{ #category : 'accessing' }
ChatPharoBenchmarkBuilder >> minSourceSize [

	^ minSourceSize
]

{ #category : 'accessing' }
ChatPharoBenchmarkBuilder >> minSourceSize: anInteger [

	minSourceSize := anInteger
]

{ #category : 'accessing' }
ChatPharoBenchmarkBuilder >> packageName [

	^ packageName
]

{ #category : 'accessing' }
ChatPharoBenchmarkBuilder >> packageNamed: aString [

	packageName := aString asString
]

{ #category : 'accessing' }
ChatPharoBenchmarkBuilder >> promptTemplate [

	^ promptTemplate ifNil: [ promptTemplate := ChatPharoBenchmarkPromptTemplate default ]
]

{ #category : 'accessing' }
ChatPharoBenchmarkBuilder >> promptTemplate: aTemplate [

	promptTemplate := aTemplate
]

{ #category : 'private' }
ChatPharoBenchmarkBuilder >> resolvePackage: aName [
	"Try the Pharo 13/14 package organisers, in order of preference."

	| organizer |
	organizer := Smalltalk globals at: #RPackageOrganizer ifAbsent: [ nil ].
	organizer ifNotNil: [
		| package |
		package := [ organizer default packageNamed: aName ifAbsent: [ nil ] ]
			           on: Error
			           do: [ nil ].
		package ifNotNil: [ ^ package ] ].

	organizer := Smalltalk globals at: #PackageOrganizer ifAbsent: [ nil ].
	organizer ifNotNil: [
		| package |
		package := [ organizer default packageNamed: aName ifAbsent: [ nil ] ]
			           on: Error
			           do: [ nil ].
		package ifNotNil: [ ^ package ] ].

	^ nil
]

{ #category : 'accessing' }
ChatPharoBenchmarkBuilder >> selectorFilter: aBlock [

	selectorFilter := aBlock
]

{ #category : 'private' }
ChatPharoBenchmarkBuilder >> sourceOf: aMethod [

	^ [
	  (aMethod respondsTo: #sourceCode)
		  ifTrue: [ aMethod sourceCode ]
		  ifFalse: [ (aMethod respondsTo: #source)
			  ifTrue: [ aMethod source ]
			  ifFalse: [ nil ] ] ]
		  on: Error
		  do: [ nil ]
]
