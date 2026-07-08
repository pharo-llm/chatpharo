"
Groq Cloud agent backend.

Groq Cloud exposes an OpenAI-compatible API at
`https://api.groq.com/openai/v1`, so this class only supplies the provider
defaults and display metadata while reusing `ChatPharoOpenAIAgent` request
handling.
"
Class {
	#name : 'ChatPharoGroqAgent',
	#superclass : 'ChatPharoOpenAIAgent',
	#category : 'AI-ChatPharo-Agent',
	#package : 'AI-ChatPharo-Agent'
}

{ #category : 'api' }
ChatPharoGroqAgent class >> displayName [

	^ 'Groq Cloud'
]

{ #category : 'api' }
ChatPharoGroqAgent class >> isReachable [

	^ [
		  ZnClient new head: 'https://api.groq.com'.
		  true ]
		  on: ZnHttpUnsuccessful , NetworkError
		  do: [ false ]
]

{ #category : 'accessing' }
ChatPharoGroqAgent >> apiKeyPlaceholder [

	^ 'GROQ_API_KEY'
]

{ #category : 'accessing' }
ChatPharoGroqAgent >> hostPlaceholder [

	^ 'https://api.groq.com/openai/v1'
]

{ #category : 'accessing' }
ChatPharoGroqAgent >> initialize [

	super initialize.
	host := 'https://api.groq.com/openai/v1'.
	model := ''
]

{ #category : 'accessing' }
ChatPharoGroqAgent >> modelInformation [

	^ 'Groq Cloud agent. Requires an API key from https://console.groq.com/keys'
]
