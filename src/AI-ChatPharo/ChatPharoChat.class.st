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
		'onNewChatRequested',
		'onTitleGenerated',
		'titleGenerated',
		'id',
		'title',
		'archive',
		'onQuestionRecorded'
	],
	#category : 'AI-ChatPharo',
	#package : 'AI-ChatPharo'
}

{ #category : 'instance creation' }
ChatPharoChat class >> fromArchiveEntry: aDictionary [
	"Answer the chat stored in aDictionary by #archiveEntry."

	^ self new
		  restoreFromArchiveEntry: aDictionary;
		  yourself
]

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
	"Show anAnswer as the reply to the last user message. The answer is either the written
	 text or a reply object carrying it; usage and reasoning come from the agent's last reply."

	self addAssistantMessage: anAnswer details: (self replyDetailsFor: anAnswer)
]

{ #category : 'private' }
ChatPharoChat >> addAssistantMessage: anAnswer details: aReply [

	| text label |
	text := self textOfAnswer: anAnswer.
	label := self assistantLabel.
	history ensureEndsWithAssistant: text.
	messages last
		answer: text;
		assistantLabel: label;
		thinking: ((aReply ifNotNil: [ aReply thinking ]) ifNil: [ '' ]);
		inputTokens: ((aReply ifNotNil: [ aReply inputTokens ]) ifNil: [ 0 ]);
		outputTokens: ((aReply ifNotNil: [ aReply outputTokens ]) ifNil: [ 0 ]);
		totalTokens: ((aReply ifNotNil: [ aReply totalTokens ]) ifNil: [ 0 ]).
	ChatPharoLogger logBackend: 'Assistant response recorded' details: (Dictionary new
			 at: 'chatId' put: self identityHash;
			 at: 'agent' put: (ChatPharoLogger agentNameFor: self agent);
			 at: 'assistantLabel' put: label;
			 at: 'response' put: text;
			 yourself)
]

{ #category : 'running' }
ChatPharoChat >> addUserMessage: text [

	| message content attachments |
	(text isKindOf: ChatPharoMessage) ifTrue: [
			message := text.
			content := message content.
			attachments := message attachments.
			history addUser: (content ifNil: [ '' ]).
			self recordUserNameIfPresentIn: content.
			attachments ifNotNil: [ message attachments: attachments ].
			messages add: message.
			^ self ].

	history addUser: text.
	self recordUserNameIfPresentIn: text.
	messages add: (ChatPharoMessage new
			 content: text;
			 yourself).
]

{ #category : 'private' }
ChatPharoChat >> addUserMessage: aText prompt: aPrompt attachments: attachmentCollection [
	"The reader sees aText and its attachments; the model reads aPrompt, which inlines the files."

	| message |
	history addUser: aPrompt.
	self recordUserNameIfPresentIn: aText.
	message := ChatPharoMessage new
		           content: aText;
		           attachments: attachmentCollection asOrderedCollection;
		           yourself.
	messages add: message.
	onQuestionRecorded ifNotNil: [ :blk | blk value: message ]
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
	"The greeting is for the reader only. It is not recorded in the LLM history: backends
	 such as Gemini and Claude reject, or answer oddly to, a conversation opened by the assistant."

	messages add: (ChatPharoMessage new
			 answer:
				 'Welcome to ChatPharo! I can answer questions, help explore your Pharo image, run snippets and search your code. Type a message to get started.';
			 assistantLabel: 'ChatPharo';
			 yourself)
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
ChatPharoChat >> answerPrompt: aPrompt cachedAt: aCacheKey titledFrom: aText [

	[
		| answer |
		answer := self askAgent: aPrompt.
		cache at: aCacheKey put: answer.
		self addAssistantMessage: answer.
		self save.
		self notifyAnswerReceived.
		self generateTitleOnceFrom: aText ]
		on: Error
		do: [ :error | self reportSendFailure: error ]
]

{ #category : 'persistence' }
ChatPharoChat >> archive: aChatArchive [
	"From now on I save myself into aChatArchive after each answer. Nil makes me transient."

	archive := aChatArchive
]

{ #category : 'persistence' }
ChatPharoChat >> archiveEntry [
	"What is written to disk: my identity and the LLM history, tool exchanges included."

	^ Dictionary new
		  at: 'id' put: self id;
		  at: 'title' put: self title;
		  at: 'messages' put: (Array streamContents: [ :stream | history putOpenAIChatMessagesOn: stream ]);
		  yourself
]

{ #category : 'private' }
ChatPharoChat >> askAgent: aPrompt [

	| backend |
	backend := self agent.
	backend onToolExecution: [ :toolName | self triggerToolExecution: toolName ].
	backend promptPrefix: (self buildPromptPrefixWithMemoryFor: aPrompt).
	^ self
		  inject: (self contextPromptFor: aPrompt)
		  intoSystemPromptOf: backend
		  during: [ self withRetries: [ backend getResponseForPrompt: aPrompt ] ]
]

{ #category : 'private' }
ChatPharoChat >> assistantLabel [

	| multivers |
	multivers := ChatPharoSettings default multivers.
	(multivers notNil and: [ multivers canExecute ]) ifTrue: [
		^ 'Multivers (' , multivers stepsCount asString , ' agents)' ].
	^ (self agent isKindOf: ChatPharoNullAgent)
		  ifTrue: [ 'Assistant bot' ]
		  ifFalse: [ 'Assistant' ]
]

{ #category : 'private' }
ChatPharoChat >> buildPromptPrefixWithMemoryFor: queryText [

	| prefix memoryContext |
	prefix := history asPromptPrefix. 
	(ChatPharoSettings default memoryEnabled and: [ self class environment includesKey: #ChatPharoMemory ]) ifTrue: [
			memoryContext := (self class environment at: #ChatPharoMemory) default contextForQuery: queryText.
			memoryContext ifNotEmpty: [ prefix := memoryContext , String cr , prefix ] ].

	^ prefix
]

{ #category : 'private' }
ChatPharoChat >> cacheKeyFor: aPrompt [
	"An answer is only reusable for the same prompt in the same conversation state.
	 Keying on the prompt alone made a second 'continue' or 'yes' replay an old answer."

	^ history asPromptPrefix , aPrompt
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

	self summarizeConversationToMemory.
	self cancelMessage.
	history clear.
	messages removeAll.
	self clearCache.
	ChatPharoToolConfirmation default clearSessionApprovals.
	archive ifNotNil: [ archive remove: self ]
]

{ #category : 'private' }
ChatPharoChat >> contextPromptFor: aPrompt [
	"Everything the model must know before reading the conversation:
	 environment, project, session and long-term memory layers."

	^ ChatPharoContext default promptFor: aPrompt
]

{ #category : 'private' }
ChatPharoChat >> deliverCachedAnswer: anAnswer titledFrom: aText [

	self addAssistantMessage: anAnswer details: nil.
	self notifyAnswerReceived.
	self generateTitleOnceFrom: aText
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

	| remainder candidate splitters |
	remainder := (text copyFrom: startIndex + 1 to: text size) trimBoth.
	[ remainder notEmpty and: [ '.,!?;' includes: remainder last ] ] whileTrue: [ remainder := remainder allButLast ].
	remainder ifEmpty: [ ^ nil ].

	splitters := #( ' and ' ' but ' ' so ' ' because ' ' that ' ).
	candidate := remainder.
	splitters do: [ :splitter |
			| index |
			index := candidate findString: splitter startingAt: 1.
			index > 0 ifTrue: [ candidate := (candidate copyFrom: 1 to: index - 1) trimBoth ] ].

	candidate ifEmpty: [ ^ nil ].
	candidate first isLetter ifFalse: [ ^ nil ].
	(candidate allSatisfy: [ :char | char isLetter or: [ char = $  or: [ char = $- or: [ char = $' ] ] ] ]) ifFalse: [ ^ nil ].

	^ candidate
]

{ #category : 'initialization' }
ChatPharoChat >> generateTitleFrom: userText [

	| titleAgent prompt result cleanTitle |
	ChatPharoSettings default dynamicChatNamingEnabled ifFalse: [ ^ self ].
	titleAgent := self agent copyForChat.
	"TODO : Maybe this title can be more precise to let the model do not generate other stuff"
	prompt := 'Give a short title of 3 to 5 words for a chat conversation that starts with this message. Each word must be separated by a space. Use title case. Reply with the title only, no punctuation, no quotes, no extra explanation: '
	          , userText.
	[
		[
			result := titleAgent getResponseForPrompt: prompt.
			cleanTitle := result asString trimBoth.
			cleanTitle := cleanTitle copyReplaceAll: '''' with: ''.
			cleanTitle := cleanTitle copyReplaceAll: String cr with: ' '.
			cleanTitle := cleanTitle copyReplaceAll: String lf with: ' '.
			cleanTitle size > 40 ifTrue: [ cleanTitle := (cleanTitle copyFrom: 1 to: 40) trimBoth ].
			(cleanTitle includesSubstring: ' ') ifFalse: [
					| spaced |
					spaced := String streamContents: [ :s |
							          cleanTitle doWithIndex: [ :char :i |
									          (i > 1 and: [ char isUppercase ]) ifTrue: [ s nextPut: $  ].
									          s nextPut: char ] ].
					cleanTitle := spaced ].
			cleanTitle ifEmpty: [ cleanTitle := 'Chat' ].
			self title: cleanTitle.
			onTitleGenerated ifNotNil: [ :blk | blk value: cleanTitle ].
			ChatPharoLogger logBackend: 'Chat title generated' details: (Dictionary new
					 at: 'chatId' put: self identityHash;
					 at: 'title' put: cleanTitle;
					 yourself) ]
			on: Error
			do: [ :ex |
					ChatPharoLogger logBackend: 'Chat title generation failed' details: (Dictionary new
							 at: 'chatId' put: self identityHash;
							 at: 'error' put: ex messageText;
							 yourself) ] ] fork
]

{ #category : 'private' }
ChatPharoChat >> generateTitleOnceFrom: aText [

	(titleGenerated or: [ onTitleGenerated isNil ]) ifTrue: [ ^ self ].
	titleGenerated := true.
	self generateTitleFrom: aText
]

{ #category : 'testing' }
ChatPharoChat >> hasConversation [

	^ history isEmpty not
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
ChatPharoChat >> id [
	"A stable name for my file in the archive."

	^ id ifNil: [ id := UUID new asString ]
]

{ #category : 'private - import' }
ChatPharoChat >> importEntry: aDictionary [

	| role content toolCalls |
	role := aDictionary at: 'role'.
	role = 'tool' ifTrue: [ ^ self importToolResult: aDictionary ].
	content := aDictionary at: 'content' ifAbsent: [ '' ].
	toolCalls := self importedToolCallsFrom: aDictionary.
	"Files written by older versions repeat each plain message twice."
	(toolCalls isNil and: [ history endsWithRole: role content: content ]) ifTrue: [ ^ self ].
	history addMessage: (ChatPharoHistoryMessage role: role content: content toolCalls: toolCalls)
]

{ #category : 'accessing' }
ChatPharoChat >> importFromJson: aJsonString [
	"Replace this conversation by the one exported with #exportAsJson.
	 The model sees it again exactly as it was, tool calls and their results included,
	 so the conversation can be continued and not only read."

	| entries |
	self clearChat.
	entries := STONJSON fromString: aJsonString.
	entries do: [ :each | self importEntry: each ].
	self rebuildMessagesFromHistory.
	self save.
	ChatPharoLogger logBackend: 'Chat imported from JSON' details: (Dictionary new
			 at: 'chatId' put: self identityHash;
			 at: 'messagesImported' put: entries size;
			 yourself).
	self notifyChatReset
]

{ #category : 'private - import' }
ChatPharoChat >> importToolResult: aDictionary [
	"A tool result belongs to the call that asked for it; that call replays it to the model."

	| callId |
	history isEmpty ifTrue: [ ^ self ].
	callId := aDictionary at: 'tool_call_id' ifAbsent: [ ^ self ].
	(history messages last toolCalls ifNil: [ #(  ) ])
		detect: [ :each | each id = callId ]
		ifFound: [ :call | call content: (aDictionary at: 'content' ifAbsent: [ nil ]) ]
]

{ #category : 'private - import' }
ChatPharoChat >> importedToolCallsFrom: aDictionary [

	^ (aDictionary at: 'tool_calls' ifAbsent: [ nil ]) ifNotNil: [ :calls |
		  calls collect: [ :each |
			  | function |
			  function := each at: 'function' ifAbsent: [ Dictionary new ].
			  ChatPharoHistorySaverToolCall
				  id: (each at: 'id' ifAbsent: [ '' ])
				  functionName: (function at: 'name' ifAbsent: [ '' ])
				  arguments: (function at: 'arguments' ifAbsent: [ '' ])
				  content: nil ] ]
]

{ #category : 'initialization' }
ChatPharoChat >> initialize [

	super initialize.
	history := ChatPharoHistory new.
	messages := OrderedCollection new.
	onToolExecution := nil.
	onChatReset := nil.
	cache := Dictionary new.
	titleGenerated := false.
	ChatPharoSettings default welcomeMessageEnabled ifTrue: [ self addWelcomeMessage ]
]

{ #category : 'private' }
ChatPharoChat >> inject: aContextString intoSystemPromptOf: anAgent during: aBlock [
	"Extend the agent's system prompt with aContextString for the duration of aBlock.
	 Agents that have no system prompt protocol (test doubles) are asked as they are."

	| originalPrompt |
	aContextString ifEmpty: [ ^ aBlock value ].
	((anAgent respondsTo: #systemPrompt) and: [ anAgent respondsTo: #systemPrompt: ]) ifFalse: [ ^ aBlock value ].
	originalPrompt := anAgent systemPrompt.
	anAgent systemPrompt: originalPrompt , String cr , String cr , aContextString.
	^ aBlock ensure: [ anAgent systemPrompt: originalPrompt ]
]

{ #category : 'testing' }
ChatPharoChat >> isAnswering [
	"Whether a request is in flight."

	^ promptProcess notNil and: [ promptProcess isTerminated not ]
]

{ #category : 'private' }
ChatPharoChat >> isTextFile: aFileReference [

	^ (aFileReference mimeTypes ifNil: [ #(  ) ]) anySatisfy: [ :each | each main = 'text' ]
]

{ #category : 'accessing' }
ChatPharoChat >> jsonStringFor: anObject [

	^ STONJSON toString: anObject
]

{ #category : 'accessing' }
ChatPharoChat >> messageLimitReached [

	| settings limit |
	settings := ChatPharoSettings default.
	settings ethicsDirectorEnabled ifFalse: [ ^ false ].
	limit := settings messageLimit.
	(limit isNil or: [ limit isNumber not ]) ifTrue: [ ^ false ].
	^ messages size >= limit
]

{ #category : 'accessing' }
ChatPharoChat >> messages [

	^ messages
]

{ #category : 'accessing' }
ChatPharoChat >> messages: anObject [

	messages := anObject
]

{ #category : 'private' }
ChatPharoChat >> notifyAnswerReceived [

	onAnswerReceived ifNotNil: [ :blk | blk value: messages last ]
]

{ #category : 'initialization' }
ChatPharoChat >> notifyChatReset [ 

	onChatReset ifNotNil: [ :blk | blk value ]
]

{ #category : 'presenters' }
ChatPharoChat >> presenter [

	^ ChatPharoChatPresenter on: self
]

{ #category : 'private' }
ChatPharoChat >> promptFor: aText withAttachments: attachmentCollection [
	"The text sent to the model: the user's words followed by the attached files."

	attachmentCollection ifEmpty: [ ^ aText ].
	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: aText;
			  cr;
			  cr;
			  nextPutAll: 'Attached files:';
			  cr.
		  attachmentCollection do: [ :each | self writeAttachment: each on: stream ] ]
]

{ #category : 'private - import' }
ChatPharoChat >> rebuildMessagesFromHistory [
	"Derive the transcript the reader sees from the LLM history: one entry per user
	 question with its final written answer. Tool round trips stay in the history only."

	| pending |
	messages removeAll.
	pending := nil.
	history messages do: [ :each |
		each role = 'user' ifTrue: [
			pending := ChatPharoMessage new
				           content: (each content ifNil: [ '' ]);
				           yourself.
			messages add: pending ].
		(each role = 'assistant' and: [ each toolCalls isEmptyOrNil ]) ifTrue: [
			pending ifNil: [
				pending := ChatPharoMessage new.
				messages add: pending ].
			pending
				answer: (each content ifNil: [ '' ]);
				assistantLabel: 'Assistant'.
			pending := nil ] ]
]

{ #category : 'memory' }
ChatPharoChat >> recordFeedback: feedbackText positive: isPositive [
	(ChatPharoSettings default memoryEnabled and: [ self class environment includesKey: #ChatPharoMemory ]) ifFalse: [ ^ self ].

	(self class environment at: #ChatPharoMemory) default addFeedback: feedbackText positive: isPositive. "Submit feedback to backend if enabled"
	(self class environment includesKey: #ChatPharoFeedbackSubmitter) ifTrue: [
			(self class environment at: #ChatPharoFeedbackSubmitter) submitFeedback: (Dictionary new
					 at: 'type' put: (isPositive
							  ifTrue: [ 'positive' ]
							  ifFalse: [ 'negative' ]);
					 at: 'content' put: feedbackText;
					 at: 'chatId' put: self identityHash;
					 yourself) ].

	ChatPharoLogger logSystem: 'Feedback recorded to memory' details: (Dictionary new
			 at: 'positive' put: isPositive;
			 yourself)
]

{ #category : 'memory' }
ChatPharoChat >> recordUserCorrection: correctionText [

	(ChatPharoSettings default memoryEnabled and: [ self class environment includesKey: #ChatPharoMemory ]) ifFalse: [ ^ self ].

	(self class environment at: #ChatPharoMemory) default addCorrection: correctionText.

	ChatPharoLogger logSystem: 'Correction recorded to memory' details: (Dictionary new
			 at: 'correction' put: (correctionText truncateTo: 50);
			 yourself)
]

{ #category : 'running' }
ChatPharoChat >> recordUserNameIfPresentIn: text [

	| lowerText prefixes name |
	text ifNil: [ ^ self ].
	(text respondsTo: #content) ifTrue: [ ^ self recordUserNameIfPresentIn: text content ].
	lowerText := text asString asLowercase.
	"TODO: make this prefixes wider and cover other prefixes"
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

	(ChatPharoSettings default memoryEnabled and: [ self class environment includesKey: #ChatPharoMemory ]) ifFalse: [ ^ self ].

	(self class environment at: #ChatPharoMemory) default addUserPreference: preferenceText.

	ChatPharoLogger logSystem: 'User preference recorded to memory' details: (Dictionary new
			 at: 'preference' put: (preferenceText truncateTo: 50);
			 yourself)
]

{ #category : 'private' }
ChatPharoChat >> replyDetailsFor: anAnswer [
	"Answer the object carrying usage and reasoning for anAnswer, or nil when there is none.
	 Agents answer plain text and keep the full reply in #response; test doubles may do neither."

	(anAnswer respondsTo: #inputTokens) ifTrue: [ ^ anAnswer ].
	(self agent respondsTo: #response) ifFalse: [ ^ nil ].
	^ self agent response ifNotNil: [ :reply | (reply respondsTo: #inputTokens) ifTrue: [ reply ] ]
]

{ #category : 'accessing' }
ChatPharoChat >> reportMessageLimitReached [

	| limit text |
	limit := ChatPharoSettings default messageLimit.
	text := 'Message limit reached (' , limit asString
		, '). Update the limit in Settings > Ethics or start a new chat.'.
	ChatPharoLogger logFrontend: 'Message limit enforced'
		details: (Dictionary new
			at: 'chatId' put: self identityHash;
			at: 'limit' put: limit;
			at: 'messages' put: messages size;
			yourself).
	onErrorReceived ifNotNil: [ :blk | blk value: text ]
]

{ #category : 'private' }
ChatPharoChat >> reportSendFailure: anError [

	ChatPharoLogger logBackend: 'Error during message send' details: (Dictionary new
			 at: 'chatId' put: self identityHash;
			 at: 'error' put: anError messageText;
			 yourself).
	onErrorReceived ifNotNil: [ :blk | blk value: anError messageText ]
]

{ #category : 'initialization' }
ChatPharoChat >> requestNewChat [ 

	onNewChatRequested
		ifNotNil: [ :blk | blk value ]
		ifNil: [ self resetConversation ]
]

{ #category : 'initialization' }
ChatPharoChat >> resetConversation [

	self summarizeConversationToMemory.

	self cancelMessage.
	history clear.
	messages removeAll.
	archive ifNotNil: [ archive remove: self ].
	self clearCache.
	ChatPharoSettings default welcomeMessageEnabled ifTrue: [ self addWelcomeMessage ].
	self notifyChatReset
]

{ #category : 'persistence' }
ChatPharoChat >> restoreFromArchiveEntry: aDictionary [

	id := aDictionary at: 'id' ifAbsent: [ nil ].
	title := aDictionary at: 'title' ifAbsent: [ nil ].
	(aDictionary at: 'messages' ifAbsent: [ #(  ) ]) do: [ :each | self importEntry: each ].
	self rebuildMessagesFromHistory.
	titleGenerated := title notNil
]

{ #category : 'persistence' }
ChatPharoChat >> save [
	"Persist me when I belong to an archive. Chats opened for a quick action do not."

	archive ifNotNil: [ archive save: self ]
]

{ #category : 'running' }
ChatPharoChat >> sendMessage: aText [

	self sendMessage: aText withAttachments: #(  )
]

{ #category : 'running' }
ChatPharoChat >> sendMessage: aText withAttachments: attachmentCollection [
	"Record the user's message and answer it asynchronously.
	 Listeners are told through whenAnswerReceivedDo: or whenErrorReceivedDo:."

	| prompt cacheKey multivers |
	self messageLimitReached ifTrue: [ ^ self reportMessageLimitReached ].
	prompt := self promptFor: aText withAttachments: attachmentCollection.
	cacheKey := self cacheKeyFor: prompt.
	self addUserMessage: aText prompt: prompt attachments: attachmentCollection.

	(cache includesKey: cacheKey) ifTrue: [ ^ self deliverCachedAnswer: (cache at: cacheKey) titledFrom: aText ].
	multivers := ChatPharoSettings default multivers.
	(multivers notNil and: [ multivers canExecute ]) ifTrue: [ ^ self sendMessageViaMultivers: prompt ].
	promptProcess := [ self answerPrompt: prompt cachedAt: cacheKey titledFrom: aText ] fork
]

{ #category : 'running' }
ChatPharoChat >> sendMessageViaMultivers: aText [

	| multivers  |
		self messageLimitReached ifTrue: [
		^ self reportMessageLimitReached ].
	multivers := ChatPharoSettings default multivers.

	promptProcess := [
		                 [
			                 | answer retryHandler |
			                 ChatPharoLogger logBackend: 'Starting multivers chain execution' details: (Dictionary new
					                  at: 'prompt' put: aText;
					                  at: 'stepsCount' put: multivers stepsCount;
					                  yourself).

			                 "Use retry handler if enabled"
			                 ChatPharoSettings default retryEnabled
				                 ifTrue: [
					                 retryHandler := ChatPharoSettings default createRetryHandler.
					                 retryHandler onRetryAttempt: [ :attempt :max |
						                 onErrorReceived ifNotNil: [ :blk |
							                 blk value: 'Connection lost. Retrying attempt ' , attempt asString , '/' , max asString , '...' ] ].
					                 answer := retryHandler executeWithRetry: [ multivers executeForPrompt: aText ] ]
				                 ifFalse: [
					                 answer := multivers executeForPrompt: aText ].
			                 cache at: aText put: answer.
			                 self addAssistantMessage: answer.

			                 ChatPharoLogger logBackend: 'Multivers chain execution completed' details: (Dictionary new
					                  at: 'responseLength' put: answer size;
					                  yourself).

			                 onAnswerReceived ifNotNil: [ :blk | blk value: messages last ] ]
			                 on: Error
			                 do: [ :ex |
					                 ChatPharoLogger logBackend: 'Error during multivers execution' details: (Dictionary new
							                  at: 'chatId' put: self identityHash;
							                  at: 'error' put: ex messageText;
							                  yourself).
					                 onErrorReceived ifNotNil: [ :blk | blk value: ex messageText ] ] ] fork
]

{ #category : 'memory' }
ChatPharoChat >> summarizeConversationToMemory [

	| summary messageCount |
	(ChatPharoSettings default memoryEnabled and: [
		 ChatPharoSettings default memoryAutoSummarize and: [ self class environment includesKey: #ChatPharoMemory ] ]) ifFalse: [
		^ self ].

	messageCount := messages size.
	messageCount < 2 ifTrue: [ ^ self ].

	summary := String streamContents: [ :stream |
			           stream nextPutAll: 'Conversation with '.
			           stream nextPutAll: messageCount asString.
			           stream nextPutAll: ' exchanges. Topics discussed: '.
			           (messages first: (3 min: messageCount)) do: [ :msg |
					           msg content ifNotNil: [ :c |
							           stream
								           nextPutAll: (c truncateTo: 50);
								           nextPutAll: '; ' ] ] ].

	(self class environment at: #ChatPharoMemory) default addConversationSummary: summary.

	ChatPharoLogger logSystem: 'Conversation summarized to memory' details: (Dictionary new
			 at: 'messageCount' put: messageCount;
			 yourself)
]

{ #category : 'private' }
ChatPharoChat >> textOfAnswer: anAnswer [

	^ (anAnswer respondsTo: #inputTokens)
		  ifTrue: [ anAnswer content ]
		  ifFalse: [ anAnswer ]
]

{ #category : 'accessing' }
ChatPharoChat >> title [
	"The name shown on my tab, or nil while nobody named me."

	^ title
]

{ #category : 'accessing' }
ChatPharoChat >> title: aString [

	title := aString.
	self save
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
	"Block the caller until the request in flight, if any, has finished."

	[ self isAnswering ] whileTrue: [ (Delay forMilliseconds: 20) wait ]
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
ChatPharoChat >> whenQuestionRecordedDo: aBlock [
	"aBlock is evaluated with the message as soon as the user's question is recorded, before the model is asked."

	onQuestionRecorded := aBlock
]

{ #category : 'enumerating' }
ChatPharoChat >> whenTitleGeneratedDo: aBlock [

	onTitleGenerated := aBlock
]

{ #category : 'running' }
ChatPharoChat >> whenToolExecutionDo: aBlock [ 

        onToolExecution := aBlock
]

{ #category : 'private' }
ChatPharoChat >> withMetadataInjectedOn: anAgent do: aBlock [
	"Kept for callers that only want the environment metadata; chats inject the full context."

	ChatPharoSettings default metadataEnabled ifFalse: [ ^ aBlock value ].
	^ self
		  inject: ChatPharoSettings default metadataString
		  intoSystemPromptOf: anAgent
		  during: aBlock
]

{ #category : 'private' }
ChatPharoChat >> withRetries: aBlock [

	| retryHandler |
	ChatPharoSettings default retryEnabled ifFalse: [ ^ aBlock value ].
	retryHandler := ChatPharoSettings default createRetryHandler.
	retryHandler onRetryAttempt: [ :attempt :max |
		onErrorReceived ifNotNil: [ :blk |
			blk value: 'Connection lost. Retrying attempt ' , attempt asString , '/' , max asString , '...' ] ].
	^ retryHandler executeWithRetry: aBlock
]

{ #category : 'private' }
ChatPharoChat >> writeAttachment: aFileReference on: aStream [

	aStream
		nextPutAll: '- ';
		nextPutAll: aFileReference basename;
		nextPutAll: ' (';
		print: aFileReference size;
		nextPutAll: ' bytes)';
		cr.
	(self isTextFile: aFileReference) ifFalse: [ ^ self ].
	aStream
		nextPutAll: '  Content: ';
		cr;
		nextPutAll: aFileReference contents;
		cr
]
