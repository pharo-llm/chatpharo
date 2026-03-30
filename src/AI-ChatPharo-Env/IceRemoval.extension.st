Extension { #name : 'IceRemoval' }

{ #category : '*AI-ChatPharo-Env' }
IceRemoval >> printOnLLMQuery: aWriteStream [

	aWriteStream
		<< 'removal';
		<< String lf.
	aWriteStream << self leftContents
]
