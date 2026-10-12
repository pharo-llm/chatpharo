Class {
	#name : 'ChatPharoReasoningExtractionTest',
	#superclass : 'TestCase',
	#category : 'AI-ChatPharo-Tests-Tools',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Tools'
}

{ #category : 'private' }
ChatPharoReasoningExtractionTest >> extractionFor: aDictionary [

	^ ChatPharoReasoningExtraction fromMessage: aDictionary
]

{ #category : 'tests' }
ChatPharoReasoningExtractionTest >> testContentWithoutReasoningIsUntouched [

	| extraction |
	extraction := self extractionFor: (Dictionary with: 'content' -> 'a < b and b > c').
	self assert: extraction content equals: 'a < b and b > c'.
	self deny: extraction hasReasoning.
	self assert: extraction reasoning isNil
]

{ #category : 'tests' }
ChatPharoReasoningExtractionTest >> testInlineThinkTagsAreMovedToReasoning [

	| extraction |
	extraction := self extractionFor: (Dictionary with: 'content' -> '<think>2 + 2 is 4</think>

Four.').
	self assert: extraction content equals: 'Four.'.
	self assert: extraction reasoning equals: '2 + 2 is 4'
]

{ #category : 'tests' }
ChatPharoReasoningExtractionTest >> testNilContentOfToolCallReplyStaysNil [

	self assert: (self extractionFor: (Dictionary with: 'role' -> 'assistant')) content isNil
]

{ #category : 'tests' }
ChatPharoReasoningExtractionTest >> testOllamaReasoningFieldIsRead [
	"Ollama's OpenAI endpoint answers the thoughts of qwen3, deepseek-r1… in 'reasoning'."

	| extraction |
	extraction := self extractionFor:
		              (Dictionary with: 'content' -> 'Four.' with: 'reasoning' -> 'The user asks for a sum.').
	self assert: extraction reasoning equals: 'The user asks for a sum.'.
	self assert: extraction content equals: 'Four.'
]

{ #category : 'tests' }
ChatPharoReasoningExtractionTest >> testReasoningContentFieldIsRead [

	self
		assert:
		(self extractionFor: (Dictionary with: 'content' -> 'x' with: 'reasoning_content' -> 'because')) reasoning
		equals: 'because'
]

{ #category : 'tests' }
ChatPharoReasoningExtractionTest >> testSeveralThinkBlocksAreAllCollected [

	| extraction |
	extraction := self extractionFor:
		              (Dictionary with: 'content' -> '<think>one</think>A<thought>two</thought>B').
	self assert: extraction content equals: 'AB'.
	self assert: (extraction reasoning includesSubstring: 'one').
	self assert: (extraction reasoning includesSubstring: 'two')
]

{ #category : 'tests' }
ChatPharoReasoningExtractionTest >> testUnterminatedThinkTagKeepsTheRestAsReasoning [

	| extraction |
	extraction := self extractionFor: (Dictionary with: 'content' -> 'Sure. <think>cut while thinking').
	self assert: extraction content equals: 'Sure.'.
	self assert: extraction reasoning equals: 'cut while thinking'
]
