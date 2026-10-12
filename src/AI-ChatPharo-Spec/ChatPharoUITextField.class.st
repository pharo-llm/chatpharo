"
I adapt single-line inputs and text areas. My text is what the field contains;
the placeholder tells what it is for.
"
Class {
	#name : 'ChatPharoUITextField',
	#superclass : 'ChatPharoUIWidget',
	#category : 'AI-ChatPharo-Spec-UIAutomation',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'UIAutomation'
}

{ #category : 'accessing' }
ChatPharoUITextField class >> presenterClass [

	^ SpAbstractTextPresenter
]

{ #category : 'describing' }
ChatPharoUITextField >> describeDetailsOn: aDictionary [

	aDictionary at: 'placeholder' put: (presenter placeholder ifNil: [ '' ]) asString
]

{ #category : 'accessing' }
ChatPharoUITextField >> kind [

	^ 'text_field'
]

{ #category : 'testing' }
ChatPharoUITextField >> matches: aStringOrId [
	"A field is found by its id or by its placeholder; its content changes all the time."

	^ aStringOrId = id or: [ aStringOrId asString asLowercase = (presenter placeholder ifNil: [ '' ]) asString asLowercase ]
]

{ #category : 'accessing' }
ChatPharoUITextField >> text [

	^ (presenter text ifNil: [ '' ]) asString truncateWithElipsisTo: 500
]

{ #category : 'gestures' }
ChatPharoUITextField >> type: aString [

	presenter text: aString.
	^ Dictionary with: 'text' -> aString
]
