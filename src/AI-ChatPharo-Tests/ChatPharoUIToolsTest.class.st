Class {
	#name : 'ChatPharoUIToolsTest',
	#superclass : 'TestCase',
	#instVars : [
		'tools',
		'window',
		'clicks'
	],
	#category : 'AI-ChatPharo-Tests-UIAutomation',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'UIAutomation'
}

{ #category : 'private' }
ChatPharoUIToolsTest >> call: aToolName with: arguments [

	^ (tools tools detect: [ :each | each name = aToolName ]) applyTo: arguments
]

{ #category : 'private' }
ChatPharoUIToolsTest >> openSampleWindow [
	"A small form: a field, a check box, a list and a button that counts its clicks."

	| presenter |
	presenter := SpPresenter new.
	presenter layout: (SpBoxLayout newTopToBottom
			 add: (presenter newTextInput
					  placeholder: 'Your name';
					  yourself);
			 add: (presenter newCheckBox
					  label: 'Remember me';
					  yourself);
			 add: (presenter newList
					  items: #( 'red' 'green' 'blue' );
					  yourself);
			 add: (presenter newButton
					  label: 'Save';
					  action: [ clicks := clicks + 1 ];
					  yourself);
			 yourself).
	window := presenter open.
	window title: 'ChatPharo UI tools sample'
]

{ #category : 'running' }
ChatPharoUIToolsTest >> setUp [

	super setUp.
	tools := ChatPharoUITools new.
	clicks := 0.
	self openSampleWindow
]

{ #category : 'running' }
ChatPharoUIToolsTest >> tearDown [

	window ifNotNil: [ window close ].
	super tearDown
]

{ #category : 'tests' }
ChatPharoUIToolsTest >> testClickButtonByItsLabel [

	self call: 'click_widget' with: (Dictionary with: 'window' -> 'UI tools sample' with: 'widget' -> 'Save').
	self assert: clicks equals: 1
]

{ #category : 'tests' }
ChatPharoUIToolsTest >> testClickCheckBoxTogglesIt [

	| result |
	result := self call: 'click_widget' with: (Dictionary with: 'window' -> 'UI tools sample' with: 'widget' -> 'Remember me').
	self assert: (result at: 'checked')
]

{ #category : 'tests' }
ChatPharoUIToolsTest >> testCloseWindow [

	self call: 'close_window' with: (Dictionary with: 'window' -> 'ChatPharo UI tools sample').
	self assert: (ChatPharoUIWindow designatedBy: 'ChatPharo UI tools sample') isNil.
	window := nil
]

{ #category : 'tests' }
ChatPharoUIToolsTest >> testContainersAreNotControls [

	self assert: (ChatPharoUIWidget forPresenter: SpPresenter new) isNil
]

{ #category : 'tests' }
ChatPharoUIToolsTest >> testDescribeWindowListsItsControls [

	| widgets |
	widgets := (self call: 'describe_window' with: (Dictionary with: 'window' -> 'UI tools sample')) at: 'widgets'.
	self assert: (widgets collect: [ :each | each at: 'kind' ]) asArray equals: #( 'text_field' 'checkbox' 'list' 'button' ).
	self assert: (widgets collect: [ :each | each at: 'id' ]) asArray equals: #( 1 2 3 4 ).
	self assert: ((widgets at: 3) at: 'items') equals: #( 'red' 'green' 'blue' ).
	self assert: ((widgets at: 1) at: 'placeholder') equals: 'Your name'
]

{ #category : 'tests' }
ChatPharoUIToolsTest >> testGestureOnTheWrongKindOfControlExplainsWhy [

	| result |
	result := self call: 'type_text' with: (Dictionary with: 'window' -> 'UI tools sample' with: 'widget' -> 'Save' with: 'text' -> 'x').
	self assert: ((result at: 'error') includesSubstring: 'button')
]

{ #category : 'tests' }
ChatPharoUIToolsTest >> testListWindowsShowsTheSampleWindow [

	| titles |
	titles := ((self call: 'list_windows' with: Dictionary new) at: 'windows') collect: [ :each | each at: 'title' ].
	self assert: (titles includes: 'ChatPharo UI tools sample')
]

{ #category : 'tests' }
ChatPharoUIToolsTest >> testSelectItemByTextAndByPosition [

	| result |
	result := self call: 'select_item' with: (Dictionary with: 'window' -> 'UI tools sample' with: 'widget' -> '3' with: 'item' -> 'green').
	self assert: (result at: 'selected') equals: 'green'.
	result := self call: 'select_item' with: (Dictionary with: 'window' -> 'UI tools sample' with: 'widget' -> 3 with: 'item' -> '3').
	self assert: (result at: 'selected') equals: 'blue'
]

{ #category : 'tests' }
ChatPharoUIToolsTest >> testToolbarButtonsAreControlsToo [

	| button clicked |
	clicked := false.
	button := ChatPharoUIWidget forPresenter: (SpToolbarButtonPresenter new
			           label: 'Settings';
			           action: [ clicked := true ];
			           yourself).
	self assert: button kind equals: 'toolbar_button'.
	self assert: button text equals: 'Settings'.
	button activate.
	self assert: clicked
]

{ #category : 'tests' }
ChatPharoUIToolsTest >> testTypeTextIntoFieldFoundByPlaceholder [

	| described |
	self call: 'type_text' with: (Dictionary with: 'window' -> 'UI tools sample' with: 'widget' -> 'Your name' with: 'text' -> 'Ada').
	described := (self call: 'describe_window' with: (Dictionary with: 'window' -> 'UI tools sample')) at: 'widgets'.
	self assert: (described first at: 'text') equals: 'Ada'
]

{ #category : 'tests' }
ChatPharoUIToolsTest >> testUnknownWindowIsReported [

	self assert: ((self call: 'describe_window' with: (Dictionary with: 'window' -> 'no such window anywhere')) includesKey: 'error')
]

{ #category : 'tests' }
ChatPharoUIToolsTest >> testWorldChangingGesturesAskForConfirmation [

	self assert: ((tools tools select: [ :each | each isMutating ]) collect: [ :each | each name ]) asArray equals: #( 'click_widget' 'type_text' 'select_item' 'open_browser' 'close_window' )
]
