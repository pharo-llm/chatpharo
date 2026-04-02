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
