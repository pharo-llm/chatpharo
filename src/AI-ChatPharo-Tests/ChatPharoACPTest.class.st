Class {
	#name : 'ChatPharoACPTest',
	#superclass : 'TestCase',
	#instVars : [
		'registry',
		'agent'
	],
	#category : 'AI-ChatPharo-Tests',
	#package : 'AI-ChatPharo-Tests'
}

{ #category : 'running' }
ChatPharoACPTest >> setUp [

	super setUp.
	registry := ChatPharoACPRegistry new.
	agent := ChatPharoACPAgent new
		         name: 'Test Agent';
		         enabled: false;
		         yourself
]

{ #category : 'running' }
ChatPharoACPTest >> testACPAgentCreation [

	self assert: agent name equals: 'Test Agent'.
	self assert: agent enabled not.
	self assert: agent isDisconnected
]

{ #category : 'running' }
ChatPharoACPTest >> testACPRegistryAddAgent [

	registry addAgent: agent.
	self assert: registry agents size equals: 1.
	self assert: (registry findAgentNamed: 'Test Agent') equals: agent
]

{ #category : 'running' }
ChatPharoACPTest >> testACPRegistryConnectedAgentsEmpty [

	registry addAgent: agent.
	self assert: registry connectedAgents isEmpty
]

{ #category : 'running' }
ChatPharoACPTest >> testACPRegistryDuplicateAgentNames [

	| agent2 |
	agent2 := ChatPharoACPAgent new
		          name: 'Test Agent';
		          enabled: false;
		          yourself.
	registry addAgent: agent.
	self should: [ registry addAgent: agent2 ] raise: Error
]

{ #category : 'running' }
ChatPharoACPTest >> testACPRegistryEnabledAgents [

	registry addAgent: agent.
	self assert: registry enabledAgents isEmpty
]

{ #category : 'running' }
ChatPharoACPTest >> testACPRegistryFindAgent [

	registry addAgent: agent.
	self assert: (registry findAgentNamed: 'Test Agent') equals: agent.
	self assert: (registry findAgentNamed: 'Nonexistent') isNil
]

{ #category : 'running' }
ChatPharoACPTest >> testACPRegistryRemoveAgent [

	registry addAgent: agent.
	registry removeAgent: agent.
	self assert: registry agents isEmpty
]
