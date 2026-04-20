Class {
	#name : 'ChatPharoThinkingPresenterTest',
	#superclass : 'TestCase',
	#instVars : [
		'presenter'
	],
	#category : 'AI-ChatPharo-Tests-Thinking',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Thinking'
}

{ #category : 'running' }
ChatPharoThinkingPresenterTest >> setUp [

	super setUp.
	presenter := ChatPharoThinkingPresenter new
]

{ #category : 'running' }
ChatPharoThinkingPresenterTest >> tearDown [

	presenter ifNotNil: [ presenter stopAnimation ].
	presenter := nil.
	super tearDown
]

{ #category : 'running' }
ChatPharoThinkingPresenterTest >> testAddExecutedToolIgnoresNil [

	presenter addExecutedTool: nil.
	self assert: (presenter instVarNamed: #executedTools) isEmpty
]

{ #category : 'running' }
ChatPharoThinkingPresenterTest >> testAddExecutedToolTracksToolName [

	presenter addExecutedTool: 'search_code'.
	self assert: (presenter instVarNamed: #executedTools) size equals: 1.
	self assert: (presenter instVarNamed: #executedTools) first equals: 'search_code'
]

{ #category : 'running' }
ChatPharoThinkingPresenterTest >> testClearExecutedToolsRemovesAll [

	presenter addExecutedTool: 'search_code'.
	presenter addExecutedTool: 'run_snippet'.
	presenter clearExecutedTools.
	self assert: (presenter instVarNamed: #executedTools) isEmpty
]

{ #category : 'running' }
ChatPharoThinkingPresenterTest >> testFormattedElapsedThinkingTime [

	presenter instVarNamed: #thinkingElapsedSeconds put: 125.

	self
		assert: presenter formattedElapsedThinkingTime
		equals: '2 min 5 sec (125s total)'
]

{ #category : 'running' }
ChatPharoThinkingPresenterTest >> testPhaseFinishedUpdatesStatusWithElapsedTime [
| buttonLabel |
	presenter
		instVarNamed: #thinkingStartedAt
		put: DateAndTime now - (Duration seconds: 65).

	presenter phase: #finished.
	buttonLabel := (presenter instVarNamed: #thinkingButton) label.
self assert: (buttonLabel includesSubstring: 'Done').
	self assert: (buttonLabel includesSubstring: '65s')
]

{ #category : 'running' }
ChatPharoThinkingPresenterTest >> testPhaseSetterUpdatesCurrentPhase [

	presenter phase: #executing.
	self assert: (presenter instVarNamed: #currentPhase) equals: #executing.
	presenter phase: #finished.
	self assert: (presenter instVarNamed: #currentPhase) equals: #finished
]

{ #category : 'tests' }
ChatPharoThinkingPresenterTest >> testRetryAttemptSetsRetryingPhaseAndLabel [

	| buttonLabel |
	presenter retryAttempt: 2 of: 3.
	self assert: (presenter instVarNamed: #currentPhase) equals: #retrying.
	self assert: presenter phaseText equals: 'Retrying (attempt 2/3)'.
	buttonLabel := (presenter instVarNamed: #thinkingButton) label.
	self assert: (buttonLabel includesSubstring: 'Retrying (attempt 2/3)')
]

{ #category : 'running' }
ChatPharoThinkingPresenterTest >> testStartAnimationClearsExecutedTools [

	presenter addExecutedTool: 'search_code'.
	presenter startAnimation.
	self assert: (presenter instVarNamed: #executedTools) isEmpty
]

{ #category : 'tests' }
ChatPharoThinkingPresenterTest >> testStartAnimationClearsRetryState [

	presenter retryAttempt: 1 of: 3.
	presenter startAnimation.
	self assert: (presenter instVarNamed: #retryAttempt) isNil.
	self assert: (presenter instVarNamed: #retryMax) isNil
]

{ #category : 'running' }
ChatPharoThinkingPresenterTest >> testStartAnimationResetsAndStartsTiming [

	presenter instVarNamed: #thinkingElapsedSeconds put: 42.
	presenter startAnimation.

	self assert: (presenter instVarNamed: #thinkingStartedAt) isNotNil.
	self assert: (presenter instVarNamed: #thinkingElapsedSeconds) equals: 0
]

{ #category : 'running' }
ChatPharoThinkingPresenterTest >> testTokenUsageAccessors [

	presenter inputTokens: 100.
	presenter outputTokens: 50.
	presenter totalTokens: 150.
	self assert: presenter inputTokens equals: 100.
	self assert: presenter outputTokens equals: 50.
	self assert: presenter totalTokens equals: 150
]

{ #category : 'running' }
ChatPharoThinkingPresenterTest >> testUpdateTokenUsageFromMessage [

	| message |
	message := ChatPharoMessage new.
	message inputTokens: 200.
	message outputTokens: 75.
	message totalTokens: 275.
	presenter updateTokenUsageFrom: message.
	self assert: presenter inputTokens equals: 200.
	self assert: presenter outputTokens equals: 75.
	self assert: presenter totalTokens equals: 275
]
