"
Fallback confirmation gate used by `ChatPharoToolConfirmation` when no
richer presenter (Spec dialog, MCP prompt, scripted test stub) has been
registered yet.

It relies on `UIManager default`: in a desktop image this opens a real
Morphic confirmation with three choices (Allow / Always / Deny); in a
headless image (tests, CI) the `UIManager` is a `NonInteractiveUIManager`
that denies by default, which is the safe behaviour.

Why a class and not a Block: we want the Spec package to replace it via
subclassing semantics (`gate:` accepts anything that answers
`confirmToolNamed:arguments:action:summary:`), and keeping the fallback
concrete makes the extension contract explicit.
"
Class {
	#name : 'ChatPharoToolConfirmationFallbackGate',
	#superclass : 'Object',
	#category : 'AI-ChatPharo',
	#package : 'AI-ChatPharo'
}

{ #category : 'confirmation' }
ChatPharoToolConfirmationFallbackGate >> askWhyDenied: aToolName [
	"Answer what the user says about their refusal; empty when they say nothing or cannot be asked."

	^ [ (UIManager default request: 'Why deny ' , aToolName , '? Your answer is sent to ChatPharo (optional).') ifNil: [ '' ] ]
		  on: Error
		  do: [ '' ]
]

{ #category : 'confirmation' }
ChatPharoToolConfirmationFallbackGate >> confirmToolNamed: aToolName arguments: anArguments action: actionLabel summary: summaryString [

	| title message choice |
	title := 'ChatPharo · Confirm ' , actionLabel.
	message := String streamContents: [ :s |
			           s nextPutAll: 'The ChatPharo wants to perform the following action on your image:'.
			           s
				           cr;
				           cr.
			           s nextPutAll: summaryString.
			           s cr.
			           s nextPutAll: 'Do you authorise this operation?' ].

	choice := [
	          UIManager default chooseFrom: #( 'Allow once' 'Always allow in this chat' 'Deny' ) title: title , String cr , message ]
		          on: Error
		          do: [ :e | 0 ].

	choice = 1 ifTrue: [ ^ ChatPharoToolConfirmationDecision allow ].
	choice = 2 ifTrue: [ ^ ChatPharoToolConfirmationDecision always ].
	choice = 3 ifTrue: [ ^ ChatPharoToolConfirmationDecision denyBecause: (self askWhyDenied: aToolName) ].
	^ ChatPharoToolConfirmationDecision denyWithReason: 'The user declined to run ' , aToolName , '.'
]
