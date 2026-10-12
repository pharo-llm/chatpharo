"
I let the model **navigate inside a user interface**: see which windows are
open, read the controls of a window, click, type, select, open a System Browser
on a class or method, and close a window.

The model works on the structure of the UI (`ChatPharoUIWindow`,
`ChatPharoUIWidget`), not on pixels, so it can drive any window built with Spec,
including the user's own application under development.

Gestures run on the UI process. A click that opens a modal dialog does not
return until the dialog is closed, so I stop waiting after `gestureTimeout` and
tell the model to look at the windows again. Everything except looking asks for
the user's confirmation first.
"
Class {
	#name : 'ChatPharoUITools',
	#superclass : 'ChatPharoToolProvider',
	#category : 'AI-ChatPharo-Spec-UIAutomation',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'UIAutomation'
}

{ #category : 'tools' }
ChatPharoUITools >> clickWidgetTool [

	^ (self
		   toolNamed: 'click_widget'
		   description: 'Clicks a button, toolbar button or check box of a window. Call describe_window first to know the controls and their ids.'
		   properties: (Dictionary with: 'window' -> self windowProperty with: 'widget' -> self widgetProperty)
		   required: #( 'window' 'widget' )
		   do: [ :arguments | self on: arguments gesture: [ :widget | widget activate ] ])
		  beMutating;
		  yourself
]

{ #category : 'tools' }
ChatPharoUITools >> closeWindowTool [

	^ (self
		   toolNamed: 'close_window'
		   description: 'Closes a window.'
		   properties: (Dictionary with: 'window' -> self windowProperty)
		   required: #( 'window' )
		   do: [ :arguments |
			   self withWindow: arguments do: [ :window |
				   window close.
				   Dictionary with: 'closed' -> window title ] ])
		  beMutating;
		  yourself
]

{ #category : 'tools' }
ChatPharoUITools >> describeWindowTool [

	^ self
		  toolNamed: 'describe_window'
		  description: 'Describes the controls of a window: buttons, check boxes, text fields, lists, drop-downs, tabs and labels, each with an id, its text and its state. Use the ids with click_widget, type_text and select_item.'
		  properties: (Dictionary with: 'window' -> self windowProperty)
		  required: #( 'window' )
		  do: [ :arguments | self withWindow: arguments do: [ :window | window describe ] ]
]

{ #category : 'accessing' }
ChatPharoUITools >> gestureTimeout [

	^ 5
]

{ #category : 'tools' }
ChatPharoUITools >> listWindowsTool [

	^ self
		  toolNamed: 'list_windows'
		  description: 'Lists the windows open in the Pharo image, front-most first, and says for each whether its controls can be described and operated.'
		  properties: Dictionary new
		  required: #(  )
		  do: [ :arguments | self onUIProcess: [ Dictionary with: 'windows' -> self windowSummaries ] ]
]

{ #category : 'private' }
ChatPharoUITools >> on: arguments gesture: aBlock [
	"Evaluate aBlock with the designated control and answer what it did, plus the windows now open."

	^ self withWindow: arguments do: [ :window |
		  (window widgetDesignatedBy: (self widgetDesignatorIn: arguments))
			  ifNil: [ Dictionary with: 'error' -> 'No such control in this window. Call describe_window to see its controls.' ]
			  ifNotNil: [ :widget |
				  (aBlock value: widget)
					  at: 'windows_now' put: self windowSummaries;
					  yourself ] ]
]

{ #category : 'private' }
ChatPharoUITools >> onUIProcess: aBlock [
	"Answer the value of aBlock evaluated on the UI process, or a notice when it is still
	 running after gestureTimeout, which happens when the gesture opened a modal dialog."

	| result finished |
	UIManager default uiProcess == Processor activeProcess ifTrue: [ ^ aBlock value ].
	finished := Semaphore new.
	UIManager default defer: [
		[ result := aBlock value ] ensure: [ finished signal ] ].
	(finished waitTimeoutSeconds: self gestureTimeout) ifTrue: [
		^ Dictionary with: 'status' -> 'The gesture is still running, probably because it opened a dialog. Call list_windows to see what is open now.' ].
	^ result
]

{ #category : 'private' }
ChatPharoUITools >> openBrowserOn: arguments [

	| class |
	class := self class environment at: (arguments at: 'class_name') asSymbol ifAbsent: [
		         ^ Dictionary with: 'error' -> ('There is no class named ' , (arguments at: 'class_name')) ].
	(arguments at: 'side' ifAbsent: [ 'instance' ]) = 'class' ifTrue: [ class := class classSide ].
	^ self onUIProcess: [
		  arguments
			  at: 'selector'
			  ifPresent: [ :selector | Smalltalk tools browser openOnClass: class selector: selector asSymbol ]
			  ifAbsent: [ Smalltalk tools browser openOnClass: class ].
		  Dictionary with: 'opened' -> class name with: 'windows_now' -> self windowSummaries ]
]

{ #category : 'tools' }
ChatPharoUITools >> openBrowserTool [

	^ (self
		   toolNamed: 'open_browser'
		   description: 'Opens a System Browser on a class, or on one of its methods, so the user sees the code you are talking about.'
		   properties: (Dictionary
				    with: 'class_name' -> (self property: 'string' description: 'Name of the class to browse')
				    with: 'selector' -> (self property: 'string' description: 'Optional selector of the method to show')
				    with: 'side' -> (self property: 'string' description: '"instance" (default) or "class"'))
		   required: #( 'class_name' )
		   do: [ :arguments | self openBrowserOn: arguments ])
		  beMutating;
		  yourself
]

{ #category : 'tools' }
ChatPharoUITools >> selectItemTool [

	^ (self
		   toolNamed: 'select_item'
		   description: 'Selects an item of a list, a table or a drop-down, or shows a tab. Give the position of the item starting at 1, or its exact text.'
		   properties: (Dictionary
				    with: 'window' -> self windowProperty
				    with: 'widget' -> self widgetProperty
				    with: 'item' -> (self property: 'string' description: 'Position starting at 1, or exact text of the item or tab'))
		   required: #( 'window' 'widget' 'item' )
		   do: [ :arguments | self on: arguments gesture: [ :widget | widget select: (self designator: (arguments at: 'item')) ] ])
		  beMutating;
		  yourself
]

{ #category : 'accessing' }
ChatPharoUITools >> summary [

	^ 'List windows, read their controls, click, type, select, open a System Browser, close a window.'
]

{ #category : 'accessing' }
ChatPharoUITools >> title [

	^ 'User interface navigation'
]

{ #category : 'accessing' }
ChatPharoUITools >> tools [

	^ {
		  self listWindowsTool.
		  self describeWindowTool.
		  self clickWidgetTool.
		  self typeTextTool.
		  self selectItemTool.
		  self openBrowserTool.
		  self closeWindowTool }
]

{ #category : 'tools' }
ChatPharoUITools >> typeTextTool [

	^ (self
		   toolNamed: 'type_text'
		   description: 'Replaces the content of a text field or text area of a window.'
		   properties: (Dictionary
				    with: 'window' -> self windowProperty
				    with: 'widget' -> self widgetProperty
				    with: 'text' -> (self property: 'string' description: 'The new content of the field'))
		   required: #( 'window' 'widget' 'text' )
		   do: [ :arguments | self on: arguments gesture: [ :widget | widget type: (arguments at: 'text') ] ])
		  beMutating;
		  yourself
]

{ #category : 'private' }
ChatPharoUITools >> designator: aValue [
	"Models send positions and ids as numbers or as digit strings; answer an Integer for both."

	^ (aValue isString and: [ aValue notEmpty and: [ aValue isAllDigits ] ])
		  ifTrue: [ aValue asInteger ]
		  ifFalse: [ aValue ]
]

{ #category : 'private' }
ChatPharoUITools >> widgetDesignatorIn: arguments [

	^ self designator: (arguments at: 'widget')
]

{ #category : 'private' }
ChatPharoUITools >> widgetProperty [

	^ self property: 'string' description: 'The id of the control as answered by describe_window, or its exact text'
]

{ #category : 'private' }
ChatPharoUITools >> windowProperty [

	^ self property: 'string' description: 'Title of the window, or a part of it'
]

{ #category : 'private' }
ChatPharoUITools >> windowSummaries [

	^ (ChatPharoUIWindow all collect: [ :each | each summary ]) asArray
]

{ #category : 'private' }
ChatPharoUITools >> withWindow: arguments do: aBlock [

	^ self onUIProcess: [
		  (ChatPharoUIWindow designatedBy: (arguments at: 'window'))
			  ifNil: [ Dictionary with: 'error' -> 'No window with that title. Call list_windows to see the open windows.' ]
			  ifNotNil: [ :window | aBlock value: window ] ]
]
