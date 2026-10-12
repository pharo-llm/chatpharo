"
I adapt the buttons of a toolbar, which Spec models apart from push buttons.
"
Class {
	#name : 'ChatPharoUIToolbarButton',
	#superclass : 'ChatPharoUIButton',
	#category : 'AI-ChatPharo-Spec-UIAutomation',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'UIAutomation'
}

{ #category : 'accessing' }
ChatPharoUIToolbarButton class >> presenterClass [

	^ SpToolbarButtonPresenter
]

{ #category : 'accessing' }
ChatPharoUIToolbarButton >> kind [

	^ 'toolbar_button'
]
