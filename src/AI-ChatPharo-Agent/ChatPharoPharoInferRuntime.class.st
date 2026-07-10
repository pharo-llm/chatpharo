"
I locate and prepare the native PharoInfer runtime used by the local llama.cpp
backend.
"
Class {
	#name : 'ChatPharoPharoInferRuntime',
	#superclass : 'Object',
	#category : 'AI-ChatPharo-Agent',
	#package : 'AI-ChatPharo-Agent'
}

{ #category : 'building' }
ChatPharoPharoInferRuntime class >> buildCommandFor: scriptFile installInto: installDirectory [

	self isWindows ifTrue: [
		^ 'set "INSTALL_DIR=' , installDirectory fullName , '" && sh '
		  , (self windowsQuote: scriptFile fullName) ].
	^ 'INSTALL_DIR=' , (self shellQuote: installDirectory fullName) , ' sh '
	  , (self shellQuote: scriptFile fullName)
]

{ #category : 'building' }
ChatPharoPharoInferRuntime class >> buildScript [

	^ self buildScriptCandidates
		  detect: [ :candidate | candidate exists ]
		  ifNone: [ nil ]
]

{ #category : 'building' }
ChatPharoPharoInferRuntime class >> buildScriptCandidates [

	| candidates environmentDirectory imageDirectory parentDirectory |
	candidates := OrderedCollection new.

	environmentDirectory := self environmentPharoInferDirectory.
	environmentDirectory ifNotNil: [
		candidates add: environmentDirectory / 'scripts' / 'build-native.sh' ].

	imageDirectory := FileLocator imageDirectory.
	candidates add: imageDirectory / 'pharo-infer' / 'scripts' / 'build-native.sh'.
	candidates add: imageDirectory / 'scripts' / 'build-native.sh'.

	parentDirectory := [ imageDirectory parent ] on: Error do: [ nil ].
	parentDirectory ifNotNil: [
		candidates add: parentDirectory / 'pharo-infer' / 'scripts' / 'build-native.sh' ].

	candidates add: FileLocator home / 'pharo-infer' / 'scripts' / 'build-native.sh'.
	^ candidates
]

{ #category : 'configuration' }
ChatPharoPharoInferRuntime class >> configureInstalledLibrary [

	self installedLibrary ifNotNil: [ :library |
		self configureLibraryPath: library.
		^ true ].
	^ false
]

{ #category : 'configuration' }
ChatPharoPharoInferRuntime class >> configureLibraryPath: aFileReference [

	| libraryClass |
	libraryClass := Smalltalk at: #AILlamaLibrary ifAbsent: [ nil ].
	libraryClass ifNotNil: [ libraryClass libraryPath: aFileReference fullName ].
	^ aFileReference
]

{ #category : 'platform' }
ChatPharoPharoInferRuntime class >> currentLibraryFileName [

	| osPlatform platformName |
	osPlatform := Smalltalk at: #OSPlatform ifAbsent: [ nil ].
	osPlatform ifNil: [ ^ 'libai_llama.so' ].
	platformName := osPlatform current name asLowercase.
	((platformName includesSubstring: 'win') or: [
		 platformName includesSubstring: 'mingw' ]) ifTrue: [ ^ 'ai_llama.dll' ].
	((platformName includesSubstring: 'mac') or: [
		 platformName includesSubstring: 'darwin' ]) ifTrue: [ ^ 'libai_llama.dylib' ].
	^ 'libai_llama.so'
]

{ #category : 'building' }
ChatPharoPharoInferRuntime class >> ensureReady [

	^ self ensureReadyWithProgressDo: [ :message :progress | ]
]

{ #category : 'building' }
ChatPharoPharoInferRuntime class >> ensureReadyWithProgressDo: progressBlock [

	| library script buildSucceeded |
	progressBlock value: 'Checking PharoInfer native runtime.' value: 0.1.
	library := self installedLibrary.
	library ifNotNil: [
		self configureLibraryPath: library.
		progressBlock value: 'PharoInfer native runtime is ready.' value: 1.0.
		^ true ].

	script := self buildScript.
	script ifNil: [
		progressBlock
			value: 'PharoInfer native runtime is missing and no build script was found.'
			value: 1.0.
		^ false ].

	progressBlock
		value: 'Building PharoInfer native runtime for this image. This can take a few minutes.'
		value: 0.25.
	buildSucceeded := self runBuildScript: script progress: progressBlock.
	buildSucceeded ifFalse: [ ^ false ].

	library := self installedLibrary.
	library ifNil: [
		progressBlock
			value: 'PharoInfer native build finished, but the runtime library was not found.'
			value: 1.0.
		^ false ].

	self configureLibraryPath: library.
	progressBlock value: 'PharoInfer native runtime is ready.' value: 1.0.
	^ true
]

{ #category : 'building' }
ChatPharoPharoInferRuntime class >> environmentPharoInferDirectory [

	| osPlatform path |
	osPlatform := Smalltalk at: #OSPlatform ifAbsent: [ ^ nil ].
	path := osPlatform current environment
		        at: 'PHARO_INFER_DIR'
		        ifAbsent: [ nil ].
	(path isNil or: [ path asString isEmpty ]) ifTrue: [ ^ nil ].
	^ path asString asFileReference
]

{ #category : 'configuration' }
ChatPharoPharoInferRuntime class >> installedLibrary [

	| fileName |
	fileName := self currentLibraryFileName.
	self runtimeDirectories do: [ :directory |
		| candidate |
		candidate := directory / fileName.
		candidate exists ifTrue: [ ^ candidate ] ].
	^ nil
]

{ #category : 'testing' }
ChatPharoPharoInferRuntime class >> isReady [

	^ self installedLibrary notNil
]

{ #category : 'platform' }
ChatPharoPharoInferRuntime class >> isWindows [

	^ self currentLibraryFileName = 'ai_llama.dll'
]

{ #category : 'building' }
ChatPharoPharoInferRuntime class >> runBuildScript: scriptFile progress: progressBlock [

	| libc installDirectory command status |
	libc := Smalltalk at: #LibC ifAbsent: [ nil ].
	libc ifNil: [
		progressBlock
			value: 'Cannot build PharoInfer native runtime because LibC is not available.'
			value: 1.0.
		^ false ].

	installDirectory := self runtimeInstallDirectory.
	command := self buildCommandFor: scriptFile installInto: installDirectory.
	[
		status := libc uniqueInstance system: command ]
		on: Error
		do: [ :ex |
			progressBlock
				value: ('PharoInfer native build failed: ' , ex description)
				value: 1.0.
			^ false ].

	status = 0 ifFalse: [
		progressBlock
			value: 'PharoInfer native build failed. Check CMake, git, and compiler availability.'
			value: 1.0.
		^ false ].
	^ true
]

{ #category : 'configuration' }
ChatPharoPharoInferRuntime class >> runtimeDirectories [

	^ {
		  FileLocator imageDirectory / 'pharo-infer-native' / 'lib'.
		  FileLocator home / 'pharo-infer-native' / 'lib' }
]

{ #category : 'configuration' }
ChatPharoPharoInferRuntime class >> runtimeInstallDirectory [

	| imageInstall |
	imageInstall := FileLocator imageDirectory / 'pharo-infer-native'.
	^ [ 
	  imageInstall ensureCreateDirectory.
	  imageInstall ]
		  on: Error
		  do: [ FileLocator home / 'pharo-infer-native' ]
]

{ #category : 'building' }
ChatPharoPharoInferRuntime class >> shellQuote: aString [

	(aString includes: $') ifTrue: [
		self error: 'Cannot shell-quote a path containing a single quote: ' , aString ].
	^ '''' , aString , ''''
]

{ #category : 'status' }
ChatPharoPharoInferRuntime class >> shouldPrepareAtStartup [

	^ self isReady not and: [ self buildScript notNil ]
]

{ #category : 'status' }
ChatPharoPharoInferRuntime class >> statusText [

	self installedLibrary ifNotNil: [ :library |
		^ 'Native runtime ready: ' , library fullName ].
	self buildScript ifNotNil: [ :script |
		^ 'Native runtime missing. Build script found: ' , script fullName ].
	^ 'Native runtime missing. Install a platform release zip or set PHARO_INFER_DIR to a pharo-infer checkout.'
]

{ #category : 'building' }
ChatPharoPharoInferRuntime class >> windowsQuote: aString [

	(aString includes: $") ifTrue: [
		self error: 'Cannot quote a Windows path containing a double quote: ' , aString ].
	^ '"' , aString , '"'
]
