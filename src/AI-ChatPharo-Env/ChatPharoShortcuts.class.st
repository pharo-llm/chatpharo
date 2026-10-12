"
I am a class defining the current shortcuts of ChatPharo. My main purpose is to avoid the duplication of shortcut definition amongst ChatPharo tools and to allow to change the shortcuts from a single place.
Users may query me to know the key combinations used for ChatPharo actions.
EXAMPLES
ChatPharoShortcuts current openChatPharoShortcut => O, C (sequential)
ChatPharoShortcuts current askShortcut => Cmd-P
ChatPharoShortcuts current codeShortcut => Cmd-Shift-K
"
Class {
	#name : 'ChatPharoShortcuts',
	#superclass : 'Object',
	#category : 'AI-ChatPharo-Env-Menu',
	#package : 'AI-ChatPharo-Env',
	#tag : 'Menu'
}

{ #category : 'keymaps' }
ChatPharoShortcuts class >> chatPharoKeymapOn: aBuilder [
	<keymap>

	(aBuilder shortcut: #openChatPharo)
		category: #ChatPharo
		default: self current openChatPharoShortcut
		do: [ :target | self openChatPharo ]
		description: 'Open ChatPharo'
]

{ #category : 'keymaps' }
ChatPharoShortcuts class >> current [

	^ self new
]

{ #category : 'keymaps' }
ChatPharoShortcuts class >> installAsGlobalCategory [
	"Install ChatPharo shortcuts as a global keyboard category"

	| category |
	category := KMCategory named: #ChatPharo.

	category
		addKeymapEntry: (KMKeymap
			shortcut: self current openChatPharoShortcut
			action: [ self openChatPharo ]).

	KMRepository default addCategory: category.
	
	^ category
]

{ #category : 'keymaps' }
ChatPharoShortcuts class >> openChatPharo [
	"Open a new ChatPharo window"

	ChatPharo default open
]

{ #category : 'visiting' }
ChatPharoShortcuts >> acceptCommitShortcut [ 

	^ $s actionModifier
]

{ #category : 'visiting' }
ChatPharoShortcuts >> askShortcut [

	^ $p meta
]

{ #category : 'visiting' }
ChatPharoShortcuts >> codeShortcut [

	^ $k meta shift
]

{ #category : 'visiting' }
ChatPharoShortcuts >> openChatPharoShortcut [

	^ $o asKeyCombination, $c asKeyCombination
]
