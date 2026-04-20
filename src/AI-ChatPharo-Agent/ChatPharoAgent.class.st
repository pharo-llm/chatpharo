"
The root of the “agent” hierarchy.
It **defines the common contract** any concrete backend must respect:

* **State it holds** – current `model`, optional `system` prompt, a rolling `history`, the `promptPrefix` serialised from that history, and the most recent `response`.
* **Public surface** –

  * *Class side* helpers (`displayName`, `isReachable`, `modelNames`, `settingsPresenterFor:`) so the settings UI can list and configure agents at run time.
  * *Instance side* service `getResponseForPrompt:` which subclasses must override to actually call an LLM.
* **Why it matters** – Everywhere else in ChatPharo the UI can just rely on “an agent” without caring whether it talks to Gemini, Ollama or something else. The abstract class enforces that interchangeability.

```smalltalk
ChatPharo new settings agent class name.
```
"
Class {
	#name : 'ChatPharoAgent',
	#superclass : 'Object',
	#instVars : [
		'model',
		'promptPrefix',
		'response',
		'history',
		'systemPrompt',
		'browserSystemPrompt',
		'onToolExecution',
		'maxTokens',
		'topP',
		'customParameters',
		'onRetry'
	],
	#category : 'AI-ChatPharo-Agent',
	#package : 'AI-ChatPharo-Agent'
}

{ #category : 'api' }
ChatPharoAgent class >> defaultBrowserSystemPrompt [

        ^ 'You are an AI coding assistant inside the Pharo System Browser. The user is exploring the package {packageName}. Focus answers on classes or methods from that package.'
]

{ #category : 'api' }
ChatPharoAgent class >> defaultSystemPrompt [

	^ 'You are an AI coding assistant inside the user''s Pharo image.'
]

{ #category : 'api' }
ChatPharoAgent class >> displayName [

	self subclassResponsibility
]

{ #category : 'api' }
ChatPharoAgent class >> isExternalApi [
	"Return true if this agent sends data to an external (non-local) API provider.
	Subclasses running locally (e.g. Ollama, LM Studio) should override to return false."

	^ true
]

{ #category : 'api' }
ChatPharoAgent class >> isReachable [          
self subclassResponsibility.
]

{ #category : 'api' }
ChatPharoAgent class >> modelNames [

	self subclassResponsibility
]

{ #category : 'api' }
ChatPharoAgent class >> settingsPresenterFor: anAgent [

	^ nil
]

{ #category : 'accessing' }
ChatPharoAgent >> browserSystemPrompt [ 

        ^ browserSystemPrompt
]

{ #category : 'accessing' }
ChatPharoAgent >> browserSystemPrompt: aString [ 

        browserSystemPrompt := aString
]

{ #category : 'accessing' }
ChatPharoAgent >> configurationErrorMessage [

    ^ 'Agent is missing required settings.'
]

{ #category : 'accessing' }
ChatPharoAgent >> copyForChat [ 

    | clone |
    clone := self copy.
    clone history: ChatPharoHistory new.
    clone promptPrefix: ''.
    clone response: ''.
    ^ clone
]

{ #category : 'initialization' }
ChatPharoAgent >> customParameters [

	^ customParameters ifNil: [ customParameters := Dictionary new ]
]

{ #category : 'initialization' }
ChatPharoAgent >> customParameters: aDictionary [

	customParameters := aDictionary ifNil: [ Dictionary new ]
]

{ #category : 'initialization' }
ChatPharoAgent >> getResponseForPrompt: prompt [

	self subclassResponsibility
]

{ #category : 'accessing' }
ChatPharoAgent >> history [                     ^ history
]

{ #category : 'accessing' }
ChatPharoAgent >> history: aHistory [           history := aHistory
]

{ #category : 'initialization' }
ChatPharoAgent >> initialize [

	super initialize.
	model := ''.
	systemPrompt := self class defaultSystemPrompt.
	browserSystemPrompt := self class defaultBrowserSystemPrompt.
	promptPrefix := ''.
	response := ''.
	history := ChatPharoHistory new.
	onToolExecution := nil.
	maxTokens := nil.
	topP := nil.
	onRetry := nil.
	customParameters := Dictionary new
]

{ #category : 'accessing' }
ChatPharoAgent >> isConfigured [ 

    ^ true
]

{ #category : 'initialization' }
ChatPharoAgent >> maxTokens [

	^ maxTokens
]

{ #category : 'initialization' }
ChatPharoAgent >> maxTokens: anObject [

	maxTokens := anObject
]

{ #category : 'accessing' }
ChatPharoAgent >> model [

	^ model
]

{ #category : 'accessing' }
ChatPharoAgent >> model: anObject [

	model := anObject
]

{ #category : 'initialization' }
ChatPharoAgent >> modelInformation [ 

	self subclassResponsibility
]

{ #category : 'initialization' }
ChatPharoAgent >> onRetry [

        ^ onRetry
]

{ #category : 'initialization' }
ChatPharoAgent >> onRetry: aBlock [

        onRetry := aBlock
]

{ #category : 'accessing' }
ChatPharoAgent >> onToolExecution [ 

        ^ onToolExecution
]

{ #category : 'accessing' }
ChatPharoAgent >> onToolExecution: aBlock [ 

        onToolExecution := aBlock
]

{ #category : 'accessing' }
ChatPharoAgent >> promptPrefix [

	^ promptPrefix
]

{ #category : 'accessing' }
ChatPharoAgent >> promptPrefix: anObject [

	promptPrefix := anObject
]

{ #category : 'initialization' }
ChatPharoAgent >> requestParameters [

	| params |
	params := self customParameters copy.
	maxTokens ifNotNil: [ params at: 'max_tokens' put: maxTokens ].
	topP ifNotNil: [ params at: 'top_p' put: topP ].
	^ params
]

{ #category : 'accessing' }
ChatPharoAgent >> response [

	^ response
]

{ #category : 'accessing' }
ChatPharoAgent >> response: anObject [

	response := anObject
]

{ #category : 'accessing' }
ChatPharoAgent >> supportsThinkingContent [
	"Default: agents do not provide thinking content.
	Subclasses should override if they support it."
	
	^ false
]

{ #category : 'tools support' }
ChatPharoAgent >> supportsToolCalling [
	"Returns true if the current model supports tool/function calling.
	Subclasses may override to provide backend-specific detection.
	By default, most modern LLM backends support tool calling."

	^ true
]

{ #category : 'accessing' }
ChatPharoAgent >> systemPrompt [

	^ systemPrompt
]

{ #category : 'accessing' }
ChatPharoAgent >> systemPrompt: anObject [

	systemPrompt := anObject
]

{ #category : 'accessing' }
ChatPharoAgent >> testConnection [ 

        self subclassResponsibility
]

{ #category : 'initialization' }
ChatPharoAgent >> topP [

	^ topP
]

{ #category : 'initialization' }
ChatPharoAgent >> topP: anObject [

	topP := anObject
]

{ #category : 'accessing' }
ChatPharoAgent >> useAdapter: anAdapter [
    self model: anAdapter.
]
