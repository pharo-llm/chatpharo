"
A single decision returned by a confirmation gate when the model is about to
execute a mutating tool call (create class, add method, evaluate code, ...).

A decision is one of:

- allow   : run the tool this one time only.
- always  : run the tool, and skip confirmation for this tool for the rest of
            the current chat session.
- deny    : cancel the tool call. The tool returns a structured cancellation
            payload back to the model so that it can adapt its plan.

Why a real object and not a Symbol: we also carry a human-readable reason
(useful when the user types a justification in the dialog), and we keep the
contract explicit for the LLM feedback path.
"
Class {
	#name : 'ChatPharoToolConfirmationDecision',
	#superclass : 'Object',
	#instVars : [
		'outcome',
		'reason'
	],
	#category : 'AI-ChatPharo',
	#package : 'AI-ChatPharo'
}

{ #category : 'instance creation' }
ChatPharoToolConfirmationDecision class >> allow [

	^ self new outcome: #allow
]

{ #category : 'instance creation' }
ChatPharoToolConfirmationDecision class >> always [

	^ self new outcome: #always
]

{ #category : 'instance creation' }
ChatPharoToolConfirmationDecision class >> deny [

	^ self new outcome: #deny
]

{ #category : 'instance creation' }
ChatPharoToolConfirmationDecision class >> denyWithReason: aString [

	^ self new
		outcome: #deny;
		reason: aString;
		yourself
]

{ #category : 'testing' }
ChatPharoToolConfirmationDecision >> isAllow [

	^ outcome = #allow or: [ outcome = #always ]
]

{ #category : 'testing' }
ChatPharoToolConfirmationDecision >> isAlways [

	^ outcome = #always
]

{ #category : 'testing' }
ChatPharoToolConfirmationDecision >> isDeny [

	^ outcome = #deny
]

{ #category : 'accessing' }
ChatPharoToolConfirmationDecision >> outcome [

	^ outcome
]

{ #category : 'accessing' }
ChatPharoToolConfirmationDecision >> outcome: aSymbol [

	outcome := aSymbol
]

{ #category : 'accessing' }
ChatPharoToolConfirmationDecision >> reason [

	^ reason ifNil: [ '' ]
]

{ #category : 'accessing' }
ChatPharoToolConfirmationDecision >> reason: aString [

	reason := aString
]
