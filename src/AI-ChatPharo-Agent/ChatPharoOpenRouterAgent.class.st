"
OpenRouter agent backend.

OpenRouter exposes an OpenAI-compatible API at `https://openrouter.ai/api/v1`,
so this class only supplies the provider defaults and display metadata while
reusing `ChatPharoOpenAIAgent` request handling.
"
Class {
	#name : 'ChatPharoOpenRouterAgent',
	#superclass : 'ChatPharoOpenAIAgent',
	#category : 'AI-ChatPharo-Agent',
	#package : 'AI-ChatPharo-Agent'
}

{ #category : 'api' }
ChatPharoOpenRouterAgent class >> displayName [

	^ 'OpenRouter'
]

{ #category : 'api' }
ChatPharoOpenRouterAgent class >> isReachable [

	^ [
		  ZnClient new head: 'https://openrouter.ai'.
		  true ]
		  on: ZnHttpUnsuccessful , NetworkError
		  do: [ false ]
]

{ #category : 'accessing' }
ChatPharoOpenRouterAgent >> apiKeyPlaceholder [

	^ 'OPENROUTER_API_KEY'
]

{ #category : 'accessing' }
ChatPharoOpenRouterAgent >> hostPlaceholder [

	^ 'https://openrouter.ai/api/v1'
]

{ #category : 'accessing' }
ChatPharoOpenRouterAgent >> initialize [

	super initialize.
	host := 'https://openrouter.ai/api/v1'.
	model := ''
]

{ #category : 'accessing' }
ChatPharoOpenRouterAgent >> modelInformation [

	^ 'OpenRouter agent. Requires an API key from https://openrouter.ai/keys'
]
