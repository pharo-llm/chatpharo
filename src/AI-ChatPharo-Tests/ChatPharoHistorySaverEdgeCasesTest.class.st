Class {
	#name : 'ChatPharoHistorySaverEdgeCasesTest',
	#superclass : 'TestCase',
	#instVars : [
		'chat'
	],
	#category : 'AI-ChatPharo-Tests-History',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'History'
}

{ #category : 'tests' }
ChatPharoHistorySaverEdgeCasesTest >> testAssistantNilContentGetsPlaceholder [ 
	| saver msgs |
	saver := ChatPharoHistorySaver role: 'assistant' content: nil.
	msgs := Array streamContents: [ :s | saver putOpenAIChatMessagesOn: s ].
	self assert: (msgs first at: 'content') equals: '[No assistant response]'.  ":contentReference[oaicite:4]{index=4}"

]

{ #category : 'tests' }
ChatPharoHistorySaverEdgeCasesTest >> testToolMessageNilContentGetsPlaceholder [ 
	| tc toolMsg |
	tc := ChatPharoHistorySaverToolCall
		id: 'tool_1'
		functionName: 'fn'
		arguments: '{}'
		content: nil.
	toolMsg := tc openAIChatToolMessage.
	self assert: (toolMsg at: 'content') equals: '[No tool result]'.  ":contentReference[oaicite:5]{index=5}"

]

{ #category : 'tests' }
ChatPharoHistorySaverEdgeCasesTest >> testTrailingUserMessageNotDroppedOnImport [

	| json |
	chat := ChatPharoChat new.
	json := '[{"role":"user","content":"hello"},{"role":"assistant","content":"hi"},{"role":"user","content":"trailing message"}]'.
	chat importFromJson: json.
	self assert: chat messages size equals: 2.
	self assert: chat messages last content equals: 'trailing message'.
	self assert: chat messages last answer isEmpty
]
