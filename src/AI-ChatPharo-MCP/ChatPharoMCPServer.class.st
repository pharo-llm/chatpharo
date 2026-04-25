"
Represents an MCP (Model Context Protocol) server configuration.
An MCP server provides tools, resources, and prompts that can be used by LLMs.
This class manages the configuration and connection to an MCP server.
Example:
```smalltalk
server := ChatPharoMCPServer new
    name: 'File System';
    command: 'npx';
    arguments: #('-y' '@modelcontextprotocol/server-filesystem' '/path/to/directory');
    enabled: true;
    yourself.
"
Class {
	#name : 'ChatPharoMCPServer',
	#superclass : 'Object',
	#instVars : [
		'name',
		'command',
		'arguments',
		'environment',
		'enabled',
		'tools',
		'resources',
		'prompts',
		'mcpServer'
	],
	#category : 'AI-ChatPharo-MCP',
	#package : 'AI-ChatPharo-MCP'
}

{ #category : 'accessing' }
ChatPharoMCPServer >> arguments [

	^ arguments ifNil: [ arguments := OrderedCollection new ]
]

{ #category : 'accessing' }
ChatPharoMCPServer >> arguments: aCollection [

	arguments := aCollection asOrderedCollection
]

{ #category : 'accessing' }
ChatPharoMCPServer >> command [

	^ command ifNil: [ command := '' ]
]

{ #category : 'accessing' }
ChatPharoMCPServer >> command: aString [

	command := aString
]

{ #category : 'circuit setup' }
ChatPharoMCPServer >> connect [

	| transport |
	mcpServer ifNotNil: [ ^ self ].
	[
		transport := McpStdioTransport new.
		mcpServer := McpServer name: self name version: '1.0.0'.
		mcpServer transport: transport.
		tools := mcpServer tools.
		resources := mcpServer resources.
		prompts := mcpServer prompts.
		ChatPharoLogger logSystem: 'MCP server connected' details: (Dictionary new
				 at: 'server' put: self name;
				 at: 'toolsCount' put: self tools size;
				 yourself) ]
		on: Error
		do: [ :error |
				mcpServer := nil.
				ChatPharoLogger logSystem: 'MCP server connection failed' details: (Dictionary new
						 at: 'server' put: self name;
						 at: 'error' put: error messageText;
						 yourself) ]
]

{ #category : 'connection open/close' }
ChatPharoMCPServer >> disconnect [

	mcpServer ifNil: [ ^ self ].
	[
		mcpServer := nil.
		tools := OrderedCollection new.
		resources := OrderedCollection new.
		ChatPharoLogger logSystem: 'MCP server disconnected' details: (Dictionary new
				 at: 'server' put: self name;
				 yourself) ]
		on: Error
		do: [ :error |
				ChatPharoLogger logSystem: 'MCP server disconnect error' details: (Dictionary new
						 at: 'server' put: self name;
						 at: 'error' put: error messageText;
						 yourself) ]
]

{ #category : 'accessing' }
ChatPharoMCPServer >> enabled [

	^ enabled ifNil: [ enabled := true ]
]

{ #category : 'accessing' }
ChatPharoMCPServer >> enabled: aBoolean [

	| wasEnabled |
	wasEnabled := self enabled.
	enabled := aBoolean.

	"Connect or disconnect based on enabled state"
	(wasEnabled not and: [ aBoolean ]) ifTrue: [ self connect ].
	(wasEnabled and: [ aBoolean not ]) ifTrue: [ self disconnect ]
]

{ #category : 'accessing' }
ChatPharoMCPServer >> environment [

	^ environment ifNil: [ environment := Dictionary new ]
]

{ #category : 'accessing' }
ChatPharoMCPServer >> environment: aDictionary [

	environment := aDictionary
]

{ #category : 'private' }
ChatPharoMCPServer >> initialize [

	super initialize.
	enabled := true.
	tools := OrderedCollection new.
	resources := OrderedCollection new.
	prompts := OrderedCollection new.
	arguments := OrderedCollection new.
	environment := Dictionary new
]

{ #category : 'private' }
ChatPharoMCPServer >> isConnected [

	^ mcpServer isNotNil
]

{ #category : 'private' }
ChatPharoMCPServer >> isDisconnected [

	^ mcpServer isNil
]

{ #category : 'accessing' }
ChatPharoMCPServer >> mcpServer: anObject [

	mcpServer := anObject
]

{ #category : 'private' }
ChatPharoMCPServer >> name [

	^ name ifNil: [ name := 'Unnamed Server' ]
]

{ #category : 'private' }
ChatPharoMCPServer >> name: aString [

	name := aString
]

{ #category : 'private' }
ChatPharoMCPServer >> prompts [

	^ prompts ifNil: [ prompts := OrderedCollection new ]
]

{ #category : 'private' }
ChatPharoMCPServer >> resources [

	^ resources ifNil: [ resources := OrderedCollection new ]
]

{ #category : 'private' }
ChatPharoMCPServer >> tools [

	^ tools ifNil: [ tools := OrderedCollection new ]
]

{ #category : 'tool execution' }
ChatPharoMCPServer >> toolsAsChatPharoClients [

	^ self tools collect: [ :tool |
			  ChatPharoClient new
				  initializeWithName: tool name
				  description: tool description
				  parameters: tool inputSchema
				  block: [ :args | tool executeWith: args ];
				  yourself ]
]
