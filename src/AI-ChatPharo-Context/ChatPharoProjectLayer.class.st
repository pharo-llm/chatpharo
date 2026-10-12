"
I am the **project context (automatic)**: the files, configuration and state of
what the user works on, read from the image without the user typing anything.

I describe the image and each Git repository that has a local clone: its
branch, where it lives on disk, and which of its packages have changes that
are not committed yet.

Iceberg and libgit are an external boundary: a repository whose clone was moved
or deleted answers errors instead of a branch. Such a repository is reported as
unavailable instead of breaking the whole prompt.
"
Class {
	#name : 'ChatPharoProjectLayer',
	#superclass : 'ChatPharoContextLayer',
	#category : 'AI-ChatPharo-Context',
	#package : 'AI-ChatPharo-Context'
}

{ #category : 'private' }
ChatPharoProjectLayer >> describeRepository: aRepository [

	^ String streamContents: [ :stream |
		  stream
			  nextPutAll: '- Repository ';
			  nextPutAll: aRepository name;
			  nextPutAll: ' on branch ';
			  nextPutAll: aRepository branchName;
			  nextPutAll: ' at ';
			  nextPutAll: aRepository location fullName.
		  (self modifiedPackageNamesOf: aRepository) ifNotEmpty: [ :names |
			  stream
				  nextPutAll: ' — uncommitted changes in: ';
				  nextPutAll: (', ' join: names) ] ]
]

{ #category : 'private' }
ChatPharoProjectLayer >> hasLocalClone: aRepository [

	^ aRepository location notNil and: [ aRepository location exists ]
]

{ #category : 'testing' }
ChatPharoProjectLayer >> isEnabled [

	^ self settings projectContextEnabled
]

{ #category : 'accessing' }
ChatPharoProjectLayer >> linesFor: aQueryString [

	^ (OrderedCollection with: '- Image: ' , Smalltalk image imageFile fullName)
		  addAll: self repositoryLines;
		  yourself
]

{ #category : 'private' }
ChatPharoProjectLayer >> modifiedPackageNamesOf: aRepository [

	^ (aRepository workingCopy modifiedPackages collect: [ :each | each name ]) asArray sorted
]

{ #category : 'private' }
ChatPharoProjectLayer >> repositories [

	^ IceRepository registry select: [ :each | self hasLocalClone: each ]
]

{ #category : 'private' }
ChatPharoProjectLayer >> repositoryLines [

	^ self repositories collect: [ :each |
		  [ self describeRepository: each ]
			  on: IceError , FileSystemError
			  do: [ :error | '- Repository ' , each name , ' (state unavailable: ' , error messageText , ')' ] ]
]

{ #category : 'accessing' }
ChatPharoProjectLayer >> title [

	^ 'Project context (automatic)'
]
