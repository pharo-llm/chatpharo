Class {
	#name : 'ChatPharoPlaygroundStub',
	#superclass : 'Object',
	#classVars : [
		'LastOpened'
	],
	#category : 'AI-ChatPharo-Tests-Mock',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Mock'
}

{ #category : 'instance creation' }
ChatPharoPlaygroundStub class >> lastOpened [ 
^ LastOpened 
]

{ #category : 'instance creation' }
ChatPharoPlaygroundStub class >> openContents: code [ 

    LastOpened := code
]

{ #category : 'instance creation' }
ChatPharoPlaygroundStub class >> reset [
	<script>
	LastOpened := nil 
]
