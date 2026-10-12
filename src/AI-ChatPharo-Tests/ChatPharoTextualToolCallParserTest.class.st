Class {
	#name : 'ChatPharoTextualToolCallParserTest',
	#superclass : 'TestCase',
	#instVars : [
		'parser'
	],
	#category : 'AI-ChatPharo-Tests-Tools',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Tools'
}

{ #category : 'running' }
ChatPharoTextualToolCallParserTest >> setUp [

	super setUp.
	parser := ChatPharoTextualToolCallParser knownToolNames: #( 'find_senders' 'get_packages' )
]

{ #category : 'tests' }
ChatPharoTextualToolCallParserTest >> testFencedJsonCallIsRecovered [

	| calls |
	calls := parser callsIn: '```json
{"name": "get_packages", "arguments": {}}
```'.
	self assert: calls size equals: 1.
	self assert: ((calls first at: 'function') at: 'name') equals: 'get_packages'
]

{ #category : 'tests' }
ChatPharoTextualToolCallParserTest >> testJsonNamingAnUnknownToolIsAnOrdinaryAnswer [

	self assert: (parser callsIn: '{"name": "Omar", "arguments": {"age": 3}}') isEmpty
]

{ #category : 'tests' }
ChatPharoTextualToolCallParserTest >> testPlainJsonCallIsRecovered [

	| calls function |
	calls := parser callsIn: '{"name": "find_senders", "arguments": {"selector": "printOn:"}}'.
	self assert: calls size equals: 1.
	function := calls first at: 'function'.
	self assert: (function at: 'name') equals: 'find_senders'.
	self assert: ((STONJSON fromString: (function at: 'arguments')) at: 'selector') equals: 'printOn:'
]

{ #category : 'tests' }
ChatPharoTextualToolCallParserTest >> testProseAroundJsonIsAnOrdinaryAnswer [

	self assert: (parser callsIn: 'You could call {"name": "find_senders", "arguments": {}} to do that.') isEmpty.
	self assert: (parser callsIn: 'Hello!') isEmpty.
	self assert: (parser callsIn: nil) isEmpty
]

{ #category : 'tests' }
ChatPharoTextualToolCallParserTest >> testSeveralTaggedCallsAreRecoveredInOrder [

	| calls |
	calls := parser callsIn: '<tool_call>{"name": "get_packages", "arguments": {}}</tool_call>
<tool_call>{"name": "find_senders", "parameters": {"selector": "foo"}}</tool_call>'.
	self assert: (calls collect: [ :each | (each at: 'function') at: 'name' ]) asArray equals: #( 'get_packages' 'find_senders' ).
	self assert: (calls collect: [ :each | each at: 'id' ]) asSet size equals: 2
]
