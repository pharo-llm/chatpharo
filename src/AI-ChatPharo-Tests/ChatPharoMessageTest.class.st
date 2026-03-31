Class {
	#name : 'ChatPharoMessageTest',
	#superclass : 'TestCase',
	#category : 'AI-ChatPharo-Tests-Spec',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Spec'
}

{ #category : 'tests' }
ChatPharoMessageTest >> testAccessors [
	| msg |
	msg := ChatPharoMessage new
		content: 'Hi';
		answer: 'Hello!'.
	self assert: msg content equals: 'Hi'.
	self assert: msg answer equals: 'Hello!'.
]

{ #category : 'tests' }
ChatPharoMessageTest >> testAddAndRemoveAttachment [

	| msg attachment |
	msg := ChatPharoMessage new.
	attachment := FileLocator imageDirectory / 'attachment.txt'.

	msg addAttachment: attachment.
	self assert: msg attachments size equals: 1.
	self assert: msg attachments first equals: attachment.

	msg removeAttachment: attachment.
	self assert: msg attachments isEmpty
]

{ #category : 'tests' }
ChatPharoMessageTest >> testAssistantLabelAccessors [ 

        | msg |
        msg := ChatPharoMessage new.
        msg assistantLabel: 'Bot'.
        self assert: msg assistantLabel equals: 'Bot'.
]

{ #category : 'tests' }
ChatPharoMessageTest >> testDefaultInitialization [

	| msg |
	msg := ChatPharoMessage new.
	self assert: msg content equals: String empty.
	self assert: msg answer equals: String empty.
	self assert: msg assistantLabel equals: 'Assistant'.
	self assert: msg feedback isNil.
	self assert: msg height equals: 112
]

{ #category : 'tests' }
ChatPharoMessageTest >> testFeedbackAccessors [

        | msg |
        msg := ChatPharoMessage new.
        msg feedback: true.
        self assert: msg feedback equals: true.
]

{ #category : 'tests' }
ChatPharoMessageTest >> testPresenterClass [ 

        | msg |
        msg := ChatPharoMessage new.
        self assert: msg presenter class equals: ChatPharoMessagePresenter.
]

{ #category : 'tests' }
ChatPharoMessageTest >> testPresenterIsLazyInitialized [ 

	| msg presenter1 presenter |
	msg := ChatPharoMessage new.
	presenter1 := msg presenter.
	presenter := msg presenter.
	self assert: presenter1 == presenter.
]

{ #category : 'tests' }
ChatPharoMessageTest >> testRemoveMissingAttachmentDoesNothing [

	| msg |
	msg := ChatPharoMessage new.

	self
		shouldnt: [ msg removeAttachment: (FileLocator imageDirectory / 'missing.txt') ]
		raise: Error.

	self assert: msg attachments isEmpty
]

{ #category : 'tests' }
ChatPharoMessageTest >> testResetPresenterCreatesFreshPresenter [

	| msg firstPresenter secondPresenter |
	msg := ChatPharoMessage new.
	firstPresenter := msg presenter.

	msg resetPresenter.
	secondPresenter := msg presenter.

	self deny: firstPresenter == secondPresenter
]

{ #category : 'tests' }
ChatPharoMessageTest >> testSuggestionAcceptance [

	| msg originalEnabled |
	originalEnabled := ChatPharoFeedbackSubmitter enabled.

	[
	ChatPharoFeedbackSubmitter enabled: false. "Disable for testing"
	msg := ChatPharoMessage new
		       content: 'Test question';
		       answer: 'Test answer'.

	self deny: msg suggestionAccepted.
	self deny: msg suggestionRejected.
	self assert: msg feedbackTimestamp isNil.

	msg acceptSuggestion.

	self assert: msg suggestionAccepted.
	self deny: msg suggestionRejected.
	self assert: msg feedbackTimestamp notNil ]
		ensure: [ ChatPharoFeedbackSubmitter enabled: originalEnabled ]
]

{ #category : 'tests' }
ChatPharoMessageTest >> testSuggestionRejection [

	| msg originalEnabled |
	originalEnabled := ChatPharoFeedbackSubmitter enabled.

	[
	ChatPharoFeedbackSubmitter enabled: false. "Disable for testing"
	msg := ChatPharoMessage new
		       content: 'Test question';
		       answer: 'Test answer'.

	self deny: msg suggestionRejected.
	self deny: msg suggestionAccepted.

	msg rejectSuggestion.

	self assert: msg suggestionRejected.
	self deny: msg suggestionAccepted.
	self assert: msg feedbackTimestamp notNil ]
		ensure: [ ChatPharoFeedbackSubmitter enabled: originalEnabled ]
]

{ #category : 'tests' }
ChatPharoMessageTest >> testSuggestionToggle [
	"Test that accepting a suggestion after rejecting it updates the state correctly"

	| msg originalEnabled |
	originalEnabled := ChatPharoFeedbackSubmitter enabled.

	[
	ChatPharoFeedbackSubmitter enabled: false. "Disable for testing"
	msg := ChatPharoMessage new.

	msg rejectSuggestion.
	self assert: msg suggestionRejected.
	self deny: msg suggestionAccepted.

	msg acceptSuggestion.
	self assert: msg suggestionAccepted.
	self deny: msg suggestionRejected ]
		ensure: [ ChatPharoFeedbackSubmitter enabled: originalEnabled ]
]

{ #category : 'tests' }
ChatPharoMessageTest >> testThinkingAccessor [

	| msg |
	msg := ChatPharoMessage new.
	msg thinking: 'internal reasoning'.

	self assert: msg thinking equals: 'internal reasoning'
]

{ #category : 'tests' }
ChatPharoMessageTest >> testThinkingDefaultsToEmptyString [

	self assert: ChatPharoMessage new thinking equals: String empty
]
