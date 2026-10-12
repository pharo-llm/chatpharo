"
I assemble the context a chat feeds its model before the conversation starts.

I hold the ordered `ChatPharoContextLayer`s and answer one text block,
`promptFor:`, that the chat appends to the system prompt of every request. The
context is rebuilt for each request, so the model always sees the current
branch, the current window and the latest changes — not a snapshot taken when
the chat was opened.

```smalltalk
ChatPharoContext default promptFor: 'why does my test fail?'
```
"
Class {
	#name : 'ChatPharoContext',
	#superclass : 'Object',
	#instVars : [
		'layers'
	],
	#category : 'AI-ChatPharo-Context',
	#package : 'AI-ChatPharo-Context'
}

{ #category : 'instance creation' }
ChatPharoContext class >> default [

	^ self settings: ChatPharoSettings default
]

{ #category : 'instance creation' }
ChatPharoContext class >> layers: aCollection [

	^ self new
		  layers: aCollection;
		  yourself
]

{ #category : 'instance creation' }
ChatPharoContext class >> settings: aSettings [

	^ self layers: {
			  (ChatPharoEnvironmentLayer settings: aSettings).
			  (ChatPharoWorkflowLayer settings: aSettings).
			  (ChatPharoProjectLayer settings: aSettings).
			  (ChatPharoSessionLayer settings: aSettings).
			  (ChatPharoMemoryLayer settings: aSettings) }
]

{ #category : 'accessing' }
ChatPharoContext >> layers [

	^ layers
]

{ #category : 'accessing' }
ChatPharoContext >> layers: aCollection [

	layers := aCollection
]

{ #category : 'accessing' }
ChatPharoContext >> promptFor: aQueryString [
	"Answer the context sections relevant to aQueryString, or an empty string when every layer is silent."

	^ (String cr , String cr) join:
		  (layers collect: [ :each | each textFor: aQueryString ] thenReject: [ :each | each isEmpty ])
]
