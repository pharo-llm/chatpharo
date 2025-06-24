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

{ #category : 'initialization' }
ChatPharoMistralAgent >> getResponseForPrompt: prompt [

	        | api result |
        api := ChatPharoTool
                       mistralWithAPIKey: apiKey
                       system: self systemPrompt
                       tools: self tools.
        model ifNotEmpty: [ api model: model ].
        self history ifNil: [ self history: ChatPharoHistory new ].
        self history addMessage:
                (ChatPharoHistorySaver role: 'user' content: prompt).

        result := api getResponseForHistory: self history.
        self history addMessage: result.

       [ result toolCalls notNil ] whileTrue: [
               result := api getResponseForHistory: self history.
               self history addMessage: result ].

        ^ result content
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
        temperature := 0.7
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

{ #category : 'accessing' }
ChatPharoMistralAgent >> tools [ 

    | available |
    available := ChatPharoBrowserEnvironment new tools.
    ^ available select: [ :tool |
        ChatPharoSettings default browserToolsEnabled includes: tool name ]
]
