Class {
	#name : 'ChatPharoOptimizationTest',
	#superclass : 'TestCase',
	#instVars : [
		'registry',
		'history'
	],
	#category : 'AI-ChatPharo-Tests-Core',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Core'
}

{ #category : 'running' }
ChatPharoOptimizationTest >> setUp [

	super setUp.
	registry := ChatPharoSkillRegistry new.
	history := ChatPharoHistory new
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testApplyToolFunctionReturnsErrorForMissing [

	| tool result |
	tool := ChatPharoTool ollamaWithSystem: 'test' tools: nil.
	result := tool applyToolFunction: 'noSuchFunc' arguments: Dictionary new.
	self assert: (result includesKey: 'error')
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testApplyToolFunctionUsesIndex [

	| tool client result |
	client := ChatPharoClient
		name: 'myFunc'
		description: 'test'
		parameters: (Dictionary with: 'type' -> 'object' with: 'properties' -> Dictionary new)
		block: [ :args | Dictionary with: 'result' -> 'success' ].
	tool := ChatPharoTool ollamaWithSystem: 'test' tools: { client }.
	result := tool applyToolFunction: 'myFunc' arguments: Dictionary new.
	self assert: (result at: 'result') equals: 'success'
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testCachedClientInvalidatedOnBaseURLChange [
	"Changing baseURL should force a new client."

	| tool first |
	tool := ChatPharoTool ollamaWithSystem: 'test' tools: nil.
	first := tool cachedClient.
	tool baseURL: (ZnUrl fromString: 'http://localhost:9999/v1').
	self deny: tool cachedClient identicalTo: first
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testCachedClientIsReused [
	"cachedClient should return the same ZnClient instance on repeated calls."

	| tool first second |
	tool := ChatPharoTool ollamaWithSystem: 'test' tools: nil.
	first := tool cachedClient.
	second := tool cachedClient.
	self assert: first identicalTo: second
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testHasSkillNamedUsesIndex [

	self assert: (registry hasSkillNamed: 'TestSkill').
	self deny: (registry hasSkillNamed: 'NonExistent')
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testHistoryEmptyPromptPrefixCached [

	| first second |
	first := history asPromptPrefix.
	second := history asPromptPrefix.
	self assert: first identicalTo: second.
	self assert: first equals: ''
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testHistoryPromptPrefixInvalidatedOnAddMessage [

	| first second |
	history addUser: 'Hello'.
	first := history asPromptPrefix.
	history addAssistant: 'World'.
	second := history asPromptPrefix.
	self deny: first identicalTo: second.
	self assert: (second includesSubstring: 'World')
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testHistoryPromptPrefixInvalidatedOnClear [

	| first second |
	history addUser: 'Hello'.
	first := history asPromptPrefix.
	history clear.
	second := history asPromptPrefix.
	self assert: second equals: ''
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testHistoryPromptPrefixIsCached [

	| first second |
	history addUser: 'Hello'.
	first := history asPromptPrefix.
	second := history asPromptPrefix.
	self assert: first identicalTo: second
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testNormalizeForJsonConvertsSymbolToString [
	"Symbols should be converted to strings."

	| tool result |
	tool := ChatPharoTool ollamaWithSystem: 'test' tools: nil.
	result := tool normalizeForJson: #hello.
	self assert: result isString.
	self assert: result equals: 'hello'.
	self deny: result isSymbol
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testNormalizeForJsonPreSizesDictionary [
	"Normalized dictionaries should contain all entries from the original."

	| tool input result |
	tool := ChatPharoTool ollamaWithSystem: 'test' tools: nil.
	input := Dictionary new.
	input at: 'a' put: 1.
	input at: 'b' put: 'two'.
	input at: 'c' put: #three.
	result := tool normalizeForJson: input.
	self assert: result size equals: 3.
	self assert: (result at: 'a') equals: 1.
	self assert: (result at: 'b') equals: 'two'.
	self assert: (result at: 'c') equals: 'three'.
	self deny: (result at: 'c') isSymbol
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testNormalizeForJsonSkipsStringCopy [
	"Strings should be returned as-is without copying."

	| tool input result |
	tool := ChatPharoTool ollamaWithSystem: 'test' tools: nil.
	input := 'hello world'.
	result := tool normalizeForJson: input.
	self assert: result identicalTo: input
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testOpenAIChatToolInvalidatedOnDescriptionChange [
	"Changing description should invalidate the cached openAIChatTool."

	| client first |
	client := ChatPharoClient
		name: 'myTool'
		description: 'old desc'
		parameters: (Dictionary with: 'type' -> 'object' with: 'properties' -> Dictionary new)
		block: [ :args | 'ok' ].
	first := client openAIChatTool.
	client description: 'new desc'.
	self deny: client openAIChatTool identicalTo: first
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testOpenAIChatToolInvalidatedOnNameChange [
	"Changing name should invalidate the cached openAIChatTool."

	| client first |
	client := ChatPharoClient
		name: 'original'
		description: 'test'
		parameters: (Dictionary with: 'type' -> 'object' with: 'properties' -> Dictionary new)
		block: [ :args | 'ok' ].
	first := client openAIChatTool.
	client name: 'renamed'.
	self deny: client openAIChatTool identicalTo: first.
	self assert: ((client openAIChatTool at: 'function') at: 'name') equals: 'renamed'
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testOpenAIChatToolInvalidatedOnParametersChange [
	"Changing parameters should invalidate the cached openAIChatTool."

	| client first |
	client := ChatPharoClient
		name: 'myTool'
		description: 'test'
		parameters: (Dictionary with: 'type' -> 'object' with: 'properties' -> Dictionary new)
		block: [ :args | 'ok' ].
	first := client openAIChatTool.
	client parameters: (Dictionary with: 'type' -> 'object' with: 'properties' -> (Dictionary with: 'x' -> 'string')).
	self deny: client openAIChatTool identicalTo: first
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testOpenAIChatToolIsCached [
	"openAIChatTool should return the same Dictionary instance on repeated calls."

	| client first second |
	client := ChatPharoClient
		name: 'cachedTool'
		description: 'test'
		parameters: (Dictionary with: 'type' -> 'object' with: 'properties' -> Dictionary new)
		block: [ :args | 'ok' ].
	first := client openAIChatTool.
	second := client openAIChatTool.
	self assert: first identicalTo: second
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testRefreshRebuildsIndexes [

	registry refresh.
	self assert: (registry hasSkillNamed: 'TestSkill').
	self assert: (registry instVarNamed: 'keywordIndex') notNil
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testRegisterSkillUpdatesIndex [

	| skill |
	skill := ChatPharoTestSkill new.
	registry registerSkill: skill.
	self assert: (registry hasSkillNamed: 'TestSkill').
	self assert: (registry skillNamed: 'TestSkill') identicalTo: skill
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testResolvedToolSchemasEmptyWithNoTools [
	"resolvedToolSchemas should return an empty array when there are no tools."

	| tool |
	tool := ChatPharoTool ollamaWithSystem: 'test' tools: nil.
	self assert: tool resolvedToolSchemas isEmpty
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testResolvedToolSchemasInvalidatedOnToolsSet [
	"Setting tools should invalidate the cached schemas."

	| tool client first |
	client := ChatPharoClient
		name: 'schemaTool'
		description: 'test'
		parameters: (Dictionary with: 'type' -> 'object' with: 'properties' -> Dictionary new)
		block: [ :args | 'ok' ].
	tool := ChatPharoTool ollamaWithSystem: 'test' tools: { client }.
	first := tool resolvedToolSchemas.
	tool tools: { client }.
	self deny: tool resolvedToolSchemas identicalTo: first
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testResolvedToolSchemasIsCached [
	"resolvedToolSchemas should return the same array when nothing changes."

	| tool client first second |
	client := ChatPharoClient
		name: 'schemaTool'
		description: 'test'
		parameters: (Dictionary with: 'type' -> 'object' with: 'properties' -> Dictionary new)
		block: [ :args | 'ok' ].
	tool := ChatPharoTool ollamaWithSystem: 'test' tools: { client }.
	first := tool resolvedToolSchemas.
	second := tool resolvedToolSchemas.
	self assert: first identicalTo: second
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testSkillCachedNormalizedKeywordsAreLowercase [

	| skill |
	skill := ChatPharoTestSkill new.
	skill cachedNormalizedKeywords do: [ :kw |
		self assert: kw equals: kw asLowercase ]
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testSkillCachedNormalizedKeywordsIncludesNameAndKeywords [

	| skill kws |
	skill := ChatPharoTestSkill new.
	kws := skill cachedNormalizedKeywords.
	self assert: (kws includes: 'testskill').
	self assert: (kws includes: 'alphabeta').
	self assert: (kws includes: 'gammatool')
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testSkillCachedNormalizedKeywordsNotNil [

	| skill |
	skill := ChatPharoTestSkill new.
	self assert: skill cachedNormalizedKeywords notNil.
	self assert: skill cachedNormalizedKeywords isArray
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testSkillCachedNormalizedKeywordsReturnsSameInstance [

	| skill first second |
	skill := ChatPharoTestSkill new.
	first := skill cachedNormalizedKeywords.
	second := skill cachedNormalizedKeywords.
	self assert: first identicalTo: second
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testSkillNamedReturnsNilForMissing [

	self assert: (registry skillNamed: 'NonExistent') isNil
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testSkillNamedUsesIndex [
	"skillNamed: should return the same result using the index as the linear scan"

	| skill |
	skill := registry skillNamed: 'TestSkill'.
	self assert: skill notNil.
	self assert: skill name equals: 'TestSkill'
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testSkillRegistryHasKeywordIndex [

	self assert: (registry instVarNamed: 'keywordIndex') notNil.
	self assert: (registry instVarNamed: 'keywordIndex') isDictionary
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testSkillRegistryHasSkillsByNameIndex [

	self assert: (registry instVarNamed: 'skillsByName') notNil.
	self assert: (registry instVarNamed: 'skillsByName') isDictionary
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testSkillsForKeywordsEmptyForNoMatch [

	| matches |
	matches := registry skillsForKeywords: #('zzzzzzz').
	self assert: matches isEmpty
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testSkillsForKeywordsUsesIndex [

	| matches |
	matches := registry skillsForKeywords: #('Alpha').
	self assert: (matches anySatisfy: [ :skill | skill name = 'TestSkill' ])
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testToolIndexInvalidatedOnToolsSet [

	| tool client |
	client := ChatPharoClient
		name: 'testTool'
		description: 'A test tool'
		parameters: (Dictionary with: 'type' -> 'object' with: 'properties' -> Dictionary new)
		block: [ :args | 'ok' ].
	tool := ChatPharoTool ollamaWithSystem: 'test' tools: { client }.
	tool toolIndex. "Force build"
	tool tools: nil.
	self assert: tool toolIndex isEmpty
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testToolIndexIsLazilyBuilt [

	| tool |
	tool := ChatPharoTool ollamaWithSystem: 'test' tools: nil.
	self assert: tool toolIndex isDictionary.
	self assert: tool toolIndex isEmpty
]

{ #category : 'running' }
ChatPharoOptimizationTest >> testToolIndexMapsNameToTool [

	| tool client |
	client := ChatPharoClient
		name: 'testTool'
		description: 'A test tool'
		parameters: (Dictionary with: 'type' -> 'object' with: 'properties' -> Dictionary new)
		block: [ :args | 'ok' ].
	tool := ChatPharoTool ollamaWithSystem: 'test' tools: { client }.
	self assert: (tool toolIndex at: 'testTool') identicalTo: client
]
