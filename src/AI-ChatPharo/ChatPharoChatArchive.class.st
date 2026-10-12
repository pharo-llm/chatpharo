"
I keep conversations on disk so they survive what an in-memory chat does not:
closing the ChatPharo window, restarting the image, or pulling a new version of
ChatPharo.

Each chat is one JSON file in my directory, named after the chat's id:

	{ ""id"": …, ""title"": …, ""messages"": [ OpenAI-style messages ] }

The messages are the LLM history, tool calls and results included, so a
restored chat is not just readable: the model continues it with full context.

`ChatPharo default` restores my chats when it is created, which is how history
is fed into the chats before the first window opens.

```smalltalk
ChatPharoChatArchive default savedChats
```
"
Class {
	#name : 'ChatPharoChatArchive',
	#superclass : 'Object',
	#instVars : [
		'directory'
	],
	#category : 'AI-ChatPharo',
	#package : 'AI-ChatPharo'
}

{ #category : 'instance creation' }
ChatPharoChatArchive class >> default [

	^ self directory: ChatPharoSettings settingsDirectory / 'chats'
]

{ #category : 'instance creation' }
ChatPharoChatArchive class >> directory: aFileReference [

	^ self new
		  setDirectory: aFileReference;
		  yourself
]

{ #category : 'private' }
ChatPharoChatArchive >> chatFromFile: aFileReference [
	"Answer the chat stored in aFileReference, or nil when the file is not a readable chat."

	| entry |
	entry := [ STONJSON fromString: aFileReference contents ]
		         on: STONReaderError
		         do: [ :error |
			         ChatPharoLogger logSystem: 'Unreadable chat file skipped' details: (Dictionary
					          with: 'file' -> aFileReference fullName
					          with: 'error' -> error messageText).
			         ^ nil ].
	^ ChatPharoChat fromArchiveEntry: entry
]

{ #category : 'private' }
ChatPharoChatArchive >> chatFiles [
	"Oldest first, so restored tabs keep the order in which the chats were last used."

	directory exists ifFalse: [ ^ #(  ) ].
	^ (directory filesMatching: '*.json') sorted: [ :a :b | a modificationTime <= b modificationTime ]
]

{ #category : 'accessing' }
ChatPharoChatArchive >> directory [

	^ directory
]

{ #category : 'private' }
ChatPharoChatArchive >> fileFor: aChat [

	^ directory / (aChat id , '.json')
]

{ #category : 'accessing' }
ChatPharoChatArchive >> maximumRestoredChats [

	^ 20
]

{ #category : 'removing' }
ChatPharoChatArchive >> remove: aChat [

	(self fileFor: aChat) deleteIfAbsent: [  ]
]

{ #category : 'saving' }
ChatPharoChatArchive >> save: aChat [
	"Write aChat to disk. A chat nobody wrote in yet is not worth a file."

	aChat hasConversation ifFalse: [ ^ self ].
	directory ensureCreateDirectory.
	(self fileFor: aChat)
		ensureDelete;
		writeStreamDo: [ :stream | stream nextPutAll: (STONJSON toString: aChat archiveEntry) ]
]

{ #category : 'accessing' }
ChatPharoChatArchive >> savedChats [
	"The most recently used chats, each bound to me so that it keeps saving itself."

	| files |
	files := self chatFiles.
	^ ((files last: (self maximumRestoredChats min: files size))
		   collect: [ :each | self chatFromFile: each ]
		   thenReject: [ :each | each isNil ]) collect: [ :each |
		  each
			  archive: self;
			  yourself ]
]

{ #category : 'initialization' }
ChatPharoChatArchive >> setDirectory: aFileReference [

	directory := aFileReference
]
