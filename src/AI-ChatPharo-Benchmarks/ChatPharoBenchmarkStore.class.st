"
File-system persistence for benchmarks and reports.

All persistence goes through JSON (`STONJSON`) via the `#asDictionary` of the
entities. This format was chosen because it is:

* vendor-agnostic (consumable from notebooks, dashboards, CI scripts),
* diff-friendly (line-by-line diffable when pretty-printed),
* supported out of the box by `ChatPharoTool` which already uses `STONJSON`.

The default storage root is `FileLocator documents / 'chatpharo-benchmarks'`.
Users can override it with `#root:`.

Layout on disk
--------------
```
<root>/
  benchmarks/
    <name>-<version>.json           # one benchmark
  reports/
    <benchmarkName>/
      <strategy>-<model>-<isoTimestamp>.json
```

The naming scheme encodes every dimension that influences the outcome, so two
reports *never* collide unless they describe literally the same run.
"
Class {
	#name : 'ChatPharoBenchmarkStore',
	#superclass : 'Object',
	#instVars : [
		'root'
	],
	#category : 'AI-ChatPharo-Benchmarks',
	#package : 'AI-ChatPharo-Benchmarks',
	#tag : 'Persistence'
}

{ #category : 'instance creation' }
ChatPharoBenchmarkStore class >> default [

	^ self new
]

{ #category : 'instance creation' }
ChatPharoBenchmarkStore class >> root: aFileReference [

	^ self new root: aFileReference; yourself
]

{ #category : 'loading' }
ChatPharoBenchmarkStore >> loadBenchmarkFrom: aFileReference [

	| ref dict |
	ref := aFileReference asFileReference.
	ref exists ifFalse: [ ^ self error: 'No such benchmark file: ' , ref fullName ].
	dict := STONJSON fromString: ref contents.
	^ ChatPharoBenchmark fromDictionary: dict
]

{ #category : 'loading' }
ChatPharoBenchmarkStore >> loadReportFrom: aFileReference [

	| ref dict |
	ref := aFileReference asFileReference.
	ref exists ifFalse: [ ^ self error: 'No such report file: ' , ref fullName ].
	dict := STONJSON fromString: ref contents.
	^ ChatPharoBenchmarkReport fromDictionary: dict
]

{ #category : 'private' }
ChatPharoBenchmarkStore >> normalizeFileName: aString [
	"Keep letters, digits, dashes, underscores and dots. Replace the rest."

	^ String streamContents: [ :s |
		  aString do: [ :c |
			  (c isLetter or: [
				   c isDigit or: [ '-_.' includes: c ] ])
				  ifTrue: [ s nextPut: c ]
				  ifFalse: [ s nextPut: $_ ] ] ]
]

{ #category : 'accessing' }
ChatPharoBenchmarkStore >> root [

	^ root ifNil: [
		  root := FileLocator documents asFileReference / 'chatpharo-benchmarks' ]
]

{ #category : 'accessing' }
ChatPharoBenchmarkStore >> root: aFileReference [

	root := aFileReference asFileReference
]

{ #category : 'saving' }
ChatPharoBenchmarkStore >> save: aBenchmark [

	| dir file json |
	dir := self root / 'benchmarks'.
	dir ensureCreateDirectory.
	file := dir / (self normalizeFileName:
		                (aBenchmark name , '-' , aBenchmark version , '.json')).
	json := STONJSON toString: aBenchmark asDictionary.
	file writeStreamDo: [ :s | s nextPutAll: json ].
	^ file
]

{ #category : 'saving' }
ChatPharoBenchmarkStore >> saveReport: aReport [

	| dir file json fileName ts |
	dir := self root / 'reports' / (self normalizeFileName: aReport benchmarkName asString).
	dir ensureCreateDirectory.
	ts := aReport startedAt ifNil: [ DateAndTime now ].
	fileName := String streamContents: [ :s |
		            s
			            nextPutAll: aReport strategy asString;
			            nextPutAll: '-';
			            nextPutAll: (aReport modelName ifNil: [ 'unknown' ]) asString;
			            nextPutAll: '-';
			            nextPutAll: ts asString;
			            nextPutAll: '.json' ].
	file := dir / (self normalizeFileName: fileName).
	json := STONJSON toString: aReport asDictionary.
	file writeStreamDo: [ :s | s nextPutAll: json ].
	^ file
]
