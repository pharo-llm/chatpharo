"
A **ChatPharoBenchmark** is a named, versioned bundle of benchmark cases that
have been *dynamically* extracted from a Pharo package. It is the ""gold"" —
the ground truth the LLM is asked to reproduce.

Key idea: the benchmark is *not* a hard-coded dataset. It is rebuilt on demand
from the live image, so whenever the source package evolves the benchmark
follows automatically. Use `ChatPharoBenchmarkBuilder` to build one.

Each case (`ChatPharoBenchmarkCase`) represents a single atomic task
(one method to generate, one method to explain, one class to synthesise, …).


Responsibilities
----------------
* Hold metadata about provenance (source package, creation time, Pharo image
  version, baseline commit).
* Hold an ordered collection of `ChatPharoBenchmarkCase`.
* Serialise / deserialise to/from a plain `Dictionary` for persistence by
  `ChatPharoBenchmarkStore`.

```smalltalk
bench := ChatPharoBenchmarkBuilder new
    packageNamed: 'AI-ChatPharo';
    build.
bench cases size.
```
"
Class {
	#name : 'ChatPharoBenchmark',
	#superclass : 'Object',
	#instVars : [
		'name',
		'sourcePackage',
		'createdAt',
		'version',
		'description',
		'cases',
		'metadata'
	],
	#category : 'AI-ChatPharo-Benchmarks',
	#package : 'AI-ChatPharo-Benchmarks',
	#tag : 'Core'
}

{ #category : 'instance creation' }
ChatPharoBenchmark class >> fromDictionary: aDictionary [

	| bench |
	bench := self new.
	bench name: (aDictionary at: 'name' ifAbsent: [ 'unnamed' ]).
	bench sourcePackage: (aDictionary at: 'sourcePackage' ifAbsent: [ nil ]).
	bench version: (aDictionary at: 'version' ifAbsent: [ '0' ]).
	bench description: (aDictionary at: 'description' ifAbsent: [ '' ]).
	bench createdAt: (aDictionary at: 'createdAt' ifAbsent: [ DateAndTime now asString ]).
	bench metadata: (aDictionary at: 'metadata' ifAbsent: [ Dictionary new ]).
	bench cases: ((aDictionary at: 'cases' ifAbsent: [ #(  ) ])
		collect: [ :dict | ChatPharoBenchmarkCase fromDictionary: dict ]) asOrderedCollection.
	^ bench
]

{ #category : 'instance creation' }
ChatPharoBenchmark class >> named: aName [

	^ self new
		  name: aName;
		  yourself
]

{ #category : 'adding' }
ChatPharoBenchmark >> addCase: aCase [

	cases add: aCase.
	^ aCase
]

{ #category : 'accessing' }
ChatPharoBenchmark >> asDictionary [

	^ Dictionary new
		  at: 'name' put: (name ifNil: [ 'unnamed' ]);
		  at: 'sourcePackage' put: sourcePackage;
		  at: 'version' put: version;
		  at: 'description' put: (description ifNil: [ '' ]);
		  at: 'createdAt' put: createdAt asString;
		  at: 'metadata' put: metadata;
		  at: 'cases' put: (cases collect: [ :c | c asDictionary ]) asArray;
		  yourself
]

{ #category : 'accessing' }
ChatPharoBenchmark >> cases [

	^ cases
]

{ #category : 'accessing' }
ChatPharoBenchmark >> cases: aCollection [

	cases := aCollection asOrderedCollection
]

{ #category : 'accessing' }
ChatPharoBenchmark >> createdAt [

	^ createdAt
]

{ #category : 'accessing' }
ChatPharoBenchmark >> createdAt: anObject [

	createdAt := anObject
]

{ #category : 'accessing' }
ChatPharoBenchmark >> description [

	^ description
]

{ #category : 'accessing' }
ChatPharoBenchmark >> description: anObject [

	description := anObject
]

{ #category : 'initialization' }
ChatPharoBenchmark >> initialize [

	super initialize.
	name := 'unnamed'.
	sourcePackage := nil.
	version := '1'.
	description := ''.
	createdAt := DateAndTime now.
	metadata := Dictionary new.
	cases := OrderedCollection new
]

{ #category : 'accessing' }
ChatPharoBenchmark >> metadata [

	^ metadata
]

{ #category : 'accessing' }
ChatPharoBenchmark >> metadata: anObject [

	metadata := anObject ifNil: [ Dictionary new ]
]

{ #category : 'accessing' }
ChatPharoBenchmark >> name [

	^ name
]

{ #category : 'accessing' }
ChatPharoBenchmark >> name: anObject [

	name := anObject
]

{ #category : 'printing' }
ChatPharoBenchmark >> printOn: aStream [

	super printOn: aStream.
	aStream
		nextPutAll: '(''';
		nextPutAll: name asString;
		nextPutAll: ''', ';
		print: cases size;
		nextPutAll: ' cases)'
]

{ #category : 'accessing' }
ChatPharoBenchmark >> size [

	^ cases size
]

{ #category : 'accessing' }
ChatPharoBenchmark >> sourcePackage [

	^ sourcePackage
]

{ #category : 'accessing' }
ChatPharoBenchmark >> sourcePackage: anObject [

	sourcePackage := anObject
]

{ #category : 'accessing' }
ChatPharoBenchmark >> version [

	^ version
]

{ #category : 'accessing' }
ChatPharoBenchmark >> version: anObject [

	version := anObject asString
]
