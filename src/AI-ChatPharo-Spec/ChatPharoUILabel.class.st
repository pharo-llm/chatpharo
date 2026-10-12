"
I adapt labels: text the user reads, with nothing to act on.
"
Class {
	#name : 'ChatPharoUILabel',
	#superclass : 'ChatPharoUIWidget',
	#category : 'AI-ChatPharo-Spec-UIAutomation',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'UIAutomation'
}

{ #category : 'accessing' }
ChatPharoUILabel class >> presenterClass [

	^ SpLabelPresenter
]

{ #category : 'accessing' }
ChatPharoUILabel >> kind [

	^ 'label'
]

{ #category : 'accessing' }
ChatPharoUILabel >> text [

	^ (presenter label ifNil: [ '' ]) asString
]
