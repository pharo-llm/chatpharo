"
I adapt notebooks: my items are the tab titles, and selecting one shows that tab.
"
Class {
	#name : 'ChatPharoUITabs',
	#superclass : 'ChatPharoUIWidget',
	#category : 'AI-ChatPharo-Spec-UIAutomation',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'UIAutomation'
}

{ #category : 'accessing' }
ChatPharoUITabs class >> presenterClass [

	^ SpNotebookPresenter
]

{ #category : 'describing' }
ChatPharoUITabs >> describeDetailsOn: aDictionary [

	aDictionary
		at: 'items' put: self tabTitles;
		at: 'selected' put: (presenter selectedPage ifNotNil: [ :page | page title asString ])
]

{ #category : 'accessing' }
ChatPharoUITabs >> kind [

	^ 'tabs'
]

{ #category : 'gestures' }
ChatPharoUITabs >> select: anIndexOrLabel [

	| index |
	index := anIndexOrLabel isInteger
		         ifTrue: [ anIndexOrLabel ]
		         ifFalse: [ self tabTitles indexOf: anIndexOrLabel asString ].
	(index between: 1 and: presenter pages size) ifFalse: [
		^ Dictionary with: 'error' -> 'No such tab. Give its position starting at 1, or its exact title.' ].
	presenter selectPageIndex: index.
	^ Dictionary with: 'selected' -> (self tabTitles at: index)
]

{ #category : 'private' }
ChatPharoUITabs >> tabTitles [

	^ presenter pages collect: [ :each | each title asString ] as: Array
]
