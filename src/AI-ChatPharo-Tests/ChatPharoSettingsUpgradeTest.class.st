Class {
	#name : 'ChatPharoSettingsUpgradeTest',
	#superclass : 'TestCase',
	#instVars : [
		'settings'
	],
	#category : 'AI-ChatPharo-Tests-Settings',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Settings'
}

{ #category : 'running' }
ChatPharoSettingsUpgradeTest >> setUp [

	super setUp.
	settings := ChatPharoSettings new
]

{ #category : 'running' }
ChatPharoSettingsUpgradeTest >> tearDown [

	ChatPharoSettings resetDefault.
	super tearDown
]

{ #category : 'tests' }
ChatPharoSettingsUpgradeTest >> testNewSettingsEnableEveryShippedTool [

	self assert: ((ChatPharoToolbox settings: settings) enabledBuiltInTools collect: [ :each | each name ]) asSet
		equals: (settings defaultBrowserToolsEnabled) asSet
]

{ #category : 'tests' }
ChatPharoSettingsUpgradeTest >> testSettingsSavedBeforeAnUpgradeGetTheNewTools [
	"Settings written by a version that did not know which tools it had seen."

	settings instVarNamed: #knownBrowserTools put: nil.
	settings instVarNamed: #browserToolsEnabled put: (OrderedCollection withAll: #( 'get_packages' 'get_class_methods' )).

	settings acknowledgeBuiltInToolNames: #( 'get_packages' 'get_class_methods' 'add_method' 'find_senders' 'propose_plan' ).

	self assert: (settings browserToolsEnabled includes: 'find_senders').
	self assert: (settings browserToolsEnabled includes: 'propose_plan').
	self deny: (settings browserToolsEnabled includes: 'add_method')
]

{ #category : 'tests' }
ChatPharoSettingsUpgradeTest >> testToolDisabledByTheUserStaysDisabled [

	| names |
	names := (ChatPharoToolbox settings: settings) builtInTools collect: [ :each | each name ].
	settings acknowledgeBuiltInToolNames: names.
	settings browserToolsEnabled remove: 'find_senders'.
	settings acknowledgeBuiltInToolNames: names.
	self deny: (settings browserToolsEnabled includes: 'find_senders')
]

{ #category : 'tests' }
ChatPharoSettingsUpgradeTest >> testUnreadableSettingsFileIsKeptAside [

	| directory file |
	directory := FileSystem memory root / 'chatpharo'.
	directory ensureCreateDirectory.
	file := directory / 'chatpharo-settings.ston'.
	file writeStreamDo: [ :stream | stream nextPutAll: 'ChatPharoSettings { #agent : NoSuchAgentClass { } }' ].
	ChatPharoSettings keepUnreadableSettingsAt: file because: (Error new messageText: 'unknown class').
	self assert: (directory / 'chatpharo-settings.unreadable.ston') contents equals: file contents
]
