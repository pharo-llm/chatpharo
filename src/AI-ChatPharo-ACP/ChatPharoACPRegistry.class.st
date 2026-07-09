Class {
	#name : 'ChatPharoACPRegistry',
	#superclass : 'Object',
	#instVars : [
		'agents'
	],
	#category : 'AI-ChatPharo-ACP',
	#package : 'AI-ChatPharo-ACP'
}

{ #category : 'initialization' }
ChatPharoACPRegistry >> addAgent: anACPAgent [

	(self agents anySatisfy: [ :a | a name = anACPAgent name ]) ifTrue: [
		Error signal: 'An ACP agent with this name already exists: ' , anACPAgent name ].
	self agents add: anACPAgent.
	anACPAgent enabled ifTrue: [ anACPAgent connect ].
	ChatPharoLogger logSystem: 'ACP agent added' details: (Dictionary new
			 at: 'agent' put: anACPAgent name;
			 at: 'enabled' put: anACPAgent enabled;
			 yourself)
]

{ #category : 'initialization' }
ChatPharoACPRegistry >> agents [

	^ agents ifNil: [ agents := OrderedCollection new ]
]

{ #category : 'initialization' }
ChatPharoACPRegistry >> agents: aCollection [

	agents := aCollection
]

{ #category : 'initialization' }
ChatPharoACPRegistry >> connectAll [

	self enabledAgents do: [ :agent | agent connect ]
]

{ #category : 'initialization' }
ChatPharoACPRegistry >> connectedAgents [

	^ self agents select: [ :a | a isConnected ]
]

{ #category : 'initialization' }
ChatPharoACPRegistry >> disconnectAll [

	self agents do: [ :agent | agent disconnect ]
]

{ #category : 'initialization' }
ChatPharoACPRegistry >> enabledAgents [

	^ self agents select: [ :a | a enabled ]
]

{ #category : 'initialization' }
ChatPharoACPRegistry >> findAgentNamed: aName [

	^ self agents detect: [ :a | a name = aName ] ifNone: [ nil ]
]

{ #category : 'initialization' }
ChatPharoACPRegistry >> initialize [

	super initialize.
	agents := OrderedCollection new
]

{ #category : 'initialization' }
ChatPharoACPRegistry >> removeAgent: anACPAgent [

	anACPAgent disconnect.
	self agents remove: anACPAgent ifAbsent: [ ]
]
