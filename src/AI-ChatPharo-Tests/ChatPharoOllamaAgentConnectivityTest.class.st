Class {
	#name : 'ChatPharoOllamaAgentConnectivityTest',
	#superclass : 'TestCase',
	#instVars : [
		'oldClass'
	],
	#category : 'AI-ChatPharo-Tests-Agent',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Agent'
}

{ #category : 'running' }
ChatPharoOllamaAgentConnectivityTest >> setUp [ 

    super setUp.
    oldClass := Smalltalk at: #ZnClient.
    Smalltalk at: #ZnClient put: ChatPharoZnClientReachabilityStub.
]

{ #category : 'running' }
ChatPharoOllamaAgentConnectivityTest >> tearDown [ 

    Smalltalk at: #ZnClient put: oldClass.
    super tearDown
]

{ #category : 'running' }
ChatPharoOllamaAgentConnectivityTest >> testIsReachableFalseOnNetworkError [ 

    ChatPharoZnClientReachabilityStub shouldFail: true.
    self deny: ChatPharoOllamaAgent isReachable.
]

{ #category : 'running' }
ChatPharoOllamaAgentConnectivityTest >> testIsReachableTrueWhenNoError [ 

    ChatPharoZnClientReachabilityStub shouldFail: false.
    self assert: ChatPharoOllamaAgent isReachable.
]

{ #category : 'running' }
ChatPharoOllamaAgentConnectivityTest >> testTestConnectionFalseOnFailure [ 

    ChatPharoZnClientReachabilityStub shouldFail: true.
    self deny: (ChatPharoOllamaAgent new testConnection).
]

{ #category : 'running' }
ChatPharoOllamaAgentConnectivityTest >> testTestConnectionTrueWhenNoError [ 

    ChatPharoZnClientReachabilityStub shouldFail: false.
    self assert: (ChatPharoOllamaAgent new testConnection).
]
