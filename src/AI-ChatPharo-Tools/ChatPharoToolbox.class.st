"
I answer the tools ChatPharo offers for one request.

There is exactly one answer to ""which tools are available right now?"", and I
own it, so the chat agents, the MCP bridge used by terminal agents (Claude Code,
Codex, Gemini CLI) and the settings UI can never disagree:

- `builtInTools` — every tool shipped with ChatPharo, including those contributed
  by `ChatPharoToolProvider` subclasses;
- `enabledTools` — the built-in tools the user left enabled, plus the enabled
  custom tools and the tools of connected MCP servers.

```smalltalk
ChatPharoToolbox new enabledTools collect: [ :each | each name ]
```
"
Class {
	#name : 'ChatPharoToolbox',
	#superclass : 'Object',
	#instVars : [
		'settings'
	],
	#category : 'AI-ChatPharo-Tools-Core',
	#package : 'AI-ChatPharo-Tools',
	#tag : 'Core'
}

{ #category : 'instance creation' }
ChatPharoToolbox class >> settings: aSettings [

	^ self new
		  settings: aSettings;
		  yourself
]

{ #category : 'accessing' }
ChatPharoToolbox >> builtInTools [

	^ ChatPharoBrowserEnvironment new tools
]

{ #category : 'accessing' }
ChatPharoToolbox >> enabledBuiltInTools [
	"Tools shipped by an upgrade are enabled on first sight; tools the user disabled stay disabled."

	| builtIn enabledNames |
	builtIn := self builtInTools.
	self settings acknowledgeBuiltInToolNames: (builtIn collect: [ :each | each name ]).
	enabledNames := self settings browserToolsEnabled.
	^ builtIn select: [ :each | enabledNames includes: each name ]
]

{ #category : 'accessing' }
ChatPharoToolbox >> enabledToolNamed: aName [

	^ self enabledTools detect: [ :each | each name = aName ] ifNone: [ nil ]
]

{ #category : 'accessing' }
ChatPharoToolbox >> enabledTools [

	^ self enabledBuiltInTools , self settings customToolsAsClients , self settings mcpToolsAsClients
]

{ #category : 'accessing' }
ChatPharoToolbox >> settings [

	^ settings ifNil: [ settings := ChatPharoSettings default ]
]

{ #category : 'accessing' }
ChatPharoToolbox >> settings: aSettings [

	settings := aSettings
]
