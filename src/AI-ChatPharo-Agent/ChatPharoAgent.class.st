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
		'onToolExecution'
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
ChatPharoAgent >> copyForChat [ 

    | clone |
    clone := self copy.
    clone history: ChatPharoHistory new.
    clone promptPrefix: ''.
    clone response: ''.
    ^ clone
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
	systemPrompt := systemPrompt := self class defaultSystemPrompt.
	browserSystemPrompt := self class defaultBrowserSystemPrompt.
	promptPrefix := ''.
	response := ''.
	onToolExecution := nil
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

{ #category : 'accessing' }
ChatPharoAgent >> response [

	^ response
]

{ #category : 'accessing' }
ChatPharoAgent >> response: anObject [

	response := anObject
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

{ #category : 'accessing' }
ChatPharoAgent >> useAdapter: anAdapter [
    self model: anAdapter.
]
