Class {
	#name : 'ChatPharoToolConsentTest',
	#superclass : 'TestCase',
	#instVars : [
		'confirmation',
		'asked'
	],
	#category : 'AI-ChatPharo-Tests-Tools',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Tools'
}

{ #category : 'gate' }
ChatPharoToolConsentTest >> confirmToolNamed: aToolName arguments: anArguments action: actionLabel summary: summaryString [
	"I am the gate: the user refuses and says why."

	asked add: aToolName.
	^ ChatPharoToolConfirmationDecision denyBecause: 'use a new package instead'
]

{ #category : 'running' }
ChatPharoToolConsentTest >> setUp [

	super setUp.
	asked := OrderedCollection new.
	confirmation := ChatPharoToolConfirmation new
		                gate: self;
		                yourself
]

{ #category : 'running' }
ChatPharoToolConsentTest >> tearDown [

	ChatPharoSettings resetDefault.
	super tearDown
]

{ #category : 'tests' }
ChatPharoToolConsentTest >> testDenialWithoutReasonSaysSo [

	self assert: ((ChatPharoToolConfirmationDecision denyBecause: '') reason includesSubstring: 'without giving a reason').
	self assert: (ChatPharoToolConfirmationDecision denyBecause: '') isDeny
]

{ #category : 'tests' }
ChatPharoToolConsentTest >> testReadOnlyToolIsNotAsked [

	confirmation
		guardToolNamed: 'find_senders'
		arguments: Dictionary new
		mutating: false
		ifDeniedDo: [ :payload | self fail ].
	self assert: asked isEmpty
]

{ #category : 'tests' }
ChatPharoToolConsentTest >> testToolDeclaringItselfMutatingIsAsked [
	"The list of mutating tools is no longer hard-coded: a tool says so itself."

	| payload |
	confirmation
		guardToolNamed: 'click_widget'
		arguments: Dictionary new
		mutating: true
		ifDeniedDo: [ :cancellation | payload := cancellation ].
	self assert: asked asArray equals: #( 'click_widget' ).
	self assert: (payload at: 'cancelled')
]

{ #category : 'tests' }
ChatPharoToolConsentTest >> testTheReasonOfTheUserReachesTheModel [

	| payload |
	confirmation
		guardToolNamed: 'create_class'
		arguments: Dictionary new
		ifDeniedDo: [ :cancellation | payload := cancellation ].
	self assert: ((payload at: 'reason') includesSubstring: 'use a new package instead').
	self assert: ((payload at: 'hint') includesSubstring: 'do not retry')
]
