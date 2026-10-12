"
I adapt push buttons and toolbar buttons. Icon-only buttons are named by their help text.
"
Class {
	#name : 'ChatPharoUIButton',
	#superclass : 'ChatPharoUIWidget',
	#category : 'AI-ChatPharo-Spec-UIAutomation',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'UIAutomation'
}

{ #category : 'accessing' }
ChatPharoUIButton class >> presenterClass [

	^ SpButtonPresenter
]

{ #category : 'gestures' }
ChatPharoUIButton >> activate [

	presenter click.
	^ Dictionary with: 'clicked' -> self text
]

{ #category : 'accessing' }
ChatPharoUIButton >> kind [

	^ 'button'
]

{ #category : 'accessing' }
ChatPharoUIButton >> text [

	^ (presenter label ifNil: [ '' ]) asString ifEmpty: [ (presenter help ifNil: [ '' ]) asString ]
]
