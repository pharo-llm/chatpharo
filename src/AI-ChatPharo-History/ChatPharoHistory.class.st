"
Ordered collection of ChatPharoHistoryMessage objects; can dump itself as a plain “role: content” string (asPromptPrefix) or the full JSON structure OpenAI expects (chatMessagesOn:).
"
Class {
	#name : 'ChatPharoHistory',
	#superclass : 'Object',
	#instVars : [
		'messages',
		'cachedPromptPrefix'
	],
	#category : 'AI-ChatPharo-History',
	#package : 'AI-ChatPharo-History'
}

{ #category : 'initialization' }
ChatPharoHistory >> addAssistant: text [

    self addMessage: (ChatPharoHistoryMessage role:'assistant' content: text)
]

{ #category : 'initialization' }
ChatPharoHistory >> addMessage: aHistoryMessage [

	messages add: aHistoryMessage.
	cachedPromptPrefix := nil
]

{ #category : 'initialization' }
ChatPharoHistory >> addUser: text [ 

    self addMessage: (ChatPharoHistoryMessage role:'user' content: text)
]

{ #category : 'initialization' }
ChatPharoHistory >> asPromptPrefix [

	  ^ cachedPromptPrefix ifNil: [
        cachedPromptPrefix := String streamContents: [ :s |
            messages do: [ :m | m historyStringOn: s ] ] ]
]

{ #category : 'initialization' }
ChatPharoHistory >> chatMessagesOn: aStream [ 

    messages do:[ :m | m putOpenAIChatMessagesOn: aStream ]
]

{ #category : 'initialization' }
ChatPharoHistory >> clear [

	messages removeAll.
	cachedPromptPrefix := nil
]

{ #category : 'testing' }
ChatPharoHistory >> endsWithRole: aRole content: aString [

	^ messages notEmpty and: [ messages last role = aRole and: [ messages last content = aString ] ]
]

{ #category : 'adding' }
ChatPharoHistory >> ensureEndsWithAssistant: aString [
	"The agent that ran the turn usually recorded its own answer already; do not record it twice."

	(self endsWithRole: 'assistant' content: aString) ifFalse: [ self addAssistant: aString ]
]

{ #category : 'adding' }
ChatPharoHistory >> ensureEndsWithUser: aString [
	"A chat records the prompt before asking its agent; an agent used on its own records it here."

	(self endsWithRole: 'user' content: aString) ifFalse: [ self addUser: aString ]
]

{ #category : 'initialization' }
ChatPharoHistory >> initialize [

    super initialize.
    messages := OrderedCollection new
]

{ #category : 'testing' }
ChatPharoHistory >> isEmpty [

	^ messages isEmpty
]

{ #category : 'initialization' }
ChatPharoHistory >> messages [
 ^ messages 

]

{ #category : 'initialization' }
ChatPharoHistory >> putOpenAIChatMessagesOn: aStream [
    "Adaptor so that history works with ChatPharoTool,
    which expects this selector."
    
    ^ self chatMessagesOn: aStream
]

{ #category : 'accessing' }
ChatPharoHistory >> size [

	^ messages size
]

{ #category : 'removing' }
ChatPharoHistory >> truncateTo: aSize [
	"Forget everything recorded after the first aSize messages, e.g. to undo a failed turn."

	messages size > aSize ifFalse: [ ^ self ].
	messages removeLast: messages size - aSize.
	cachedPromptPrefix := nil
]
