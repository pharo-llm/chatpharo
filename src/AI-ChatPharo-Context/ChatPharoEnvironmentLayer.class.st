"
I tell the model which ChatPharo, Pharo and platform it is running in.
The user can switch me off with Settings > ""Send environment metadata"".
"
Class {
	#name : 'ChatPharoEnvironmentLayer',
	#superclass : 'ChatPharoContextLayer',
	#category : 'AI-ChatPharo-Context',
	#package : 'AI-ChatPharo-Context'
}

{ #category : 'testing' }
ChatPharoEnvironmentLayer >> isEnabled [

	^ self settings metadataEnabled
]

{ #category : 'accessing' }
ChatPharoEnvironmentLayer >> linesFor: aQueryString [

	^ {
		  ('- ChatPharo version: ' , self settings chatPharoVersion).
		  ('- Pharo version: ' , SystemVersion current asString).
		  ('- Platform: ' , OSPlatform current name).
		  ('- Locale: ' , Locale current asString).
		  ('- Timestamp: ' , DateAndTime now asString) }
]

{ #category : 'accessing' }
ChatPharoEnvironmentLayer >> title [

	^ 'ChatPharo Environment'
]
