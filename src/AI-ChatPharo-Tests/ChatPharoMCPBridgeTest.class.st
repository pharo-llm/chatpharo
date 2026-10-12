Class {
	#name : 'ChatPharoMCPBridgeTest',
	#superclass : 'TestCase',
	#instVars : [
		'bridge'
	],
	#category : 'AI-ChatPharo-Tests-MCP',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'MCP'
}

{ #category : 'private' }
ChatPharoMCPBridgeTest >> post: aJsonString [

	^ bridge handleRequest: ((ZnRequest post: 'http://localhost:8765/mcp')
			   entity: (ZnEntity json: aJsonString);
			   yourself)
]

{ #category : 'private' }
ChatPharoMCPBridgeTest >> resultOf: aJsonString [

	^ (STONJSON fromString: (self post: aJsonString) contents) at: 'result'
]

{ #category : 'running' }
ChatPharoMCPBridgeTest >> setUp [

	super setUp.
	bridge := ChatPharoMCPBridge new
]

{ #category : 'running' }
ChatPharoMCPBridgeTest >> tearDown [

	bridge stop.
	ChatPharoSettings resetDefault.
	super tearDown
]

{ #category : 'tests' }
ChatPharoMCPBridgeTest >> testBadJsonAnswersAJsonRpcParseError [

	| reply |
	reply := STONJSON fromString: (self post: '{oops') contents.
	self assert: ((reply at: 'error') at: 'code') equals: -32700
]

{ #category : 'tests' }
ChatPharoMCPBridgeTest >> testConnectionInstructionsNameTheTerminalAgents [

	| instructions |
	instructions := bridge connectionInstructions.
	#( 'claude mcp add' 'codex mcp add' 'gemini mcp add' 'http://localhost:8765/mcp' ) do: [ :each |
		self assert: (instructions includesSubstring: each) ]
]

{ #category : 'tests' }
ChatPharoMCPBridgeTest >> testDisabledToolIsNotExposed [

	| names |
	ChatPharoSettings default disableBrowserTool: 'find_senders'.
	names := ((self resultOf: '{"jsonrpc":"2.0","id":1,"method":"tools/list"}') at: 'tools') collect: [ :each | each at: 'name' ].
	self deny: (names includes: 'find_senders').
	self assert: (names includes: 'find_implementors')
]

{ #category : 'tests' }
ChatPharoMCPBridgeTest >> testForeignOriginIsRefused [

	| request |
	request := (ZnRequest post: 'http://localhost:8765/mcp')
		           entity: (ZnEntity json: '{"jsonrpc":"2.0","id":1,"method":"tools/list"}');
		           yourself.
	request headers at: 'Origin' put: 'https://evil.example'.
	self assert: (bridge handleRequest: request) code equals: 403
]

{ #category : 'tests' }
ChatPharoMCPBridgeTest >> testInitializeAnswersServerInfo [

	| result |
	result := self resultOf: '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"test","version":"1"}}}'.
	self assert: ((result at: 'serverInfo') at: 'name') equals: 'chatpharo'.
	self assert: ((result at: 'capabilities') includesKey: 'tools')
]

{ #category : 'tests' }
ChatPharoMCPBridgeTest >> testNotificationIsAccepted [

	self assert: (self post: '{"jsonrpc":"2.0","method":"notifications/initialized"}') code equals: 202
]

{ #category : 'tests' }
ChatPharoMCPBridgeTest >> testOnlyPostOnTheMcpPathIsServed [

	self assert: (bridge handleRequest: (ZnRequest get: 'http://localhost:8765/mcp')) code equals: 405.
	self assert: (bridge handleRequest: (ZnRequest post: 'http://localhost:8765/other')) code equals: 404
]

{ #category : 'tests' }
ChatPharoMCPBridgeTest >> testStartAndStopOverRealHttp [

	| response |
	bridge port: 18765.
	bridge start.
	self assert: bridge isRunning.
	response := ZnClient new
		            url: bridge url;
		            entity: (ZnEntity json: '{"jsonrpc":"2.0","id":1,"method":"ping"}');
		            post;
		            response.
	self assert: response isSuccess.
	bridge stop.
	self deny: bridge isRunning
]

{ #category : 'tests' }
ChatPharoMCPBridgeTest >> testToolCallRunsTheChatPharoToolAndAnswersItsJson [

	| result payload |
	result := self resultOf: '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"find_implementors","arguments":{"selector":"connectionInstructions"}}}'.
	payload := STONJSON fromString: ((result at: 'content') first at: 'text').
	self assert: ((payload at: 'implementors') first at: 'class') equals: 'ChatPharoMCPBridge'
]

{ #category : 'tests' }
ChatPharoMCPBridgeTest >> testToolsListExposesTheEnabledChatPharoTools [

	| tools |
	tools := (self resultOf: '{"jsonrpc":"2.0","id":1,"method":"tools/list"}') at: 'tools'.
	self assert: (tools collect: [ :each | each at: 'name' ]) asSet equals: (ChatPharoToolbox new enabledTools collect: [ :each | each name ]) asSet.
	self assert: (tools allSatisfy: [ :each | (each at: 'inputSchema') includesKey: 'type' ])
]
