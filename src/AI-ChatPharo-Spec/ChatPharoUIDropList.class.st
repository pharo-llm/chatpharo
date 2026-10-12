"
I adapt drop-down lists.
"
Class {
	#name : 'ChatPharoUIDropList',
	#superclass : 'ChatPharoUIList',
	#category : 'AI-ChatPharo-Spec-UIAutomation',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'UIAutomation'
}

{ #category : 'accessing' }
ChatPharoUIDropList class >> presenterClass [

	^ SpDropListPresenter
]

{ #category : 'describing' }
ChatPharoUIDropList >> describeDetailsOn: aDictionary [

	super describeDetailsOn: aDictionary.
	aDictionary at: 'selected' put: (presenter selectedItem ifNotNil: [ :item | self labelOf: item ])
]

{ #category : 'accessing' }
ChatPharoUIDropList >> kind [

	^ 'dropdown'
]

{ #category : 'private' }
ChatPharoUIDropList >> labelOf: anItem [

	^ (presenter displayForItem: anItem) asString
]
