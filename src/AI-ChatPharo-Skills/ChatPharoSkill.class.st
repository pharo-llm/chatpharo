"
Abstract base class for ChatPharo skills.
A **Skill** provides contextual documentation and knowledge about specific Pharo libraries
or frameworks (e.g., Spec2, Roassal, Collections) that can be passed to the LLM
to improve its understanding and response quality.
## Key Concepts:
* **Automatic Skills** - Skills that can be automatically invoked when the model detects
  relevant keywords or expresses uncertainty about a topic.
* **Manual Skills** - Skills that the user explicitly enables to always include in context.
## Subclass Responsibilities:
* Override `name` to provide a unique identifier
* Override `description` to explain what the skill covers
* Override `keywords` to list terms that trigger automatic activation
* Override `contextString` to return the actual documentation/context
## Usage:
```smalltalk
ChatPharoSpec2Skill new context.
ChatPharoSkillRegistry default skillsForKeywords: #('SpPresenter' 'button').
"
Class {
	#name : 'ChatPharoSkill',
	#superclass : 'Object',
	#instVars : [
		'enabled',
		'automaticEnabled',
		'cachedNormalizedKeywords'
	],
	#category : 'AI-ChatPharo-Skills',
	#package : 'AI-ChatPharo-Skills'
}

{ #category : 'testing' }
ChatPharoSkill class >> isAbstract [

	^ self == ChatPharoSkill
]

{ #category : 'accessing' }
ChatPharoSkill >> automaticEnabled [
	"Whether this skill can be automatically triggered based on keywords"

	^ automaticEnabled ifNil: [ automaticEnabled := true ]
]

{ #category : 'accessing' }
ChatPharoSkill >> automaticEnabled: aBoolean [

	automaticEnabled := aBoolean
]

{ #category : 'accessing' }
ChatPharoSkill >> cachedNormalizedKeywords [
	"Returns cached lowercased keywords including name, description, and keyword list.
	 Computed once and reused for fast matching."

	^ cachedNormalizedKeywords ifNil: [
		| kws |
		kws := OrderedCollection new.
		kws add: self name asString asLowercase.
		kws add: self description asString asLowercase.
		self keywords ifNotNil: [ :keywordList |
			kws addAll: (keywordList collect: [ :k | k asString asLowercase ]) ].
		cachedNormalizedKeywords := kws asArray ]
]

{ #category : 'accessing' }
ChatPharoSkill >> context [
	"Returns the full context string for this skill, formatted for the LLM"

	^ String streamContents: [ :stream |
		stream
			nextPutAll: '=== SKILL: ';
			nextPutAll: self name;
			nextPutAll: ' ===';
			cr; cr;
			nextPutAll: 'Description: ';
			nextPutAll: self description;
			cr; cr;
			nextPutAll: self contextString ]
]

{ #category : 'accessing' }
ChatPharoSkill >> contextString [
	"Override in subclasses to provide the actual documentation/knowledge"

	self subclassResponsibility
]

{ #category : 'accessing' }
ChatPharoSkill >> description [
	"A brief description of what this skill covers"

	self subclassResponsibility
]

{ #category : 'accessing' }
ChatPharoSkill >> enabled [
	"Whether this skill is manually enabled by the user"

	^ enabled ifNil: [ enabled := false ]
]

{ #category : 'accessing' }
ChatPharoSkill >> enabled: aBoolean [

	enabled := aBoolean
]

{ #category : 'accessing' }
ChatPharoSkill >> initialize [

	super initialize.
	enabled := false.
	automaticEnabled := true
]

{ #category : 'accessing' }
ChatPharoSkill >> keywords [
	"A collection of keywords that trigger automatic skill activation.
	 These should include class names, method selectors, and common terms."

	self subclassResponsibility
]

{ #category : 'accessing' }
ChatPharoSkill >> matchesKeywords: searchTerms [
"Returns true if any of the searchTerms match this skill's keywords.
	 Uses cached normalized keywords to avoid recomputation."

	| normalizedTerms |
	normalizedTerms := (searchTerms ifNil: [ #() ])
		collect: [ :term | term asString asLowercase ].
	^ normalizedTerms anySatisfy: [ :term |
		  self cachedNormalizedKeywords anySatisfy: [ :kw |
			  kw includesSubstring: term ] ]
]

{ #category : 'accessing' }
ChatPharoSkill >> name [
	"The unique identifier for this skill"

	self subclassResponsibility
]
