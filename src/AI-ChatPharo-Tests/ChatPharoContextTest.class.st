Class {
	#name : 'ChatPharoContextTest',
	#superclass : 'TestCase',
	#instVars : [
		'settings'
	],
	#category : 'AI-ChatPharo-Tests-Context',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Context'
}

{ #category : 'running' }
ChatPharoContextTest >> setUp [

	super setUp.
	settings := ChatPharoSettings default
]

{ #category : 'running' }
ChatPharoContextTest >> tearDown [

	ChatPharoSettings resetDefault.
	super tearDown
]

{ #category : 'tests' }
ChatPharoContextTest >> testDefaultContextOrdersLayersFromStableToVolatile [

	self
		assert: ((ChatPharoContext settings: settings) layers collect: [ :each | each class ]) asArray
		equals: {
				ChatPharoEnvironmentLayer.
				ChatPharoWorkflowLayer.
				ChatPharoProjectLayer.
				ChatPharoSessionLayer.
				ChatPharoMemoryLayer }
]

{ #category : 'tests' }
ChatPharoContextTest >> testDisabledLayerIsSilent [

	settings projectContextEnabled: false.
	self assert: ((ChatPharoProjectLayer settings: settings) textFor: 'anything') isEmpty.
	self deny: (((ChatPharoContext settings: settings) promptFor: 'anything') includesSubstring: 'Project context')
]

{ #category : 'tests' }
ChatPharoContextTest >> testLayerStaysWithinItsCharacterBudget [

	| layer text |
	layer := ChatPharoEnvironmentLayer settings: settings.
	text := String streamContents: [ :stream |
		        layer
			        write: ((1 to: 500) collect: [ :index | '- line number ' , index printString ])
			        within: 200
			        on: stream ].
	self assert: text size < 300.
	self assert: (text endsWith: '- (more omitted)')
]

{ #category : 'tests' }
ChatPharoContextTest >> testMemoryLayerTellsTheUserProfile [

	| text |
	settings userName: 'Ada'.
	text := (ChatPharoMemoryLayer settings: settings) textFor: 'hello'.
	self assert: (text includesSubstring: 'User name: Ada').
	self assert: (text includesSubstring: 'Pharo experience')
]

{ #category : 'tests' }
ChatPharoContextTest >> testProjectLayerNamesTheImage [

	| text |
	text := (ChatPharoProjectLayer settings: settings) textFor: 'hello'.
	self assert: (text beginsWith: '## Project context (automatic)').
	self assert: (text includesSubstring: Smalltalk image imageFile basename)
]

{ #category : 'tests' }
ChatPharoContextTest >> testSessionLayerReportsCodeChangesOfTheSession [

	| layer |
	layer := ChatPharoSessionLayer settings: settings.
	self assert: (layer describeChange: (EpMethodAddition method: Object >> #printString)) equals: 'EpMethodAddition(Object>>printString)'
]
