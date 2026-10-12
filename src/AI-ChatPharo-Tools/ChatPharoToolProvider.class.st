"
I am the extension point for adding tools to ChatPharo.

Subclass me, implement `tools` to answer `ChatPharoClient` instances, and the
tools show up everywhere: in chats, in Settings > Tools, and for terminal agents
connected through the MCP bridge. Nothing else has to be registered.

Each provider is one coherent group (code navigation, UI driving, planning…).
`title` and `summary` describe the group in the settings UI.

Finding my subclasses is deliberate, isolated reflection: it is the plug-in
boundary, in the same spirit as SUnit finding `TestCase` subclasses.

```smalltalk
ChatPharoToolProvider allTools collect: [ :each | each name ]
```
"
Class {
	#name : 'ChatPharoToolProvider',
	#superclass : 'Object',
	#category : 'AI-ChatPharo-Tools-Core',
	#package : 'AI-ChatPharo-Tools',
	#tag : 'Core'
}

{ #category : 'accessing' }
ChatPharoToolProvider class >> allProviders [

	^ (self allSubclasses reject: [ :each | each isAbstract ]) collect: [ :each | each new ]
]

{ #category : 'accessing' }
ChatPharoToolProvider class >> allTools [

	^ (self allProviders sorted: [ :a :b | a title <= b title ]) flatCollect: [ :each | each tools ]
]

{ #category : 'testing' }
ChatPharoToolProvider class >> isAbstract [

	^ self = ChatPharoToolProvider
]

{ #category : 'private' }
ChatPharoToolProvider >> objectSchemaWithProperties: properties required: requiredNames [

	^ Dictionary
		  with: 'type' -> 'object'
		  with: 'properties' -> properties
		  with: 'required' -> requiredNames
]

{ #category : 'private' }
ChatPharoToolProvider >> property: aType description: aString [

	^ Dictionary with: 'type' -> aType with: 'description' -> aString
]

{ #category : 'accessing' }
ChatPharoToolProvider >> summary [
	"One sentence shown in the settings UI."

	^ ''
]

{ #category : 'accessing' }
ChatPharoToolProvider >> title [
	"Short group name shown in the settings UI."

	^ self subclassResponsibility
]

{ #category : 'private' }
ChatPharoToolProvider >> toolNamed: aName description: aDescription properties: properties required: requiredNames do: aBlock [

	^ ChatPharoClient
		  name: aName
		  description: aDescription
		  parameters: (self objectSchemaWithProperties: properties required: requiredNames)
		  block: aBlock
]

{ #category : 'accessing' }
ChatPharoToolProvider >> tools [

	^ self subclassResponsibility
]
