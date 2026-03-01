"
One **conversation transcript**.

* Keeps an ordered list of UI `ChatPharoMessage` objects **and** a non-UI `ChatPharoHistory` that mirrors the same information in LLM-friendly format.
* Drives asynchronous prompting: forks a light process that asks the agent and posts the assistant reply back into both collections.
* Can clear its own history, cancel an in-flight request, and notify listeners when a reply arrives.
* **Why** – encapsulates everything that makes a single chat tick, so multiple chats can live side-by-side in a notebook UI.


```smalltalk
(ChatPharoChat new
	ollamaApi: (OllamaApi new
		model: 'codellama:7b';
		yourself);
	yourself) presenter open.
	
```
"
Class {
	#name : 'ChatPharoChat',
	#superclass : 'Object',
	#instVars : [
		'messages',
		'agent',
		'promptProcess',
		'onAnswerReceived',
		'onChatReset',
		'history',
		'onToolExecution',
		'cache',
		'onErrorReceived',
		'onNewChatRequested'
	],
	#category : 'AI-ChatPharo',
	#package : 'AI-ChatPharo'
}

{ #category : 'running' }
ChatPharoChat >> addAnswerReceivedHandler: aBlock [

	| existing |
	aBlock ifNil: [ ^ self ].
	existing := onAnswerReceived.
	onAnswerReceived := [ :message |
		existing ifNotNil: [ :blk | blk value: message ].
		aBlock value: message ]
]

{ #category : 'running' }
ChatPharoChat >> addAssistantMessage: anAnswer [

	| label multivers thinking answerText |
	"Note: history is already updated by the agent's getResponseForPrompt: method
	Determine label based on mode"
	thinking := nil.
	answerText := anAnswer. "Handle both string and result object"
	(answerText respondsTo: #content) ifTrue: [
			thinking := answerText thinking.
			answerText := answerText content ].

(thinking isNil and: [ self agent respondsTo: #response ]) ifTrue: [
		| agentResponse |
		agentResponse := self agent response.
		(agentResponse respondsTo: #thinking) ifTrue: [
			thinking := agentResponse thinking ] ].


	multivers := ChatPharoSettings default multivers.
	label := (multivers notNil and: [ multivers canExecute ])
		         ifTrue: [ 'Multivers (' , multivers stepsCount asString , ' agents)' ]
		         ifFalse: [
				         (self agent isKindOf: ChatPharoNullAgent)
					         ifTrue: [ 'Assistant bot' ]
					         ifFalse: [ 'Assistant' ] ].

	messages last
		answer: answerText;
		assistantLabel: label;
		thinking: (thinking ifNil: [ '' ]).

	ChatPharoLogger logBackend: 'Assistant response recorded' details: (Dictionary new
			 at: 'chatId' put: self identityHash;
			 at: 'agent' put: (ChatPharoLogger agentNameFor: self agent);
			 at: 'assistantLabel' put: label;
			 at: 'response' put: answerText;
			 yourself)
]

{ #category : 'running' }
ChatPharoChat >> addUserMessage: text [

	| message content attachments |
	(text isKindOf: ChatPharoMessage) ifTrue: [
			message := text.
			content := message content.
			attachments := message attachments.
			self recordUserNameIfPresentIn: content.
			attachments ifNotNil: [ message attachments: attachments ].
			messages add: message.
			^ self ].

	self recordUserNameIfPresentIn: text.
	messages add: (ChatPharoMessage new
			 content: text;
			 yourself).
]

{ #category : 'running' }
ChatPharoChat >> addUserMessage: text withAttachments: attachmentCollection [

	| message |
	history addUser: text.
	self recordUserNameIfPresentIn: text.
	message := ChatPharoMessage new
		           content: text;
		           attachments: attachmentCollection;
		           yourself.
	messages add: message.
]

{ #category : 'initialization' }
ChatPharoChat >> addWelcomeMessage [ 

        | text message |
        text := 'Welcome to ChatPharo! I can answer questions, help explore your Pharo image, run snippets and search your code. Type a message to get started.'.
        history addAssistant: text.
        message := ChatPharoMessage new
                        answer: text;
                        assistantLabel: 'ChatPharo';
                        yourself.
        messages add: message
]

{ #category : 'accessing' }
ChatPharoChat >> agent [
    ^ agent ifNotNil: [ agent history: history. agent ]
]

{ #category : 'accessing' }
ChatPharoChat >> agent: anObject [

	agent := anObject
]

{ #category : 'private' }
ChatPharoChat >> buildPromptPrefixWithMemoryFor: queryText [
	"Build the prompt prefix including memory context if enabled"

	| prefix memoryContext |
	prefix := history asPromptPrefix.

	"Add memory context if enabled"
	(ChatPharoSettings default memoryEnabled and: [
		 self class environment includesKey: #ChatPharoMemory ]) ifTrue: [
		memoryContext := (self class environment at: #ChatPharoMemory) default
			                 contextForQuery: queryText.
		memoryContext ifNotEmpty: [
			prefix := memoryContext , String cr , prefix ] ].

	^ prefix
]

{ #category : 'running' }
ChatPharoChat >> cancelMessage [

	promptProcess ifNotNil: [ :process | process terminate ]
]

{ #category : 'running' }
ChatPharoChat >> clearCache [

	cache removeAll
]

{ #category : 'running' }
ChatPharoChat >> clearChat [

	"Save conversation summary to memory before clearing"
	self summarizeConversationToMemory.
	self cancelMessage.
	history clear.
	messages removeAll.
	self clearCache
]

{ #category : 'accessing' }
ChatPharoChat >> exportAsJson [

	| entries normalized |
	entries := Array streamContents: [ :stream |
		history putOpenAIChatMessagesOn: stream ].
	normalized := entries collect: [ :entry |
		| dict |
		dict := entry copy.
		(dict includesKey: 'role') ifTrue: [
			(dict includesKey: 'content') ifFalse: [
				dict at: 'content' put: '' ] ].
		dict ].
	^ self jsonStringFor: normalized
]

{ #category : 'running' }
ChatPharoChat >> extractNameFrom: text startingAfter: startIndex [
	"Extract a reasonable name candidate from text starting at startIndex."

	| remainder candidate splitters |
	remainder := (text copyFrom: startIndex + 1 to: text size) trimBoth.
	[ remainder notEmpty and: [ '.,!?;' includes: remainder last ] ] whileTrue: [
		remainder := remainder allButLast ].
	remainder ifEmpty: [ ^ nil ].

	splitters := #(' and ' ' but ' ' so ' ' because ' ' that ').
	candidate := remainder.
	splitters do: [ :splitter |
		| index |
		index := candidate findString: splitter startingAt: 1.
		index > 0 ifTrue: [
			candidate := (candidate copyFrom: 1 to: index - 1) trimBoth ] ].

	candidate ifEmpty: [ ^ nil ].
	(candidate first isLetter) ifFalse: [ ^ nil ].
	(candidate allSatisfy: [ :char |
		char isLetter or: [ char = $  or: [ char = $- or: [ char = $' ] ] ] ])
		ifFalse: [ ^ nil ].

	^ candidate
]

{ #category : 'running' }
ChatPharoChat >> history [
    ^ history asPromptPrefix
]

{ #category : 'running' }
ChatPharoChat >> historyMessages [
    ^ history messages
]

{ #category : 'running' }
ChatPharoChat >> historyPromptPrefix [
    ^ history asPromptPrefix
]

{ #category : 'accessing' }
ChatPharoChat >> importFromJson: aJsonString [
	"Import a chat from a JSON string. The JSON should be an array of message objects
    with 'role' and 'content' keys, optionally with 'tool_calls' for assistant messages."

	| parsedMessages currentUserContent |
	self clearChat.
	parsedMessages := STONJSON fromString: aJsonString.
	currentUserContent := nil.

	parsedMessages do: [ :msgDict |
			| role content toolCalls historyMsg |
			role := msgDict at: 'role'.
			content := msgDict at: 'content' ifAbsent: [ '' ].
			toolCalls := msgDict at: 'tool_calls' ifAbsent: [ nil ]. "Create tool calls if present"
			toolCalls ifNotNil: [
					toolCalls := toolCalls collect: [ :tcDict |
							             | funcDict |
							             funcDict := tcDict at: 'function' ifAbsent: [ Dictionary new ].
							             ChatPharoHistorySaverToolCall
								             id: (tcDict at: 'id' ifAbsent: [ '' ])
								             functionName: (funcDict at: 'name' ifAbsent: [ '' ])
								             arguments: (funcDict at: 'arguments' ifAbsent: [ '' ])
								             content: nil ] ]. "Add to history"
			historyMsg := ChatPharoHistoryMessage role: role content: content toolCalls: toolCalls.
			history addMessage: historyMsg. "Build UI messages - pair user with assistant"
			role = 'user' ifTrue: [ currentUserContent := content ].
			role = 'assistant' ifTrue: [
					messages add: (ChatPharoMessage new
							 content: (currentUserContent ifNil: [ '' ]);
							 answer: (content ifNil: [ '' ]);
							 assistantLabel: 'Assistant';
							 yourself).
					currentUserContent := nil ] ].

	ChatPharoLogger logBackend: 'Chat imported from JSON' details: (Dictionary new
			 at: 'chatId' put: self identityHash;
			 at: 'messagesImported' put: parsedMessages size;
			 yourself).
		
	self notifyChatReset
]

{ #category : 'initialization' }
ChatPharoChat >> initialize [

	super initialize.
	history := ChatPharoHistory new.
	messages := OrderedCollection new.
	onToolExecution := nil.
	onChatReset := nil.
	cache := Dictionary new.
	ChatPharoSettings default welcomeMessageEnabled ifTrue: [ self addWelcomeMessage ]
]

{ #category : 'accessing' }
ChatPharoChat >> jsonStringFor: anObject [
	"Serialize JSON while ignoring shared reference warnings."

^ STONJSON toString: anObject
]

{ #category : 'accessing' }
ChatPharoChat >> messages [

	^ messages
]

{ #category : 'accessing' }
ChatPharoChat >> messages: anObject [

	messages := anObject
]

{ #category : 'initialization' }
ChatPharoChat >> notifyChatReset [ 

	onChatReset ifNotNil: [ :blk | blk value ]
]

{ #category : 'presenters' }
ChatPharoChat >> presenter [

	^ ChatPharoChatPresenter on: self
]

{ #category : 'memory' }
ChatPharoChat >> recordFeedback: feedbackText positive: isPositive [
	"Record user feedback as a memory item"

	(ChatPharoSettings default memoryEnabled and: [
		 self class environment includesKey: #ChatPharoMemory ]) ifFalse: [ ^ self ].

	(self class environment at: #ChatPharoMemory) default
		addFeedback: feedbackText
		positive: isPositive.
		
	"Submit feedback to backend if enabled"
	(self class environment includesKey: #ChatPharoFeedbackSubmitter) ifTrue: [
		(self class environment at: #ChatPharoFeedbackSubmitter) submitFeedback: (Dictionary new
				 at: 'type' put: (isPositive ifTrue: [ 'positive' ] ifFalse: [ 'negative' ]);
				 at: 'content' put: feedbackText;
				 at: 'chatId' put: self identityHash;
				 yourself) ].

	ChatPharoLogger logSystem: 'Feedback recorded to memory'
		details: (Dictionary new
				 at: 'positive' put: isPositive;
				 yourself)
]

{ #category : 'memory' }
ChatPharoChat >> recordUserCorrection: correctionText [
	"Record a user correction as a memory item"

	(ChatPharoSettings default memoryEnabled and: [
		 self class environment includesKey: #ChatPharoMemory ]) ifFalse: [ ^ self ].

	(self class environment at: #ChatPharoMemory) default
		addCorrection: correctionText.

	ChatPharoLogger logSystem: 'Correction recorded to memory'
		details: (Dictionary new
				 at: 'correction' put: (correctionText truncateTo: 50);
				 yourself)
]

{ #category : 'running' }
ChatPharoChat >> recordUserNameIfPresentIn: text [
	"Detect and record the user's name from common phrases (e.g., 'my name is Omar')."

	| lowerText prefixes name |
	text ifNil: [ ^ self ].
	(text respondsTo: #content) ifTrue: [ ^ self recordUserNameIfPresentIn: text content ].
	lowerText := text asString asLowercase.
	prefixes := #( 'my name is ' 'i am ' 'i''m ' 'im ' 'call me ' 'you can call me ' ).

	name := nil.
	prefixes do: [ :prefix |
			name ifNil: [
					| startIndex |
					startIndex := lowerText findString: prefix startingAt: 1.
					startIndex > 0 ifTrue: [ name := self extractNameFrom: text startingAfter: startIndex + prefix size - 1 ] ] ].

	name ifNil: [ ^ self ].
	self recordUserPreference: 'User''s name is ' , name
]

{ #category : 'memory' }
ChatPharoChat >> recordUserPreference: preferenceText [
	"Record a user preference as a memory item"

	(ChatPharoSettings default memoryEnabled and: [
		 self class environment includesKey: #ChatPharoMemory ]) ifFalse: [ ^ self ].

	(self class environment at: #ChatPharoMemory) default
		addUserPreference: preferenceText.

	ChatPharoLogger logSystem: 'User preference recorded to memory'
		details: (Dictionary new
				 at: 'preference' put: (preferenceText truncateTo: 50);
				 yourself)
]

{ #category : 'initialization' }
ChatPharoChat >> requestNewChat [ 

	onNewChatRequested
		ifNotNil: [ :blk | blk value ]
		ifNil: [ self resetConversation ]
]

{ #category : 'initialization' }
ChatPharoChat >> resetConversation [

"Save conversation summary to memory before resetting"
	self summarizeConversationToMemory.
	
	self cancelMessage.
	history clear.
	messages removeAll.
	self clearCache.
	(ChatPharoSettings default welcomeMessageEnabled)
		ifTrue: [ self addWelcomeMessage ].
	self notifyChatReset
]

{ #category : 'running' }
ChatPharoChat >> sendMessage: aText [

	| answer multivers promptWithMemory historyPrefix combinedPrefix |
	self addUserMessage: aText.

	(cache includesKey: aText) ifTrue: [
			answer := cache at: aText.
			self addAssistantMessage: answer.
			onAnswerReceived ifNotNil: [ :blk | blk value: messages last ].
			^ self ]. "Check if multivers mode is enabled and can execute"
	multivers := ChatPharoSettings default multivers.
	(multivers notNil and: [ multivers canExecute ]) ifTrue: [ ^ self sendMessageViaMultivers: aText ]. "Standard single-agent execution"
	promptProcess := [
		                 [
			                 | backend |
			                 backend := self agent.
			                backend onToolExecution: [ :toolName | self triggerToolExecution: toolName ].
			                 promptWithMemory := self buildPromptPrefixWithMemoryFor: aText.

			                 backend promptPrefix: promptWithMemory.
			                 answer := backend getResponseForPrompt: aText.
			                 cache at: aText put: answer.
			                 self addAssistantMessage: answer.
			                 onAnswerReceived ifNotNil: [ :blk | blk value: messages last ] ]
			                 on: Error
			                 do: [ :ex |
					                 ChatPharoLogger logBackend: 'Error during message send' details: (Dictionary new
							                  at: 'chatId' put: self identityHash;
							                  at: 'error' put: ex messageText;
							                  yourself).
					                 onErrorReceived ifNotNil: [ :blk | blk value: ex messageText ] ] ] fork
]

{ #category : 'running' }
ChatPharoChat >> sendMessage: aText withAttachments: attachmentCollection [

	| answer multivers promptWithMemory textWithAttachments |
	self addUserMessage: aText withAttachments: attachmentCollection. "Build the message text including attachment information"
	textWithAttachments := aText.
	attachmentCollection ifNotEmpty: [
			textWithAttachments := String streamContents: [ :stream |
					                       stream nextPutAll: aText.
					                       stream
						                       cr;
						                       cr.
					                       stream nextPutAll: 'Attached files:'.
					                       stream cr.
					                       attachmentCollection do: [ :fileRef |
							                       stream nextPutAll: '- '.
							                       stream nextPutAll: fileRef basename.
							                       stream nextPutAll: ' ('.
							                       stream nextPutAll: fileRef size asString.
							                       stream nextPutAll: ' bytes)'.
							                       stream cr. "Optionally include file content for text files"
							                       (fileRef mimeTypes anySatisfy: [ :mime | mime beginsWith: 'text/' ]) ifTrue: [
									                       stream nextPutAll: '  Content: '.
									                       stream cr.
									                       stream nextPutAll: fileRef contents.
									                       stream cr ] ] ] ].

	(cache includesKey: textWithAttachments) ifTrue: [
			answer := cache at: textWithAttachments.
			self addAssistantMessage: answer.
			onAnswerReceived ifNotNil: [ :blk | blk value: messages last ].
			^ self ]. "Check if multivers mode is enabled and can execute"
	multivers := ChatPharoSettings default multivers.
	(multivers notNil and: [ multivers canExecute ]) ifTrue: [ ^ self sendMessageViaMultivers: textWithAttachments ]. "Standard single-agent execution"
	promptProcess := [
		                 [
			                 | backend |
			                 backend := self agent.
			                backend onToolExecution: [ :toolName | self triggerToolExecution: toolName ].
			                 promptWithMemory := self buildPromptPrefixWithMemoryFor: textWithAttachments.

			                 backend promptPrefix: promptWithMemory.
			                 answer := backend getResponseForPrompt: textWithAttachments.
			                 cache at: textWithAttachments put: answer.
			                 self addAssistantMessage: answer.
			                 onAnswerReceived ifNotNil: [ :blk | blk value: messages last ] ]
			                 on: Error
			                 do: [ :ex |
					                 ChatPharoLogger logBackend: 'Error during message send' details: (Dictionary new
							                  at: 'chatId' put: self identityHash;
							                  at: 'error' put: ex messageText;
							                  yourself).
					                 onErrorReceived ifNotNil: [ :blk | blk value: ex messageText ] ] ] fork
]

{ #category : 'running' }
ChatPharoChat >> sendMessageViaMultivers: aText [

	"Execute the message through the multivers chain"

	| multivers |
	multivers := ChatPharoSettings default multivers.

	promptProcess := [
		[
			| answer |
			ChatPharoLogger logBackend: 'Starting multivers chain execution'
				details: (Dictionary new
					at: 'prompt' put: aText;
					at: 'stepsCount' put: multivers stepsCount;
					yourself).

			answer := multivers executeForPrompt: aText.
			cache at: aText put: answer.
			self addAssistantMessage: answer.

			ChatPharoLogger logBackend: 'Multivers chain execution completed'
				details: (Dictionary new
					at: 'responseLength' put: answer size;
					yourself).

			onAnswerReceived ifNotNil: [ :blk | blk value: messages last ]
		] on: Error do: [ :ex |
			ChatPharoLogger logBackend: 'Error during multivers execution'
				details: (Dictionary new
					at: 'chatId' put: self identityHash;
					at: 'error' put: ex messageText;
					yourself).
			onErrorReceived ifNotNil: [ :blk | blk value: ex messageText ]
		]
	] fork
]

{ #category : 'memory' }
ChatPharoChat >> summarizeConversationToMemory [
	"Create a summary of this conversation and store it in memory.
	 This is typically called when the chat is closed or cleared."

	| summary messageCount |
	(ChatPharoSettings default memoryEnabled and: [
		 ChatPharoSettings default memoryAutoSummarize and: [
			 self class environment includesKey: #ChatPharoMemory ] ]) ifFalse: [ ^ self ].

	messageCount := messages size.
	messageCount < 2 ifTrue: [ ^ self ]. "Don't summarize trivial conversations"

	summary := String streamContents: [ :stream |
		           stream nextPutAll: 'Conversation with '.
		           stream nextPutAll: messageCount asString.
		           stream nextPutAll: ' exchanges. Topics discussed: '.
		           (messages first: (3 min: messageCount)) do: [ :msg |
			           msg content ifNotNil: [ :c |
				           stream
					           nextPutAll: (c truncateTo: 50);
					           nextPutAll: '; ' ] ] ].

	(self class environment at: #ChatPharoMemory) default
		addConversationSummary: summary.

	ChatPharoLogger logSystem: 'Conversation summarized to memory'
		details: (Dictionary new
				 at: 'messageCount' put: messageCount;
				 yourself)
]

{ #category : 'running' }
ChatPharoChat >> triggerToolExecution [

	self triggerToolExecution: nil
]

{ #category : 'running' }
ChatPharoChat >> triggerToolExecution: aToolName [
	onToolExecution ifNotNil: [ :blk | blk cull: aToolName ]
]

{ #category : 'running' }
ChatPharoChat >> waitForPromptProcessDone [ 
    | promptProcess |
promptProcess ifNotNil: [ promptProcess waitUntil: [ promptProcess isTerminated ] ].

]

{ #category : 'running' }
ChatPharoChat >> whenAnswerReceivedDo: aBlock [

	onAnswerReceived := aBlock
]

{ #category : 'initialization' }
ChatPharoChat >> whenChatResetDo: aBlock [

	onChatReset := aBlock
]

{ #category : 'running' }
ChatPharoChat >> whenErrorReceivedDo: aBlock [

	onErrorReceived := aBlock
]

{ #category : 'initialization' }
ChatPharoChat >> whenNewChatRequestedDo: aBlock [ 

	onNewChatRequested := aBlock
]

{ #category : 'running' }
ChatPharoChat >> whenToolExecutionDo: aBlock [ 

        onToolExecution := aBlock
]
