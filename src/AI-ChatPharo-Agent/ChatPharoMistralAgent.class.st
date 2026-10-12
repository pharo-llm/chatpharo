"
Not uspported yet
"
Class {
	#name : 'ChatPharoMistralAgent',
	#superclass : 'ChatPharoAgent',
	#instVars : [
		'host',
		'apiKey',
		'temperature',
		'packageName'
	],
	#category : 'AI-ChatPharo-Agent',
	#package : 'AI-ChatPharo-Agent'
}

{ #category : 'api' }
ChatPharoMistralAgent class >> displayName [
	
	^ 'Mistral AI'	
]

{ #category : 'api' }
ChatPharoMistralAgent class >> isReachable [ 

    ^ [ ZnClient new head: 'https://api.mistral.ai/v1/models'. true ]
        on: NetworkError do: [ false ]

]

{ #category : 'api' }
ChatPharoMistralAgent class >> modelNames [ 

    ^ #( 'Enter your API-Key' )
]

{ #category : 'api' }
ChatPharoMistralAgent class >> settingsPresenterFor: anAgent [ 

    ^ ChatPharoMistralSettingsPresenter on: anAgent
]

{ #category : 'accessing' }
ChatPharoMistralAgent >> apiKey [

	^ apiKey
]

{ #category : 'accessing' }
ChatPharoMistralAgent >> apiKey: anObject [ 


        apiKey := anObject.
        ChatPharoSettings saveDefault
]

{ #category : 'accessing' }
ChatPharoMistralAgent >> configurationErrorMessage [

	^ 'Please complete all required fields.'
]

{ #category : 'accessing' }
ChatPharoMistralAgent >> host [

	^ host
]

{ #category : 'accessing' }
ChatPharoMistralAgent >> host: anObject [

	host := anObject
]

{ #category : 'accessing' }
ChatPharoMistralAgent >> initialize [ 


        super initialize.
        host := 'api.mistral.ai'.
        apiKey := ''.
        model := ''.
        temperature := nil
]

{ #category : 'accessing' }
ChatPharoMistralAgent >> isConfigured [

	^ host notEmpty and: [ apiKey notEmpty and: [ model notEmpty ] ]
]

{ #category : 'initialization' }
ChatPharoMistralAgent >> modelInformation [
	^ self shouldBeImplemented
]

{ #category : 'accessing' }
ChatPharoMistralAgent >> modelNames [ 

        apiKey isEmpty ifTrue: [ ^ self class modelNames ].

        ^ [
                (ChatPharoTool
                        mistralWithAPIKey: apiKey
                        system: nil) modelNames
        ] on: Error do: [ self class modelNames ]
]

{ #category : 'private - conversation' }
ChatPharoMistralAgent >> newCompletionClient [

	^ ChatPharoTool mistralWithAPIKey: apiKey system: self systemPrompt tools: self tools
]

{ #category : 'accessing' }
ChatPharoMistralAgent >> packageName [

	^ packageName
]

{ #category : 'accessing' }
ChatPharoMistralAgent >> packageName: aString [ 

        packageName := aString.
        self systemPrompt: (ChatPharoAgent defaultBrowserSystemPrompt
                         copyReplaceAll: '{packageName}'
                         with: packageName)
]

{ #category : 'tools support' }
ChatPharoMistralAgent >> supportsToolCalling [
	"Check if the current Mistral model supports tool calling.
	Most Mistral models support function calling, except embedding models."

	| modelLower nonToolModels |
	model ifEmpty: [ ^ false ].
	self isConfigured ifFalse: [ ^ false ].

	modelLower := model asLowercase.

	"Models that don't support tool calling"
	nonToolModels := #( 'embed' 'moderation' ).
	(nonToolModels anySatisfy: [ :pattern |
		 modelLower includesSubstring: pattern ]) ifTrue: [ ^ false ].

	"All other Mistral models support tool calling"
	^ true
]

{ #category : 'accessing' }
ChatPharoMistralAgent >> temperature [

	^ temperature
]

{ #category : 'accessing' }
ChatPharoMistralAgent >> temperature: anObject [

	temperature := anObject
]

{ #category : 'accessing' }
ChatPharoMistralAgent >> testConnection [ 
^ [  
                | url client |
                url := 'https://' , host , '/v1/models'.
                client := ZnClient new url: url.
                apiKey ifNotEmpty: [ client setBearerAuthentication: apiKey ].
                client head.
                true ]
                on: ZnHttpUnsuccessful , NetworkError
                do: [ false ]
]
