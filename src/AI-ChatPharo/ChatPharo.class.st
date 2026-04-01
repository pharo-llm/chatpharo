"
The **application root-object**.

* Owns global `settings` (which agent to use) and an ordered collection of open `chats`.
* Spawns new chat sessions through `newChat`.
* **Why** – single source of truth for top-level state; presenters bind to it to build windows/toolbars.


```samlltalk
ChatPharo new presenter open.

ChatPharoSettings new presenter open


```
"
Class {
	#name : 'ChatPharo',
	#superclass : 'Object',
	#instVars : [
		'settings',
		'chats'
	],
	#category : 'AI-ChatPharo',
	#package : 'AI-ChatPharo'
}

{ #category : 'context' }
ChatPharo class >> ask: text [

^ self
                performQuickActionNamed: 'Quick ask'
                prompt: text
                additionalDetails: nil
                customizeAgent: nil
]

{ #category : 'tests' }
ChatPharo class >> askAboutMethod: aMethod [

        | methodClass source className selector packageName prompt details |
        methodClass := (aMethod respondsTo: #methodClass)
                        ifTrue: [ aMethod methodClass ]
                        ifFalse: [ nil ].
        source := (aMethod respondsTo: #sourceCode)
                        ifTrue: [ aMethod sourceCode ]
                        ifFalse: [ '' ].
        className := methodClass
                        ifNotNil: [ methodClass name asString ]
                        ifNil: [ nil ].
        selector := (aMethod respondsTo: #selector)
                        ifTrue: [ aMethod selector asString ]
                        ifFalse: [ nil ].
        packageName := (methodClass respondsTo: #package)
                        ifTrue: [
                                | package |
                                package := methodClass package.
                                package ifNotNil: [ package name asString ] ]
                        ifFalse: [ nil ].
        prompt := self
                        promptForMethodExplanationSource: source
                        className: className
                        selector: selector.
        details := Dictionary new.
        className ifNotNil: [ details at: 'class' put: className ].
        selector ifNotNil: [ details at: 'selector' put: selector ].
        packageName ifNotNil: [ details at: 'package' put: packageName ].
        ^ self
                performQuickActionNamed: 'Quick ask'
                prompt: prompt
                additionalDetails: details
                customizeAgent: [ :agent |
                        packageName ifNotNil: [
                                (agent respondsTo: #packageName:)
                                        ifTrue: [ agent packageName: packageName ] ] ]
]

{ #category : 'tests' }
ChatPharo class >> askAboutMethod: aMethod withSystemPrompt: aSystemPrompt [

	| methodClass source className selector packageName prompt details |
	methodClass := (aMethod respondsTo: #methodClass)
		               ifTrue: [ aMethod methodClass ]
		               ifFalse: [ nil ].
	source := (aMethod respondsTo: #sourceCode)
		          ifTrue: [ aMethod sourceCode ]
		          ifFalse: [ '' ].
	className := methodClass
		             ifNotNil: [ methodClass name asString ]
		             ifNil: [ nil ].
	selector := (aMethod respondsTo: #selector)
		            ifTrue: [ aMethod selector asString ]
		            ifFalse: [ nil ].
	packageName := (methodClass respondsTo: #package)
		               ifTrue: [
			               | package |
			               package := methodClass package.
			               package ifNotNil: [ package name asString ] ]
		               ifFalse: [ nil ].
	prompt := self
		          promptForMethodExplanationSource: source
		          className: className
		          selector: selector.
	details := Dictionary new.
	className ifNotNil: [ details at: 'class' put: className ].
	selector ifNotNil: [ details at: 'selector' put: selector ].
	packageName ifNotNil: [ details at: 'package' put: packageName ].
	^ self
		  performQuickActionNamed: 'Quick ask'
		  prompt: prompt
		  additionalDetails: details
		  customizeAgent: [ :agent |
			  packageName ifNotNil: [
				  (agent respondsTo: #packageName:)
					  ifTrue: [ agent packageName: packageName ] ].
			  (aSystemPrompt isNotNil and: [ aSystemPrompt notEmpty ])
				  ifTrue: [
					  (agent respondsTo: #systemPrompt:)
						  ifTrue: [ agent systemPrompt: aSystemPrompt ] ] ]
]

{ #category : 'context' }
ChatPharo class >> code: sourceText [

        | prompt |
        prompt := self codePromptForSource: sourceText context: nil.
        ^ self
                performQuickActionNamed: 'Quick code'
                prompt: prompt
                additionalDetails: nil
                customizeAgent: nil

]

{ #category : 'context' }
ChatPharo class >> codeAndFixFromDebugger: aStDebugger [
	"Intelligent debugging: extract full error context from the debugger
	 (exception, stack trace, variables, receiver state) and open a
	 ChatPharo session with a rich diagnostic prompt and debugger-
	 specific tools that the LLM can use to investigate further."

	| debugCtx debugEnv prompt details |
	debugCtx := ChatPharoDebuggerContext fromDebugger: aStDebugger.
	debugEnv := ChatPharoDebuggerEnvironment forContext: debugCtx.

	"Register debugger tools as temporal tools so the LLM can call them"
	debugEnv tools do: [ :tool |
		ChatPharoTemporalToolRegistry current registerClient: tool ].

	prompt := debugCtx diagnosticPrompt.
	details := Dictionary new.
	debugCtx failingClassName ifNotNil: [ details at: 'class' put: debugCtx failingClassName ].
	debugCtx failingSelector ifNotNil: [ details at: 'selector' put: debugCtx failingSelector ].
	debugCtx failingPackageName ifNotNil: [ details at: 'package' put: debugCtx failingPackageName ].
	debugCtx errorClassName ifNotNil: [ details at: 'exception' put: debugCtx errorClassName ].

	^ self
		  performQuickActionNamed: 'Intelligent Debug'
		  prompt: prompt
		  additionalDetails: details
		  customizeAgent: [ :agent |
			  agent systemPrompt: debugCtx systemPromptForDebugging.
			  debugCtx failingPackageName ifNotNil: [
				  (agent respondsTo: #packageName:)
					  ifTrue: [ agent packageName: debugCtx failingPackageName ] ] ]
]

{ #category : 'tests' }
ChatPharo class >> codeForMethod: aMethod [

        | methodClass source className selector packageName context details prompt |
        methodClass := (aMethod respondsTo: #methodClass)
                        ifTrue: [ aMethod methodClass ]
                        ifFalse: [ nil ].
        source := (aMethod respondsTo: #sourceCode)
                        ifTrue: [ aMethod sourceCode ]
                        ifFalse: [ '' ].
        className := methodClass
                        ifNotNil: [ methodClass name asString ]
                        ifNil: [ nil ].
        selector := (aMethod respondsTo: #selector)
                        ifTrue: [ aMethod selector asString ]
                        ifFalse: [ nil ].
        packageName := (methodClass respondsTo: #package)
                        ifTrue: [
                                | package |
                                package := methodClass package.
                                package ifNotNil: [ package name asString ] ]
                        ifFalse: [ nil ].
        context := Dictionary new.
        className ifNotNil: [ context at: 'Class' put: className ].
        selector ifNotNil: [ context at: 'Selector' put: selector ].
        context isEmpty ifTrue: [ context := nil ].
        prompt := self codePromptForSource: source context: context.
        details := Dictionary new.
        className ifNotNil: [ details at: 'class' put: className ].
        selector ifNotNil: [ details at: 'selector' put: selector ].
        packageName ifNotNil: [ details at: 'package' put: packageName ].
        ^ self
                performQuickActionNamed: 'Quick code'
                prompt: prompt
                additionalDetails: details
                customizeAgent: [ :agent |
                        packageName ifNotNil: [
                                (agent respondsTo: #packageName:)
                                        ifTrue: [ agent packageName: packageName ] ] ]
]

{ #category : 'context' }
ChatPharo class >> codePromptForSource: source context: contextDictionary [

    | lines safeSource |
    safeSource := source ifNil: [ '' ].

    lines := OrderedCollection new.
    contextDictionary ifNotNil: [
        contextDictionary associationsDo: [ :assoc |
            assoc value ifNotNil: [
                lines add: assoc key , ': ' , assoc value ] ] ].

    ^ String streamContents: [ :stream |
        stream
            nextPutAll: 'Suggest improvements or provide a revised Smalltalk implementation for the following code while preserving its behaviour.';
            cr;
            cr.
        lines do: [ :line |
            stream nextPutAll: line; cr ].
        lines isEmpty ifFalse: [ stream cr ].
        stream
            nextPutAll: '```smalltalk';
            cr;
            nextPutAll: safeSource;
            cr;
            nextPutAll: '```' ]

]

{ #category : 'context' }
ChatPharo class >> performQuickActionNamed: actionName prompt: prompt additionalDetails: details customizeAgent: customizationBlock [

        | agentCopy chat baseDetails frontendDetails backendDetails |
        baseDetails := details
                        ifNil: [ Dictionary new ]
                        ifNotNil: [ details copy ].
        baseDetails at: 'prompt' put: prompt.
        frontendDetails := baseDetails copy.
        ChatPharoLogger
                logFrontend: actionName , ' invoked'
                details: frontendDetails.
        agentCopy := ChatPharoSettings default agent.
        agentCopy := (agentCopy isKindOf: ChatPharoAgent)
                             ifTrue: [ agentCopy copyForChat ]
                             ifFalse: [ agentCopy ].
        customizationBlock ifNotNil: [ customizationBlock value: agentCopy ].
        chat := ChatPharoChat new
                        agent: ChatPharoSettings default agent;
                        agent: agentCopy;
                        yourself.
        chat presenter open.
        prompt ifNotEmpty: [ chat sendMessage: prompt ].
        backendDetails := baseDetails copy.
        backendDetails at: 'activeAgent' put: (ChatPharoLogger agentNameFor: agentCopy).
        ChatPharoLogger
                logSystem: actionName , ' completed'
                details: backendDetails.
        ^ chat
]

{ #category : 'context' }
ChatPharo class >> promptForMethodExplanationSource: source className: className selector: selector [

    | lines safeSource |
    safeSource := source ifNil: [ '' ].

    lines := OrderedCollection new.
    className ifNotNil: [ lines add: 'Class: ' , className ].
    selector ifNotNil: [ lines add: 'Selector: ' , selector ].

    ^ String streamContents: [ :stream |
        stream
            nextPutAll: 'Explain what the following Smalltalk method does and highlight any potential improvements or edge cases.';
            cr;
            cr.
        lines do: [ :line |
            stream nextPutAll: line; cr ].
        lines isEmpty ifFalse: [ stream cr ].
        stream
            nextPutAll: '```smalltalk';
            cr;
            nextPutAll: safeSource;
            cr;
            nextPutAll: '```' ]

]

{ #category : 'accessing' }
ChatPharo >> activeAgent [
    
    ^ chats isEmpty
        ifTrue: [ nil ]
        ifFalse: [ chats last agent ]
]

{ #category : 'initialization' }
ChatPharo >> chats [

	^ chats
]

{ #category : 'initialization' }
ChatPharo >> initialize [

	super initialize.
	settings := ChatPharoSettings default.
	settings agent systemPrompt isEmpty ifTrue: [ settings agent systemPrompt: ChatPharoAgent defaultSystemPrompt ].
	chats := OrderedCollection new.
	ChatPharoLogger logSystem: 'ChatPharo initialized' details: (Dictionary new
			 at: 'defaultAgent' put: (ChatPharoLogger agentNameFor: settings agent);
			 yourself)
]

{ #category : 'initialization' }
ChatPharo >> newChat [

	| agentCopy |
	agentCopy := self settings agent.
	agentCopy := (agentCopy isKindOf: ChatPharoAgent)
		             ifTrue: [ agentCopy copyForChat ]
		             ifFalse: [ agentCopy ].
	chats add: (ChatPharoChat new
			 agent: agentCopy;
			 yourself).
        ChatPharoLogger logFrontend: 'New chat session created'
                details: (Dictionary new
                        at: 'totalChats' put: chats size;
                        at: 'agent' put: (ChatPharoLogger agentNameFor: agentCopy);
                        yourself)
]

{ #category : 'initialization' }
ChatPharo >> presenter [

	^ ChatPharoPresenter on: self 
]

{ #category : 'accessing' }
ChatPharo >> removeAllChats [

	| removed |
	chats do: [ :each | each clearChat ].
	        removed := chats size.
        chats removeAll.
        ChatPharoLogger logFrontend: 'All chats removed'
                details: (Dictionary new
                        at: 'removedCount' put: removed;
                        yourself)
]

{ #category : 'accessing' }
ChatPharo >> removeChatAt: anIndex [

	        | removedChat agentName |
        removedChat := chats at: anIndex ifAbsent: [ nil ].
        chats removeAt: anIndex.
        agentName := removedChat
                ifNotNil: [ ChatPharoLogger agentNameFor: removedChat agent ]
                ifNil: [ 'None' ].
        ChatPharoLogger logFrontend: 'Chat removed'
                details: (Dictionary new
                        at: 'index' put: anIndex;
                        at: 'remainingChats' put: chats size;
                        at: 'agent' put: agentName;
                        yourself)
]

{ #category : 'accessing' }
ChatPharo >> settings [

	^ settings
]

{ #category : 'accessing' }
ChatPharo >> synchronizeChatsWithSettingsAgent [

	| configuredAgent |
	configuredAgent := self settings agent.
	chats do: [ :chat |
			| chatAgent |
			chatAgent := (configuredAgent isKindOf: ChatPharoAgent)
				             ifTrue: [ configuredAgent copyForChat ]
				             ifFalse: [ configuredAgent ].
			chat agent: chatAgent ]
]
