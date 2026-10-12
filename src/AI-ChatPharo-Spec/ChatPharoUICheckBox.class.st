"
I adapt check boxes: clicking me toggles my state.
"
Class {
	#name : 'ChatPharoUICheckBox',
	#superclass : 'ChatPharoUIButton',
	#category : 'AI-ChatPharo-Spec-UIAutomation',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'UIAutomation'
}

{ #category : 'accessing' }
ChatPharoUICheckBox class >> presenterClass [

	^ SpCheckBoxPresenter
]

{ #category : 'gestures' }
ChatPharoUICheckBox >> activate [

	presenter click.
	^ Dictionary with: 'checked' -> presenter state
]

{ #category : 'describing' }
ChatPharoUICheckBox >> describeDetailsOn: aDictionary [

	aDictionary at: 'checked' put: presenter state
]

{ #category : 'accessing' }
ChatPharoUICheckBox >> kind [

	^ 'checkbox'
]
