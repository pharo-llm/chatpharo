Class {
	#name : 'ChatPharoFeatureSettingsTest',
	#superclass : 'TestCase',
	#category : 'AI-ChatPharo-Tests-Settings',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Settings'
}

{ #category : 'running' }
ChatPharoFeatureSettingsTest >> tearDown [

	ChatPharoSettings resetDefault.
	super tearDown
]

{ #category : 'tests' }
ChatPharoFeatureSettingsTest >> testApplicationsAndExtensionsShareTheSameUI [

	self assert: ChatPharoApplicationSettingsPresenter superclass equals: ChatPharoFeatureSettingsPresenter.
	self assert: ChatPharoExtensionSettingsPresenter superclass equals: ChatPharoFeatureSettingsPresenter
]

{ #category : 'tests' }
ChatPharoFeatureSettingsTest >> testEveryApplicationCanBeShown [

	| presenter |
	presenter := ChatPharoApplicationSettingsPresenter on: ChatPharoSettings default.
	presenter features do: [ :each | self shouldnt: [ presenter showFeature: each ] raise: Error ]
]

{ #category : 'tests' }
ChatPharoFeatureSettingsTest >> testEveryExtensionCanBeShown [

	| presenter |
	presenter := ChatPharoExtensionSettingsPresenter on: ChatPharoSettings default.
	presenter features do: [ :each | self shouldnt: [ presenter showFeature: each ] raise: Error ]
]

{ #category : 'tests' }
ChatPharoFeatureSettingsTest >> testExtensionIsSwitchedFromItsCheckBox [

	| settings debugger |
	settings := ChatPharoSettings default.
	debugger := (ChatPharoExtensionSettingsPresenter on: settings) features detect: [ :each | each name = 'Debugger' ].
	debugger enable: true.
	self assert: settings debuggerExtensionEnabled.
	self assert: debugger isEnabled.
	debugger enable: false.
	self deny: settings debuggerExtensionEnabled
]

{ #category : 'tests' }
ChatPharoFeatureSettingsTest >> testExtensionsListTheirTools [

	| features |
	features := (ChatPharoExtensionSettingsPresenter on: ChatPharoSettings default) features.
	self assert: (features collect: [ :each | each name ]) asArray equals: #( 'System Browser' 'Iceberg' 'Debugger' ).
	self assert: (((features detect: [ :each | each name = 'Debugger' ]) tools collect: [ :each | each name ]) includes: 'get_stack_trace')
]

{ #category : 'tests' }
ChatPharoFeatureSettingsTest >> testFeatureThatCannotBeSwitchedOffStaysOn [

	| feature |
	feature := ChatPharoSettingsFeature named: 'Tools' description: 'x' icon: #smallConfiguration.
	feature enable: false.
	self assert: feature isEnabled.
	self assert: feature tools isEmpty
]
