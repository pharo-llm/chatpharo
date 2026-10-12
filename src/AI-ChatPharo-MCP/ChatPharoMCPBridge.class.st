"
I expose ChatPharo's tools to **terminal agents** — Claude Code, Codex CLI,
Gemini CLI, or any MCP client — so they can read and change the live image from
the user's terminal.

I am an MCP server over the *Streamable HTTP* transport: clients POST JSON-RPC
messages to `http://localhost:<port>/mcp` and read the JSON reply. The MCP
protocol itself (initialize, tools/list, tools/call…) is handled by `McpServer`
from the pharo-mcp library; I only add the HTTP transport and the tools.

What a client sees is exactly `ChatPharoToolbox new enabledTools`: the tools the
user enabled in Settings, including custom tools and the tools contributed by
`ChatPharoToolProvider` subclasses. It is computed for each request, so toggling
a tool takes effect without restarting me.

Safety:

- I listen on the loopback interface only, never on the network.
- Requests carrying an `Origin` that is not local are refused, so a web page
  cannot drive the image through the browser.
- Mutating tools go through `ChatPharoToolConfirmation` like in a chat: the
  user confirms in the image, and a refusal with its reason is answered to
  the agent.

```smalltalk
ChatPharoMCPBridge default start.
ChatPharoMCPBridge default connectionInstructions.
ChatPharoMCPBridge default stop
```
"
Class {
	#name : 'ChatPharoMCPBridge',
	#superclass : 'Object',
	#instVars : [
		'port',
		'httpServer',
		'toolbox'
	],
	#classInstVars : [
		'default'
	],
	#category : 'AI-ChatPharo-MCP',
	#package : 'AI-ChatPharo-MCP'
}

{ #category : 'accessing' }
ChatPharoMCPBridge class >> default [

	^ default ifNil: [ default := self new ]
]

{ #category : 'accessing' }
ChatPharoMCPBridge class >> defaultPort [

	^ 8765
]

{ #category : 'accessing' }
ChatPharoMCPBridge class >> reset [

	<script>
	default ifNotNil: [ :bridge | bridge stop ].
	default := nil
]

{ #category : 'private - http' }
ChatPharoMCPBridge >> answerJsonRpc: aJsonString [

	| payload replies |
	payload := [ STONJSON fromString: aJsonString ]
		           on: STONReaderError
		           do: [ :error | ^ self jsonResponse: (self parseErrorReply: error messageText) ].
	payload isArray ifFalse: [ ^ self httpResponseForReply: (self replyTo: payload) ].
	replies := (payload collect: [ :each | self replyTo: each ]) reject: [ :each | each isNil ].
	^ replies
		  ifEmpty: [ ZnResponse accepted ]
		  ifNotEmpty: [ self jsonResponse: replies ]
]

{ #category : 'accessing' }
ChatPharoMCPBridge >> connectionInstructions [
	"The commands that register me in the usual terminal agents."

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: 'Claude Code:  claude mcp add --transport http chatpharo ';
			  nextPutAll: self url;
			  cr;
			  nextPutAll: 'Codex CLI:    codex mcp add chatpharo --url ';
			  nextPutAll: self url;
			  cr;
			  nextPutAll: 'Gemini CLI:   gemini mcp add --transport http chatpharo ';
			  nextPutAll: self url;
			  cr;
			  nextPutAll: 'Any client:   Streamable HTTP MCP server at ';
			  nextPutAll: self url ]
]

{ #category : 'private - http' }
ChatPharoMCPBridge >> handleRequest: aRequest [
	"ZnServer delegate entry point."

	(self isLocalOrigin: aRequest) ifFalse: [ ^ ZnResponse statusLine: ZnStatusLine forbidden ].
	aRequest uri firstPathSegment = 'mcp' ifFalse: [ ^ ZnResponse notFound: aRequest uri ].
	aRequest method = #POST ifFalse: [ ^ ZnResponse methodNotAllowed: aRequest ].
	^ self answerJsonRpc: aRequest contents
]

{ #category : 'private - http' }
ChatPharoMCPBridge >> httpResponseForReply: aReply [
	"A notification has no reply: MCP answers it 202 Accepted."

	^ aReply
		  ifNil: [ ZnResponse accepted ]
		  ifNotNil: [ self jsonResponse: aReply ]
]

{ #category : 'private - http' }
ChatPharoMCPBridge >> isLocalOrigin: aRequest [
	"Command line clients send no Origin. A browser does, and only a local page is accepted."

	| origin |
	origin := aRequest headers at: 'Origin' ifAbsent: [ ^ true ].
	^ #( 'http://localhost' 'http://127.0.0.1' 'http://[::1]' ) anySatisfy: [ :each | origin beginsWith: each ]
]

{ #category : 'testing' }
ChatPharoMCPBridge >> isRunning [

	^ httpServer notNil and: [ httpServer isRunning ]
]

{ #category : 'private - http' }
ChatPharoMCPBridge >> jsonResponse: anObject [

	^ ZnResponse ok: (ZnEntity json: (STONJSON toString: anObject))
]

{ #category : 'private - mcp' }
ChatPharoMCPBridge >> mcpToolFor: aTool calledThrough: aDispatcher [

	^ McpTool
		  name: aTool name
		  description: aTool description
		  inputSchema: aTool parameters
		  handler: [ :arguments | self resultOfCalling: aTool name with: arguments through: aDispatcher ]
]

{ #category : 'private - mcp' }
ChatPharoMCPBridge >> newMcpServer [
	"A server holding the tools enabled right now. Building one per request keeps me stateless."

	| server tools dispatcher |
	server := McpServer name: 'chatpharo' version: ChatPharoSettings default chatPharoVersion.
	tools := self toolbox enabledTools.
	dispatcher := ChatPharoTool baseURL: nil system: nil tools: tools.
	tools do: [ :each | server addTool: (self mcpToolFor: each calledThrough: dispatcher) ].
	^ server
]

{ #category : 'private - http' }
ChatPharoMCPBridge >> parseErrorReply: aString [

	^ (McpJsonRpcResponse id: nil error: (McpJsonRpcError code: MCPConstants errorCodeParseError message: aString))
		  asDictionary
]

{ #category : 'accessing' }
ChatPharoMCPBridge >> port [

	^ port ifNil: [ port := self class defaultPort ]
]

{ #category : 'accessing' }
ChatPharoMCPBridge >> port: anInteger [

	port := anInteger
]

{ #category : 'private - mcp' }
ChatPharoMCPBridge >> replyTo: aDictionary [
	"Answer the JSON-RPC reply to one message, or nil when it expects none.
	 In JSON-RPC a request has an id and a method; a notification has no id."

	| message |
	(aDictionary includesKey: 'method') ifFalse: [ ^ nil ].
	message := MCPJSONRPCMessage fromDictionary: aDictionary.
	(aDictionary includesKey: 'id') ifFalse: [
		self newMcpServer handleNotification: message.
		^ nil ].
	^ (self newMcpServer dispatchRequest: message) asDictionary
]

{ #category : 'private - mcp' }
ChatPharoMCPBridge >> resultOfCalling: aToolName with: arguments through: aDispatcher [

	| result text |
	result := aDispatcher applyToolFunction: aToolName arguments: arguments.
	text := aDispatcher jsonStringFor: (aDispatcher normalizeForJson: result).
	^ ((result isDictionary and: [ result includesKey: 'error' ])
		   ifTrue: [ McpToolResult errorText: text ]
		   ifFalse: [ McpToolResult successText: text ])
]

{ #category : 'running' }
ChatPharoMCPBridge >> start [
	"Start listening. Answer myself; does nothing when already running."

	self isRunning ifTrue: [ ^ self ].
	httpServer := (ZnServer on: self port)
		              bindingAddress: NetNameResolver loopBackAddress;
		              delegate: self;
		              yourself.
	httpServer start.
	ChatPharoLogger logSystem: 'MCP bridge started' details: (Dictionary with: 'url' -> self url)
]

{ #category : 'running' }
ChatPharoMCPBridge >> stop [

	httpServer ifNil: [ ^ self ].
	httpServer stop.
	httpServer := nil.
	ChatPharoLogger logSystem: 'MCP bridge stopped' details: Dictionary new
]

{ #category : 'accessing' }
ChatPharoMCPBridge >> toolbox [

	^ toolbox ifNil: [ toolbox := ChatPharoToolbox new ]
]

{ #category : 'accessing' }
ChatPharoMCPBridge >> toolbox: aToolbox [

	toolbox := aToolbox
]

{ #category : 'accessing' }
ChatPharoMCPBridge >> url [

	^ 'http://localhost:' , self port printString , '/mcp'
]
