"
Smoke tests for the builder. These exercise the live Pharo package
organiser; they should always find the `AI-ChatPharo-Benchmarks` package we
just loaded.
"
Class {
	#name : 'ChatPharoBenchmarkBuilderTest',
	#superclass : 'TestCase',
	#category : 'AI-ChatPharo-Benchmarks-Tests',
	#package : 'AI-ChatPharo-Benchmarks-Tests'
}

{ #category : 'tests' }
ChatPharoBenchmarkBuilderTest >> testAsDictionaryRoundTrip [

	| bench dict loaded |
	bench := ChatPharoBenchmark new
		         name: 'roundtrip';
		         sourcePackage: 'X';
		         yourself.
	bench addCase: (ChatPharoBenchmarkCase new
			 id: 'X/Foo/bar/methodGeneration';
			 className: 'Foo';
			 selector: 'bar';
			 goldSource: 'bar ^ 1';
			 prompt: 'Implement bar';
			 yourself).
	dict := bench asDictionary.
	loaded := ChatPharoBenchmark fromDictionary: dict.
	self assert: loaded name equals: 'roundtrip'.
	self assert: loaded cases size equals: 1.
	self assert: loaded cases first goldSource equals: 'bar ^ 1'
]

{ #category : 'tests' }
ChatPharoBenchmarkBuilderTest >> testBuildSelfPackage [
	"We can always benchmark our own package."

	| bench |
	bench := ChatPharoBenchmarkBuilder new
		         packageNamed: 'AI-ChatPharo-Benchmarks';
		         minSourceSize: 0;
		         maxCases: 3;
		         build.
	self assert: bench sourcePackage equals: 'AI-ChatPharo-Benchmarks'.
	self deny: bench cases isEmpty.
	bench cases do: [ :c |
		self assert: c className isNotNil.
		self assert: c selector isNotNil.
		self assert: c goldSource notEmpty.
		self assert: c prompt notEmpty ]
]

{ #category : 'tests' }
ChatPharoBenchmarkBuilderTest >> testUnknownPackageIsError [

	self
		should: [
			ChatPharoBenchmarkBuilder new
				packageNamed: 'This-Package-Really-Does-Not-Exist-123';
				build ]
		raise: Error
]
