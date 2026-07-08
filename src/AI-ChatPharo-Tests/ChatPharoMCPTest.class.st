Class {
	#name : 'ChatPharoMCPTest',
	#superclass : 'TestCase',
	#instVars : [
		'server',
		'registry',
		'settings'
	],
	#category : 'AI-ChatPharo-Tests-MCP',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'MCP'
}

{ #category : 'running' }
ChatPharoMCPTest >> setUp [

	super setUp.
	server := ChatPharoMCPServer new.
	registry := ChatPharoMCPRegistry new.
	settings := ChatPharoSettings new
]

{ #category : 'running' }
ChatPharoMCPTest >> tearDown [

	registry ifNotNil: [ registry disconnectAll ].
	super tearDown
]

{ #category : 'running' }
ChatPharoMCPTest >> testMCPIntegrationWithSettings [

	| testServer |
	testServer := ChatPharoMCPServer new
		              name: 'Integration Test Server';
		              enabled: false;
		              yourself.

	settings mcpRegistry addServer: testServer.

	self assert: settings mcpRegistry servers size equals: 1.
	self
		assert: (settings mcpRegistry findServerNamed: 'Integration Test Server')
		equals: testServer
]

{ #category : 'running' }
ChatPharoMCPTest >> testMCPRegistryAddServer [

	| testServer |
	testServer := ChatPharoMCPServer new
		              name: 'Test Server';
		              enabled: false;
		              yourself.

	registry addServer: testServer.

	self assert: registry servers size equals: 1.
	self assert: (registry findServerNamed: 'Test Server') equals: testServer
]

{ #category : 'running' }
ChatPharoMCPTest >> testMCPRegistryAllPromptsEmpty [

	self assert: registry allPrompts isEmpty
]

{ #category : 'running' }
ChatPharoMCPTest >> testMCPRegistryAllResourcesEmpty [

	self assert: registry allResources isEmpty
]

{ #category : 'running' }
ChatPharoMCPTest >> testMCPRegistryAllToolsAsClientsEmpty [

	self assert: registry allToolsAsClients isEmpty
]

{ #category : 'running' }
ChatPharoMCPTest >> testMCPRegistryAllToolsEmpty [

	self assert: registry allTools isEmpty
]

{ #category : 'running' }
ChatPharoMCPTest >> testMCPRegistryConnectedServersEmpty [

	| s1 |
	s1 := ChatPharoMCPServer new name: 'Server1'; enabled: false; yourself.
	registry addServer: s1.

	self assert: registry connectedServers isEmpty
]

{ #category : 'running' }
ChatPharoMCPTest >> testMCPRegistryCreation [

	self assert: registry servers isEmpty
]

{ #category : 'running' }
ChatPharoMCPTest >> testMCPRegistryDuplicateServerNames [

	| server1 server2 |
	server1 := ChatPharoMCPServer new
		           name: 'Same Name';
		           enabled: false;
		           yourself.
	server2 := ChatPharoMCPServer new
		           name: 'Same Name';
		           enabled: false;
		           yourself.

	registry addServer: server1.

	self
		should: [ registry addServer: server2 ]
		raise: Error
		description: 'Should raise error for duplicate server names'
]

{ #category : 'running' }
ChatPharoMCPTest >> testMCPRegistryEnabledServers [

	| s1 s2 |
	s1 := ChatPharoMCPServer new name: 'Server1'; enabled: false; yourself.
	s2 := ChatPharoMCPServer new name: 'Server2'; enabled: false; yourself.

	registry addServer: s1.
	registry addServer: s2.

	"Both are disabled (enabled: false was set before adding)"
	self assert: registry enabledServers isEmpty
]

{ #category : 'running' }
ChatPharoMCPTest >> testMCPRegistryFindServer [

	| testServer |
	testServer := ChatPharoMCPServer new
		              name: 'Findable Server';
		              enabled: false;
		              yourself.

	registry addServer: testServer.

	self
		assert: (registry findServerNamed: 'Findable Server')
		equals: testServer.
	self assert: (registry findServerNamed: 'Nonexistent') isNil
]

{ #category : 'running' }
ChatPharoMCPTest >> testMCPRegistryRemoveServer [

	| testServer |
	testServer := ChatPharoMCPServer new
		              name: 'Test Server';
		              enabled: false;
		              yourself.

	registry addServer: testServer.
	self assert: registry servers size equals: 1.

	registry removeServer: testServer.
	self assert: registry servers isEmpty
]

{ #category : 'running' }
ChatPharoMCPTest >> testMCPRegistryServersSette [

	| servers |
	servers := OrderedCollection
		with: (ChatPharoMCPServer new name: 'S1'; enabled: false; yourself).
	registry servers: servers.

	self assert: registry servers size equals: 1
]

{ #category : 'running' }
ChatPharoMCPTest >> testMCPResourceCreation [

	| resource |
	resource := McpResource new
		            uri: 'file:///test.txt';
		            name: 'Test File';
		            description: 'A test file';
		            mimeType: 'text/plain';
		            yourself.

	self assert: resource uri equals: 'file:///test.txt'.
	self assert: resource name equals: 'Test File'.
	self assert: resource description equals: 'A test file'.
	self assert: resource mimeType equals: 'text/plain'
]

{ #category : 'running' }
ChatPharoMCPTest >> testMCPResourceDefaults [

	| resource |
	resource := McpResource new.
	self assert: resource uri isNil.
	self assert: resource name isNil.
	self assert: resource description isNil.
	self assert: resource mimeType isNil.
]

{ #category : 'running' }
ChatPharoMCPTest >> testMCPServerCommandDefaults [

	self assert: server command equals: ''.
	self assert: server arguments isEmpty
]

{ #category : 'running' }
ChatPharoMCPTest >> testMCPServerConfiguration [

	server
		name: 'Test Server';
		command: 'node';
		arguments: #( 'server.js' );
		enabled: true.

	self assert: server name equals: 'Test Server'.
	self assert: server command equals: 'node'.
	self assert: server arguments equals: #( 'server.js' ) asOrderedCollection.
	self assert: server enabled
]

{ #category : 'running' }
ChatPharoMCPTest >> testMCPServerCreation [

	self assert: server name equals: 'Unnamed Server'.
	self assert: server enabled.
	self assert: server isDisconnected.
	self assert: server tools isEmpty.
	self assert: server resources isEmpty.
	self assert: server prompts isEmpty
]

{ #category : 'running' }
ChatPharoMCPTest >> testMCPServerDisconnectWhenNotConnected [

    self assert: server isDisconnected.
    server disconnect.
    self assert: server isDisconnected
]

{ #category : 'running' }
ChatPharoMCPTest >> testMCPServerEnvironmentVariables [

	server environment
		at: 'API_KEY' put: 'test-key';
		at: 'PORT' put: '3000'.

	self assert: (server environment at: 'API_KEY') equals: 'test-key'.
	self assert: (server environment at: 'PORT') equals: '3000'
]

{ #category : 'running' }
ChatPharoMCPTest >> testMCPSettingsEnabled [

	self deny: settings mcpEnabled.

	settings mcpEnabled: true.
	self assert: settings mcpEnabled
]

{ #category : 'running' }
ChatPharoMCPTest >> testMCPSettingsRegistry [

	self assert: settings mcpRegistry notNil.
	self assert: settings mcpRegistry class equals: ChatPharoMCPRegistry
]

{ #category : 'running' }
ChatPharoMCPTest >> testMCPSettingsToolsAsClients [

	| clients |
	settings mcpEnabled: false.
	clients := settings mcpToolsAsClients.
	self assert: clients isEmpty.

	settings mcpEnabled: true.
	clients := settings mcpToolsAsClients.
	self assert: clients isEmpty "Empty because no servers are configured"
]

{ #category : 'running' }
ChatPharoMCPTest >> testMCPToolCreation [

	| tool |
	tool := McpTool new
		        name: 'test_tool';
		        description: 'A test tool';
		        inputSchema: (Dictionary new
				         at: 'type' put: 'object';
				         yourself);
		        yourself.

	self assert: tool name equals: 'test_tool'.
	self assert: tool description equals: 'A test tool'.
	self assert: (tool inputSchema at: 'type') equals: 'object'
]

{ #category : 'running' }
ChatPharoMCPTest >> testMCPToolDefaults [

	| tool |
	tool := McpTool new.
	self assert: tool name isNil.
	self assert: tool description isNil.
	self assert: tool inputSchema isNil.
]

{ #category : 'running' }
ChatPharoMCPTest >> testMCPToolsFlowToAgents [
	"Regression test for the Codex/MCP connection bug: when MCP is enabled and a
	server (e.g. `codex mcp`) is connected with discovered tools, every agent's
	tools list MUST include the MCP tools alongside built-in and custom tools.
	Before the fix, agents only exposed customToolsAsClients and silently dropped
	MCP tools, making the registry useless from the agent's perspective."

	| previousDefault testSettings fakeServer fakeTool agentClasses |
	previousDefault := ChatPharoSettings default.
	[
		testSettings := ChatPharoSettings new.
		ChatPharoSettings setDefault: testSettings. "Build a fake MCP server that reports as connected with one tool — no
		subprocess is started so the test stays hermetic."
		fakeTool := McpTool
			            name: 'codex_exec'
			            description: 'Run a Codex prompt'
			            handler: [ :args | McpToolResult text: '' ].
		fakeServer := ChatPharoMCPServer new
			              name: 'Codex CLI';
			              command: 'codex';
			              arguments: #( 'mcp' );
			              enabled: false;
			              yourself.

		fakeServer tools add: fakeTool.
		fakeServer mcpServer: McpServer new.
		testSettings mcpRegistry addServer: fakeServer. "Use the private setter to avoid the disk write that mcpEnabled: triggers."
		testSettings privateSetMcpEnabled: true. "Sanity check: settings exposes the MCP tool as a client."
		self assert: testSettings mcpToolsAsClients size equals: 1.
		self assert: testSettings mcpToolsAsClients first name equals: 'codex_exec'. "Every agent class must surface MCP tools through its tools method."
		agentClasses := {
			                ChatPharoOpenAIAgent.
			                ChatPharoClaudeAgent.
			                ChatPharoMistralAgent.
			                ChatPharoGeminiAgent.
			                ChatPharoOllamaAgent.
			                ChatPharoDeepSeekAgent.
			                ChatPharoLMStudioAgent }.
		agentClasses do: [ :cls |
				| agent |
				agent := cls new.
				self
					assert: (agent tools anySatisfy: [ :t | t name = 'codex_exec' ])
					description: cls name , ' must expose MCP tools to the LLM' ] ] ensure: [ ChatPharoSettings setDefault: previousDefault ]
]
