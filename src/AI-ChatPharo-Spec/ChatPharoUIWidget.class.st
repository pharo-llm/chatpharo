"
I describe one Spec widget of a window to a model, and act on it for the model.

A model cannot see pixels. I turn a presenter into the few facts that matter —
what kind of control it is, its label or text, whether it is enabled — and I
offer the three gestures a user has: `activate` (click), `type:` and `select:`.
My subclasses know one family of Spec presenters each; a gesture that makes no
sense for a control answers an explanation instead of failing.

`ChatPharoUIWidget class >> forPresenter:` is the only place that looks at the
class of a presenter: it is the adapter boundary between Spec and the tools.
"
Class {
	#name : 'ChatPharoUIWidget',
	#superclass : 'Object',
	#instVars : [
		'presenter',
		'id'
	],
	#category : 'AI-ChatPharo-Spec-UIAutomation',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'UIAutomation'
}

{ #category : 'instance creation' }
ChatPharoUIWidget class >> adapterClasses [
	"Each adapter with the Spec presenter family it handles; the first match wins."

	^ {
		  ChatPharoUICheckBox.
		  ChatPharoUIToolbarButton.
		  ChatPharoUIButton.
		  ChatPharoUITextField.
		  ChatPharoUIDropList.
		  ChatPharoUIList.
		  ChatPharoUITabs.
		  ChatPharoUILabel }
]

{ #category : 'instance creation' }
ChatPharoUIWidget class >> forPresenter: aPresenter [
	"Answer the adapter for aPresenter, or nil when it is a container with nothing to act on."

	^ self adapterClasses
		  detect: [ :each | aPresenter isKindOf: each presenterClass ]
		  ifFound: [ :adapterClass | adapterClass new setPresenter: aPresenter ]
		  ifNone: [ nil ]
]

{ #category : 'accessing' }
ChatPharoUIWidget class >> presenterClass [

	^ self subclassResponsibility
]

{ #category : 'gestures' }
ChatPharoUIWidget >> activate [

	^ self unsupported: 'clicked'
]

{ #category : 'describing' }
ChatPharoUIWidget >> describe [

	| description |
	description := Dictionary new
		               at: 'id' put: id;
		               at: 'kind' put: self kind;
		               at: 'text' put: self text;
		               at: 'enabled' put: presenter isEnabled;
		               yourself.
	self describeDetailsOn: description.
	^ description
]

{ #category : 'describing' }
ChatPharoUIWidget >> describeDetailsOn: aDictionary [
	"Hook: add what is specific to my kind of control."
]

{ #category : 'accessing' }
ChatPharoUIWidget >> id [

	^ id
]

{ #category : 'accessing' }
ChatPharoUIWidget >> id: anInteger [

	id := anInteger
]

{ #category : 'accessing' }
ChatPharoUIWidget >> kind [

	^ self subclassResponsibility
]

{ #category : 'testing' }
ChatPharoUIWidget >> matches: aStringOrId [
	"Whether the model designates me: by id, or by my text ignoring case."

	^ aStringOrId = id or: [ aStringOrId asString asLowercase = self text asLowercase ]
]

{ #category : 'gestures' }
ChatPharoUIWidget >> select: anIndexOrLabel [

	^ self unsupported: 'used to select an item'
]

{ #category : 'initialization' }
ChatPharoUIWidget >> setPresenter: aPresenter [

	presenter := aPresenter
]

{ #category : 'accessing' }
ChatPharoUIWidget >> text [

	^ ''
]

{ #category : 'gestures' }
ChatPharoUIWidget >> type: aString [

	^ self unsupported: 'typed into'
]

{ #category : 'private' }
ChatPharoUIWidget >> unsupported: aGesture [

	^ Dictionary with: 'error' -> ('A ' , self kind , ' cannot be ' , aGesture , '.')
]
