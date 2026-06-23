Class {
	#name : 'ChatPharoACPAgent',
	#superclass : 'Object',
	#instVars : [
		'name',
		'command',
		'arguments',
		'environment',
		'enabled',
		'acpClient',
		'acpSession'
	],
	#category : 'AI-ChatPharo-ACP',
	#package : 'AI-ChatPharo-ACP'
}

{ #category : 'accessing' }
ChatPharoACPAgent >> acpClient: anObject [

	acpClient := anObject
]

{ #category : 'accessing' }
ChatPharoACPAgent >> arguments [

	^ arguments
]

{ #category : 'accessing' }
ChatPharoACPAgent >> arguments: aCollection [

	arguments := aCollection
]

{ #category : 'accessing' }
ChatPharoACPAgent >> command [

	^ command
]

{ #category : 'accessing' }
ChatPharoACPAgent >> command: aString [

	command := aString
]

{ #category : 'accessing' }
ChatPharoACPAgent >> connect [

	acpClient ifNotNil: [ ^ self ].
	[
		acpClient := ACPClient new.
		ChatPharoLogger logSystem: 'ACP agent connected' details: (Dictionary new
				 at: 'agent' put: self name;
				 yourself) ]
		on: Error
		do: [ :error |
				acpClient := nil.
				acpSession := nil.
				ChatPharoLogger logSystem: 'ACP agent connection failed' details: (Dictionary new
						 at: 'agent' put: self name;
						 at: 'error' put: error messageText;
						 yourself) ]
]

{ #category : 'accessing' }
ChatPharoACPAgent >> disconnect [

	acpClient ifNil: [ ^ self ].
	[
		acpSession ifNotNil: [ acpSession close ].
		acpClient disconnect.
		acpClient := nil.
		acpSession := nil.
		ChatPharoLogger logSystem: 'ACP agent disconnected' details: (Dictionary new
				 at: 'agent' put: self name;
				 yourself) ]
		on: Error
		do: [ :error |
				ChatPharoLogger logSystem: 'ACP agent disconnect error' details: (Dictionary new
						 at: 'agent' put: self name;
						 at: 'error' put: error messageText;
						 yourself) ]
]

{ #category : 'accessing' }
ChatPharoACPAgent >> enabled [

	^ enabled ifNil: [ false ]
]

{ #category : 'accessing' }
ChatPharoACPAgent >> enabled: aBoolean [

	enabled := aBoolean
]

{ #category : 'initialization' }
ChatPharoACPAgent >> initialize [

	super initialize.
	enabled := true.
	arguments := OrderedCollection new.
	environment := Dictionary new
]

{ #category : 'accessing' }
ChatPharoACPAgent >> isConnected [

	^ acpClient isNotNil and: [ acpSession isNotNil ]
]

{ #category : 'accessing' }
ChatPharoACPAgent >> isDisconnected [

	^ self isConnected not
]

{ #category : 'accessing' }
ChatPharoACPAgent >> name [

	^ name
]

{ #category : 'accessing' }
ChatPharoACPAgent >> name: aString [

	name := aString
]
