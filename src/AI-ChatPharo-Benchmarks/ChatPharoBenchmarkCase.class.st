"
A single atomic benchmark case — the smallest unit we can send to an LLM and
compare against a known ground truth.

A case is *kind-aware*. `kind` is one of:

* `#methodGeneration` — generate a method body from signature + class context.
* `#methodExplanation` — produce a natural-language explanation of a method.
* `#classGeneration` — produce an entire class definition from description.
* `#snippetCompletion` — free-form code continuation.

Fields
------
* `id` – stable identifier (sha-style, used for re-running only failed cases).
* `kind` – as described above.
* `className` / `selector` / `protocol` – provenance inside the source package.
* `superclassName`, `instanceVariableNames`, `classComment` – context fed to
  the prompt so the LLM has enough to regenerate the method faithfully.
* `goldSource` – the original source we compare against (gold data).
* `prompt` – the fully-rendered prompt passed to the LLM.
* `tags` – free-form strings (e.g. 'fast', 'side-effectful'). Used for
  filtering inside the runner and for reporting.

The case is intentionally a dumb data holder: building is done in
`ChatPharoBenchmarkBuilder`, scoring in `ChatPharoBenchmarkScorer`, execution
in `ChatPharoBenchmarkRunner`.
"
Class {
	#name : 'ChatPharoBenchmarkCase',
	#superclass : 'Object',
	#instVars : [
		'id',
		'kind',
		'className',
		'selector',
		'protocol',
		'superclassName',
		'instanceVariableNames',
		'classComment',
		'goldSource',
		'prompt',
		'tags',
		'metadata'
	],
	#category : 'AI-ChatPharo-Benchmarks',
	#package : 'AI-ChatPharo-Benchmarks',
	#tag : 'Core'
}

{ #category : 'instance creation' }
ChatPharoBenchmarkCase class >> fromDictionary: aDictionary [

	^ self new
		  id: (aDictionary at: 'id' ifAbsent: [ nil ]);
		  kind: (aDictionary at: 'kind' ifAbsent: [ 'methodGeneration' ]) asSymbol;
		  className: (aDictionary at: 'className' ifAbsent: [ nil ]);
		  selector: (aDictionary at: 'selector' ifAbsent: [ nil ]);
		  protocol: (aDictionary at: 'protocol' ifAbsent: [ nil ]);
		  superclassName: (aDictionary at: 'superclassName' ifAbsent: [ nil ]);
		  instanceVariableNames: (aDictionary at: 'instanceVariableNames' ifAbsent: [ #(  ) ]) asArray;
		  classComment: (aDictionary at: 'classComment' ifAbsent: [ '' ]);
		  goldSource: (aDictionary at: 'goldSource' ifAbsent: [ '' ]);
		  prompt: (aDictionary at: 'prompt' ifAbsent: [ '' ]);
		  tags: (aDictionary at: 'tags' ifAbsent: [ #(  ) ]) asArray;
		  metadata: (aDictionary at: 'metadata' ifAbsent: [ Dictionary new ]);
		  yourself
]

{ #category : 'accessing' }
ChatPharoBenchmarkCase >> asDictionary [

	^ Dictionary new
		  at: 'id' put: id;
		  at: 'kind' put: kind asString;
		  at: 'className' put: className;
		  at: 'selector' put: selector;
		  at: 'protocol' put: protocol;
		  at: 'superclassName' put: superclassName;
		  at: 'instanceVariableNames' put: (instanceVariableNames ifNil: [ #(  ) ]) asArray;
		  at: 'classComment' put: (classComment ifNil: [ '' ]);
		  at: 'goldSource' put: (goldSource ifNil: [ '' ]);
		  at: 'prompt' put: (prompt ifNil: [ '' ]);
		  at: 'tags' put: (tags ifNil: [ #(  ) ]) asArray;
		  at: 'metadata' put: (metadata ifNil: [ Dictionary new ]);
		  yourself
]

{ #category : 'accessing' }
ChatPharoBenchmarkCase >> classComment [

	^ classComment
]

{ #category : 'accessing' }
ChatPharoBenchmarkCase >> classComment: anObject [

	classComment := anObject
]

{ #category : 'accessing' }
ChatPharoBenchmarkCase >> className [

	^ className
]

{ #category : 'accessing' }
ChatPharoBenchmarkCase >> className: anObject [

	className := anObject
]

{ #category : 'accessing' }
ChatPharoBenchmarkCase >> goldSource [

	^ goldSource
]

{ #category : 'accessing' }
ChatPharoBenchmarkCase >> goldSource: anObject [

	goldSource := anObject
]

{ #category : 'accessing' }
ChatPharoBenchmarkCase >> id [

	^ id
]

{ #category : 'accessing' }
ChatPharoBenchmarkCase >> id: anObject [

	id := anObject
]

{ #category : 'initialization' }
ChatPharoBenchmarkCase >> initialize [

	super initialize.
	kind := #methodGeneration.
	tags := #(  ).
	instanceVariableNames := #(  ).
	metadata := Dictionary new.
	classComment := ''.
	goldSource := ''.
	prompt := ''
]

{ #category : 'accessing' }
ChatPharoBenchmarkCase >> instanceVariableNames [

	^ instanceVariableNames
]

{ #category : 'accessing' }
ChatPharoBenchmarkCase >> instanceVariableNames: anObject [

	instanceVariableNames := anObject asArray
]

{ #category : 'accessing' }
ChatPharoBenchmarkCase >> kind [

	^ kind
]

{ #category : 'accessing' }
ChatPharoBenchmarkCase >> kind: aSymbol [

	kind := aSymbol asSymbol
]

{ #category : 'accessing' }
ChatPharoBenchmarkCase >> metadata [

	^ metadata
]

{ #category : 'accessing' }
ChatPharoBenchmarkCase >> metadata: anObject [

	metadata := anObject ifNil: [ Dictionary new ]
]

{ #category : 'printing' }
ChatPharoBenchmarkCase >> printOn: aStream [

	super printOn: aStream.
	aStream
		nextPutAll: '(';
		nextPutAll: kind asString;
		nextPutAll: ': ';
		nextPutAll: (className ifNil: [ '?' ]);
		nextPutAll: '>>';
		nextPutAll: (selector ifNil: [ '?' ]);
		nextPutAll: ')'
]

{ #category : 'accessing' }
ChatPharoBenchmarkCase >> prompt [

	^ prompt
]

{ #category : 'accessing' }
ChatPharoBenchmarkCase >> prompt: anObject [

	prompt := anObject
]

{ #category : 'accessing' }
ChatPharoBenchmarkCase >> protocol [

	^ protocol
]

{ #category : 'accessing' }
ChatPharoBenchmarkCase >> protocol: anObject [

	protocol := anObject
]

{ #category : 'accessing' }
ChatPharoBenchmarkCase >> selector [

	^ selector
]

{ #category : 'accessing' }
ChatPharoBenchmarkCase >> selector: anObject [

	selector := anObject
]

{ #category : 'accessing' }
ChatPharoBenchmarkCase >> superclassName [

	^ superclassName
]

{ #category : 'accessing' }
ChatPharoBenchmarkCase >> superclassName: anObject [

	superclassName := anObject
]

{ #category : 'accessing' }
ChatPharoBenchmarkCase >> tags [

	^ tags
]

{ #category : 'accessing' }
ChatPharoBenchmarkCase >> tags: anObject [

	tags := anObject asArray
]
