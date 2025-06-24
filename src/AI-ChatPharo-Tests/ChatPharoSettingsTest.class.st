Class {
	#name : 'ChatPharoSettingsTest',
	#superclass : 'TestCase',
	#instVars : [
		'settings',
		'mockApi'
	],
	#category : 'AI-ChatPharo-Tests-Settings',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Settings'
}

{ #category : 'running' }
ChatPharoSettingsTest >> setUp [

	super setUp.
	
	settings := ChatPharoSettings new.
	mockApi := ChatPharoMockAgent new.
	settings instVarNamed: #agent put: mockApi
]

{ #category : 'running' }
ChatPharoSettingsTest >> tearDown [

	ChatPharoSettings resetDefault.
	super tearDown
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testAvailableApiChoicesReturnsAssociations [
	| choices |
	choices := settings availableApiChoices.
	self assert: (choices allSatisfy: [ :assoc | assoc key isString and: [ assoc value isClass ] ]).
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testBrowserToolsEnabledDefault [ 
        self deny: settings browserToolsEnabled isNil.
        self assert: settings browserToolsEnabled notEmpty
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testEnableDisableBrowserTool [ 

        | name |
        name := settings browserToolsEnabled anyOne.
        settings disableBrowserTool: name.
        self deny: (settings browserToolsEnabled includes: name).
        settings enableBrowserTool: name.
        self assert: (settings browserToolsEnabled includes: name)
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testModelsDelegation [
	self
		assert: settings models
		equals: (ChatPharoMockAgent modelNames).

]

{ #category : 'tests' }
ChatPharoSettingsTest >> testSwitchModelAfterAgentSwitch [ 

    settings useApi: ChatPharoMockAgent.
    settings useModel: 'mock-advanced'.

    self assert: settings agent model equals: 'mock-advanced'.
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testSwitchingAgentPreservesModel [ 

    settings useApi: ChatPharoMockAgent.
    settings useModel: 'mock-advanced'.
    self assert: settings agent model equals: 'mock-advanced'.
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testUseApiReplacesAgentSubclass [ 

    settings useApi: ChatPharoNullAgent.
    self assert: settings agent class equals: ChatPharoNullAgent.
]

{ #category : 'tests' }
ChatPharoSettingsTest >> testUseModel [
	settings useModel: 'mock-advanced'.
	self assert: (mockApi instVarNamed: #currentModel) equals: 'mock-advanced'.
]
