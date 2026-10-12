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
		'fallbackModels'
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

{ #category : 'private - conversation' }
ChatPharoAgent >> answerTryingModels: modelNames from: historyMark [
	"Ask each model in turn until one answers. Only failures that another model can
	 plausibly avoid (usage limit reached, model missing) move on to the next one."

	| notes |
	notes := OrderedCollection new.
	modelNames allButLast do: [ :each |
		[ ^ self answerUsingModel: each notes: notes ]
			on: ChatPharoBackendError
			do: [ :error |
				error canFallBackToAnotherModel ifFalse: [ error pass ].
				self history truncateTo: historyMark.
				notes add: (self fallbackNoteFor: each because: error) ] ].
	^ self answerUsingModel: modelNames last notes: notes
]

{ #category : 'private - conversation' }
ChatPharoAgent >> answerUsingModel: aModelName notes: notes [

	| turn |
	turn := ChatPharoConversationTurn client: (self completionClientForModel: aModelName) history: self history.
	turn iterationLimit: self iterationLimit.
	notes do: [ :each | turn addNote: each ].
	response := turn run.
	model := aModelName.
	^ response content
]

{ #category : 'accessing' }
ChatPharoAgent >> browserSystemPrompt [ 

        ^ browserSystemPrompt
]

{ #category : 'accessing' }
ChatPharoAgent >> browserSystemPrompt: aString [ 

        browserSystemPrompt := aString
]

{ #category : 'private - conversation' }
ChatPharoAgent >> completionClientForModel: aModelName [

	| client |
	client := self newCompletionClient.
	aModelName ifNotEmpty: [ client model: aModelName ].
	client requestParameters: self completionParameters.
	client onToolExecution: onToolExecution.
	^ client
]

{ #category : 'private - conversation' }
ChatPharoAgent >> completionParameters [

	| parameters |
	parameters := self requestParameters copy.
	self temperature ifNotNil: [ :value | parameters at: 'temperature' put: value ].
	^ parameters
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

{ #category : 'private - conversation' }
ChatPharoAgent >> ensureBackendReady [
	"Hook: make sure my backend can answer before a request. Local runtimes start their server here."
]

{ #category : 'accessing' }
ChatPharoAgent >> fallbackModels [
	"Model names tried, in order, when the selected model hits a usage limit or is missing."

	^ fallbackModels ifNil: [ fallbackModels := OrderedCollection new ]
]

{ #category : 'accessing' }
ChatPharoAgent >> fallbackModels: aCollection [

	fallbackModels := aCollection asOrderedCollection
]

{ #category : 'private - conversation' }
ChatPharoAgent >> fallbackNoteFor: aModelName because: anError [

	| note |
	note := 'Model "{1}" could not answer ({2}). Trying the next fallback model.' format: {
			        aModelName.
			        anError messageText }.
	ChatPharoLogger logBackend: 'Model fallback' details: (Dictionary new
			 at: 'model' put: aModelName;
			 at: 'status' put: anError statusCode;
			 at: 'error' put: anError messageText;
			 yourself).
	^ note
]

{ #category : 'initialization' }
ChatPharoAgent >> getResponseForPrompt: userPrompt [
	"Answer the model's written reply to userPrompt, running the tool calls it asks for.
	 The full reply, with token usage and reasoning, stays available through #response.
	 A turn that fails or is cancelled leaves no half-finished tool exchange in the history."

	| historyMark |
	self ensureBackendReady.
	self history ensureEndsWithUser: userPrompt.
	historyMark := self history size.
	^ [ self answerTryingModels: self modelCandidates from: historyMark ] ifCurtailed: [
		  self history truncateTo: historyMark ]
]

{ #category : 'accessing' }
ChatPharoAgent >> history [

	^ history ifNil: [ history := ChatPharoHistory new ]
]

{ #category : 'accessing' }
ChatPharoAgent >> history: aHistory [

	history := aHistory
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
	customParameters := Dictionary new
]

{ #category : 'accessing' }
ChatPharoAgent >> isConfigured [ 

    ^ true
]

{ #category : 'private - conversation' }
ChatPharoAgent >> iterationLimit [

	^ ChatPharoSettings default maximumIterations ifNil: [ ChatPharoConversationTurn defaultIterationLimit ]
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

{ #category : 'private - conversation' }
ChatPharoAgent >> modelCandidates [
	"The selected model first, then the fallbacks, without repetition."

	^ (OrderedCollection with: model)
		  addAll: (self fallbackModels reject: [ :each | each = model ]);
		  yourself
]

{ #category : 'initialization' }
ChatPharoAgent >> modelInformation [ 

	self subclassResponsibility
]

{ #category : 'private - conversation' }
ChatPharoAgent >> newCompletionClient [
	"Answer a ChatPharoTool configured for my backend: URL, credentials, system prompt and tools."

	^ self subclassResponsibility
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
ChatPharoAgent >> packageName: aString [
	"Focus my system prompt on the package the user is browsing."

	self systemPrompt: (self browserSystemPrompt copyReplaceAll: '{packageName}' with: aString)
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
	"Reasoning is read from every OpenAI-style reply, whichever field or tag carries it."

	^ true
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
ChatPharoAgent >> temperature [
	"Backends that expose a temperature override this accessor."

	^ nil
]

{ #category : 'accessing' }
ChatPharoAgent >> testConnection [ 

        self subclassResponsibility
]

{ #category : 'tools support' }
ChatPharoAgent >> tools [
	"The tools offered to the model for this request."

	^ ChatPharoToolbox new enabledTools
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
