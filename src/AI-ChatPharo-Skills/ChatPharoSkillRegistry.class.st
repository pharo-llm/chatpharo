"
Central registry for ChatPharo skills.
Manages the discovery, registration, and retrieval of skills. Uses automatic
discovery via subclass scanning to find all available skills.
## Usage:
```smalltalk
""""Get all available skills""""
ChatPharoSkillRegistry default allSkills.
""""Find skills matching keywords""""
ChatPharoSkillRegistry default skillsForKeywords: #('Spec2' 'button' 'presenter').
""""Get context for enabled skills""""
ChatPharoSkillRegistry default contextForEnabledSkills.
""""Get context for skills matching a query""""
ChatPharoSkillRegistry default contextForQuery: 'How do I create a Spec2 button?'.
"
Class {
	#name : 'ChatPharoSkillRegistry',
	#superclass : 'Object',
	#instVars : [
		'skills',
		'keywordIndex',
		'skillsByName'
	],
	#classInstVars : [
		'default'
	],
	#category : 'AI-ChatPharo-Skills',
	#package : 'AI-ChatPharo-Skills'
}

{ #category : 'accessing' }
ChatPharoSkillRegistry class >> default [

	^ default ifNil: [ default := self new ]
]

{ #category : 'accessing' }
ChatPharoSkillRegistry class >> reset [
	"Reset the default registry, forcing re-discovery of skills"
	<script>

	default := nil
]

{ #category : 'as yet unclassified' }
ChatPharoSkillRegistry >> allSkills [
	"Returns all registered skills"

	^ skills
]

{ #category : 'as yet unclassified' }
ChatPharoSkillRegistry >> allSkillsNames [
	"Returns names of all registered skills"

	^ self allSkills collect: [ :skill | skill name ]
]

{ #category : 'as yet unclassified' }
ChatPharoSkillRegistry >> contextForEnabledSkills [
	"Returns combined context string for all manually enabled skills"

	| enabledSkills |
	enabledSkills := self enabledSkills.
	enabledSkills ifEmpty: [ ^ '' ].

	^ String streamContents: [ :stream |
		stream
			nextPutAll: '### ENABLED SKILLS CONTEXT ###';
			cr; cr.
		enabledSkills do: [ :skill |
			stream
				nextPutAll: skill context;
				cr; cr ] ]
]

{ #category : 'as yet unclassified' }
ChatPharoSkillRegistry >> contextForQuery: queryString [
	"Returns context for skills that match keywords in the query.
	 Only considers skills with automaticEnabled = true."

	| matchingSkills keywords |
	keywords := self extractKeywordsFrom: queryString.
	matchingSkills := self skillsForKeywords: keywords.

	"Filter to only automatic-enabled skills"
	matchingSkills := matchingSkills select: [ :skill | skill automaticEnabled ].

	matchingSkills ifEmpty: [ ^ '' ].

	^ String streamContents: [ :stream |
		stream
			nextPutAll: '### AUTO-DETECTED SKILLS CONTEXT ###';
			cr;
			nextPutAll: '(Based on detected keywords: ';
			nextPutAll: (keywords joinUsing: ', ');
			nextPutAll: ')';
			cr; cr.
		matchingSkills do: [ :skill |
			stream
				nextPutAll: skill context;
				cr; cr ] ]
]

{ #category : 'as yet unclassified' }
ChatPharoSkillRegistry >> contextForSkillNamed: skillName [
	"Returns context for a specific skill by name"

	| skill |
	skill := self skillNamed: skillName.
	^ skill
		ifNotNil: [ skill context ]
		ifNil: [ 'Skill not found: ' , skillName ]
]

{ #category : 'as yet unclassified' }
ChatPharoSkillRegistry >> contextForSkillsNamed: skillNames [
	"Returns combined context for multiple skills by name"

	| foundSkills |
	foundSkills := skillNames
		collect: [ :name | self skillNamed: name ]
		thenSelect: [ :skill | skill notNil ].

	foundSkills ifEmpty: [ ^ 'No matching skills found.' ].

	^ String streamContents: [ :stream |
		stream
			nextPutAll: '### REQUESTED SKILLS CONTEXT ###';
			cr; cr.
		foundSkills do: [ :skill |
			stream
				nextPutAll: skill context;
				cr; cr ] ]
]

{ #category : 'as yet unclassified' }
ChatPharoSkillRegistry >> disableSkillNamed: skillName [
	"Disable a skill by name"

	(self skillNamed: skillName) ifNotNil: [ :skill | skill enabled: false ]
]

{ #category : 'as yet unclassified' }
ChatPharoSkillRegistry >> discoverSkills [
	"Discovers all concrete skill subclasses and instantiates them"

	^ ChatPharoSkill allSubclasses
		reject: [ :cls | cls isAbstract ]
		thenCollect: [ :cls | cls new ]
]

{ #category : 'as yet unclassified' }
ChatPharoSkillRegistry >> enableSkillNamed: skillName [
	"Enable a skill by name"

	(self skillNamed: skillName) ifNotNil: [ :skill | skill enabled: true ]
]

{ #category : 'as yet unclassified' }
ChatPharoSkillRegistry >> enabledSkills [
	"Returns all manually enabled skills"

	^ self allSkills select: [ :skill | skill enabled ]
]

{ #category : 'as yet unclassified' }
ChatPharoSkillRegistry >> extractKeywordsFrom: queryString [
	"Extracts potential keywords from a query string.
	 Looks for capitalized words, class-like names, and known patterns."

	| words stopWords |
	words := queryString substrings.
stopWords := #('use' 'uses' 'using').
	"Return words that look like identifiers (capitalized or camelCase)"
	^ words select: [ :word |
		word size > 2 and: [
			(stopWords includes: word asLowercase) not and: [
				(word first isUppercase) or: [
					word anySatisfy: [ :c | c isUppercase ] ] ] ] ]
]

{ #category : 'as yet unclassified' }
ChatPharoSkillRegistry >> hasSkillNamed: skillName [

	^ skillsByName includesKey: skillName
]

{ #category : 'as yet unclassified' }
ChatPharoSkillRegistry >> initialize [

	super initialize.
	skills := self discoverSkills asOrderedCollection.
	self rebuildIndexes
]

{ #category : 'indexing' }
ChatPharoSkillRegistry >> rebuildIndexes [
	"Rebuild the keyword index and name index for fast lookups"

	keywordIndex := Dictionary new.
	skillsByName := Dictionary new.
	skills do: [ :skill |
		skillsByName at: skill name put: skill.
		skill cachedNormalizedKeywords do: [ :kw |
			(keywordIndex at: kw ifAbsentPut: [ Set new ]) add: skill ] ]
]

{ #category : 'as yet unclassified' }
ChatPharoSkillRegistry >> refresh [

skills := self discoverSkills asOrderedCollection.
	self rebuildIndexes
]

{ #category : 'as yet unclassified' }
ChatPharoSkillRegistry >> registerSkill: aSkillOrClass [
	"Register a skill instance or class in the registry."

	| skill |
	skill := aSkillOrClass isBehavior
		         ifTrue: [ aSkillOrClass new ]
		         ifFalse: [ aSkillOrClass ].
	skill ifNil: [ ^ self ].
	skills ifNil: [ skills := OrderedCollection new ].
	skills removeAllSuchThat: [ :existing | existing name = skill name ].
	skills add: skill.
	self rebuildIndexes.
	^ skill
]

{ #category : 'as yet unclassified' }
ChatPharoSkillRegistry >> setAutomaticEnabled: aBoolean forSkillNamed: skillName [
	"Set automatic mode for a skill by name"

	(self skillNamed: skillName) ifNotNil: [ :skill | skill automaticEnabled: aBoolean ]
]

{ #category : 'as yet unclassified' }
ChatPharoSkillRegistry >> skillNamed: skillName [

	^ skillsByName at: skillName ifAbsent: [ nil ]
]

{ #category : 'as yet unclassified' }
ChatPharoSkillRegistry >> skillsForKeywords: keywordCollection [

	| matches normalizedTerms |
	matches := Set new.
	normalizedTerms := (keywordCollection ifNil: [ #() ])
		collect: [ :term | term asString asLowercase ].
	normalizedTerms do: [ :term |
		keywordIndex keysAndValuesDo: [ :kw :skillSet |
			(kw includesSubstring: term) ifTrue: [
				matches addAll: skillSet ] ] ].
	^ matches asOrderedCollection
]

{ #category : 'as yet unclassified' }
ChatPharoSkillRegistry >> skillsWithAutomaticEnabled [
	"Returns all skills that have automatic mode enabled"

	^ self allSkills select: [ :skill | skill automaticEnabled ]
]
