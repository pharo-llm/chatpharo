"
I am an open window as a model can understand it: a title and the list of its
controls (`ChatPharoUIWidget`), each with a small integer id.

Ids number the controls in the order Spec traverses the window, so the id seen
in `describe` designates the same control in a later click, as long as the
window did not change in between.

Only windows built with Spec expose their controls. Other windows (the System
Browser, the debugger) are listed with their title; the model drives those
through dedicated tools such as `open_browser`.
"
Class {
	#name : 'ChatPharoUIWindow',
	#superclass : 'Object',
	#instVars : [
		'morph'
	],
	#category : 'AI-ChatPharo-Spec-UIAutomation',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'UIAutomation'
}

{ #category : 'accessing' }
ChatPharoUIWindow class >> all [
	"The open windows, front-most first."

	^ self currentWorld systemWindows collect: [ :each | self on: each ]
]

{ #category : 'accessing' }
ChatPharoUIWindow class >> designatedBy: aTitle [
	"The front-most window with that title, else the front-most whose title contains it; nil when none."

	| windows wanted |
	windows := self all.
	wanted := aTitle asString asLowercase.
	^ windows
		  detect: [ :each | each title asLowercase = wanted ]
		  ifNone: [ windows detect: [ :each | each title asLowercase includesSubstring: wanted ] ifNone: [ nil ] ]
]

{ #category : 'instance creation' }
ChatPharoUIWindow class >> on: aSystemWindow [

	^ self new
		  setMorph: aSystemWindow;
		  yourself
]

{ #category : 'actions' }
ChatPharoUIWindow >> close [

	morph delete
]

{ #category : 'describing' }
ChatPharoUIWindow >> describe [

	| widgets |
	widgets := self widgets.
	^ Dictionary new
		  at: 'title' put: self title;
		  at: 'controls_available' put: self isSpecWindow;
		  at: 'widgets' put: ((widgets first: (self shownWidgets min: widgets size)) collect: [ :each | each describe ]) asArray;
		  at: 'widget_count' put: widgets size;
		  yourself
]

{ #category : 'testing' }
ChatPharoUIWindow >> isSpecWindow [
	"Adapter boundary: only Spec windows give access to their presenters."

	^ morph model isKindOf: SpAbstractPresenter
]

{ #category : 'initialization' }
ChatPharoUIWindow >> setMorph: aSystemWindow [

	morph := aSystemWindow
]

{ #category : 'accessing' }
ChatPharoUIWindow >> shownWidgets [

	^ 150
]

{ #category : 'describing' }
ChatPharoUIWindow >> summary [

	^ Dictionary with: 'title' -> self title with: 'controls_available' -> self isSpecWindow
]

{ #category : 'accessing' }
ChatPharoUIWindow >> title [

	^ morph label asString
]

{ #category : 'accessing' }
ChatPharoUIWindow >> widgetDesignatedBy: anIdOrText [

	^ self widgets detect: [ :each | each matches: anIdOrText ] ifNone: [ nil ]
]

{ #category : 'accessing' }
ChatPharoUIWindow >> widgets [
	"My controls, numbered in traversal order."

	| widgets |
	self isSpecWindow ifFalse: [ ^ #(  ) ].
	widgets := OrderedCollection new.
	morph model traversePresentersDo: [ :each |
		(ChatPharoUIWidget forPresenter: each) ifNotNil: [ :widget |
			widgets add: widget.
			widget id: widgets size ] ].
	^ widgets
]
