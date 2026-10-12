"
I adapt lists, tables and trees of rows: I show the first rows and select one by position or by its text.
"
Class {
	#name : 'ChatPharoUIList',
	#superclass : 'ChatPharoUIWidget',
	#category : 'AI-ChatPharo-Spec-UIAutomation',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'UIAutomation'
}

{ #category : 'accessing' }
ChatPharoUIList class >> presenterClass [

	^ SpAbstractListPresenter
]

{ #category : 'describing' }
ChatPharoUIList >> describeDetailsOn: aDictionary [

	| labels |
	labels := self itemLabels.
	aDictionary
		at: 'items' put: (labels first: (self shownItems min: labels size));
		at: 'item_count' put: labels size
]

{ #category : 'private' }
ChatPharoUIList >> indexOf: anIndexOrLabel [

	anIndexOrLabel isInteger ifTrue: [ ^ anIndexOrLabel ].
	^ self itemLabels indexOf: anIndexOrLabel asString
]

{ #category : 'private' }
ChatPharoUIList >> itemLabels [

	^ presenter items collect: [ :each | self labelOf: each ] as: Array
]

{ #category : 'accessing' }
ChatPharoUIList >> kind [

	^ 'list'
]

{ #category : 'private' }
ChatPharoUIList >> labelOf: anItem [

	^ anItem isString
		  ifTrue: [ anItem ]
		  ifFalse: [ anItem printString ]
]

{ #category : 'gestures' }
ChatPharoUIList >> select: anIndexOrLabel [

	| index |
	index := self indexOf: anIndexOrLabel.
	(index between: 1 and: presenter items size) ifFalse: [
		^ Dictionary with: 'error' -> 'No such item. Give its position starting at 1, or its exact text.' ].
	presenter selectIndex: index.
	^ Dictionary with: 'selected' -> (self itemLabels at: index)
]

{ #category : 'accessing' }
ChatPharoUIList >> shownItems [

	^ 40
]
