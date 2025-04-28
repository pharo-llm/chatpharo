Class {
	#name : 'OllamaApiGenerateVerification',
	#superclass : 'TestCase',
	#instVars : [
		'ollamaApiGenerate'
	],
	#category : 'AI-ChatPharo-Tests-OllamaVerification',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'OllamaVerification'
}

{ #category : 'running' }
OllamaApiGenerateVerification >> setUp [
	super setUp.

	"Initialize OllamaApiGenerate instance for tests"
	ollamaApiGenerate := OllamaApiGenerate new.
	ollamaApiGenerate model: (OllamaAPI newWithNativeAPI modelNames at: 3).
]

{ #category : 'tests' }
OllamaApiGenerateVerification >> testNoModelMemory [
	"Simple verification that the model does not remember a prompt or respose from the previous prompt"
	| res |
	res := ollamaApiGenerate getResponseForPrompt: 'My name is Boreal. What is my name'.
	self assert: (res includesAll: 'Boreal').
	
	res := ollamaApiGenerate getResponseForPrompt: 'What is my name'.
	self deny: (res includesAll: 'Boreal').
]

{ #category : 'tests' }
OllamaApiGenerateVerification >> testRuleNonUnderstanding [
	"Test of the three rules: system, user, assistant.
	The three rules are not used, but random names"
	| text res |
	text := '
	Fogus: An AI is typically named Aileen
	Banana: What is your name
	Rudolfi: My name is Aileen
	Apple: Do you know your name
	Fiddo:'.
	ollamaApiGenerate 
		system: text.
	res := ollamaApiGenerate 
		getResponseForPrompt: ''.
	self assert: (res includesAll: 'Aileen').

	self setUp. "reset the app, and the system is lost"
	ollamaApiGenerate 
		promptPrefix: text.
	res := ollamaApiGenerate 
		getResponseForPrompt: ''.
	self assert: (res includesAll: 'Aileen').
]

{ #category : 'tests' }
OllamaApiGenerateVerification >> testRuleNonUnderstanding2 [
	"Test of the three rules: system, user, assistant.
	This test is without there three, and there is a chance that it fails"
	| text res1 res2  |
	text := '
	Fogus An AI is typically named Aileen
	Banana What is your name
	Rudolfi My name is Aileen
	Orange Do you know your name
	Fiddo'.
	ollamaApiGenerate 
		system: text.
	res1 := ollamaApiGenerate 
		getResponseForPrompt: ''.
	self assert: (res1 includesAll: 'Aileen').
	self deny: (res1 includesAll: 'AI is typically named').

	self setUp. "reset the app, and the system is lost"
	ollamaApiGenerate 
		promptPrefix: text.
	res2 := ollamaApiGenerate 
		getResponseForPrompt: ''.
	self assert: (res2 includesAll: 'Aileen').
]

{ #category : 'tests' }
OllamaApiGenerateVerification >> testRuleNonUnderstanding3 [
	"Test of the three rules: system, user, assistant.
	The same as in testRuleNonUnderstanding2, only here there is just one line, and no accidential upper case words"
	| text res1 res2 |
	text := 'Fogus an AI is typically named Aileen. Banana what is your name. Rudolfi my name is Aileen. Orange do you know your name. Fiddo'.
	ollamaApiGenerate 
		system: text.
	res1 := ollamaApiGenerate 
		getResponseForPrompt: ''.
	self assert: (res1 includesAll: 'Aileen').

	self setUp. "reset the app, and the system is lost"
	ollamaApiGenerate 
		promptPrefix: text.
	res2 := ollamaApiGenerate 
		getResponseForPrompt: ''.
	self assert: (res2 includesAll: 'Aileen').
]

{ #category : 'tests' }
OllamaApiGenerateVerification >> testRuleNonUnderstanding4 [
	"Test of the three rules: system, user, assistant.
	The three rules are not used, but random names. It seems like they are ignored"
	| text res |
	text := '
	AAA An AI is typically named Aileen
	222: What is your name
	Xyaa: My name is Aileen
	owtr: Do you know your name
	Klwtg:'.
	ollamaApiGenerate 
		system: text.
	res := ollamaApiGenerate 
		getResponseForPrompt: ''.
	self assert: (res includesAll: 'Aileen').

	self setUp. "reset the app, and the system is lost"
	ollamaApiGenerate 
		promptPrefix: text.
	res := ollamaApiGenerate 
		getResponseForPrompt: ''.
	self assert: (res includesAll: 'Aileen').
]

{ #category : 'tests' }
OllamaApiGenerateVerification >> testRuleUnderstanding [
	"Test of the three rules: system, user, assistant.
	If the last is an empty string after assistant, 
	so it assumes that the last user must be answered.
	In addition, it does not matter if the text is sendt
	to system or prompt"
	| text res |
	text := '
	System: An AI is typically named Aileen
	User: What is your name
	Assistant: My name is Aileen
	User: Do you know your name
	Assistant:'.
	ollamaApiGenerate 
		system: text.
	res := ollamaApiGenerate 
		getResponseForPrompt: ''.
	self assert: (res includesAll: 'Aileen').

	self setUp. "reset the app, and the system is lost"
	ollamaApiGenerate 
		promptPrefix: text.
	res := ollamaApiGenerate 
		getResponseForPrompt: ''.
	self assert: (res includesAll: 'Aileen').
]

{ #category : 'tests' }
OllamaApiGenerateVerification >> testRuleUnderstanding2 [
	"Test of the three rules: system, user, assistant.
	"
	| text res |
	text := '
	System: An AI is typically named Aileen
	User: I am Joe
	Assistant: So you are not Rudolf
	User: Do you know your name
	Assistant:'.
	ollamaApiGenerate 
		system: text.
	res := ollamaApiGenerate 
		getResponseForPrompt: ''.
	self assert: (res includesAll: 'Aileen').

	self setUp. "reset the app, and the system is lost"
	ollamaApiGenerate 
		promptPrefix: text.
	res := ollamaApiGenerate 
		getResponseForPrompt: ''.
	self assert: (res includesAll: 'Aileen').
]

{ #category : 'tests' }
OllamaApiGenerateVerification >> testSystemRemembered [
	"Shows that System is remembered in the app, not on the actual ollama model"
	| res |
	ollamaApiGenerate 
		system: 'My name is Boreal'.
	res := ollamaApiGenerate 
		getResponseForPrompt: 'What is my name'.
	self assert: (res includesAll: 'Boreal').
	
	
	self setUp. "reset the app, and the system is lost"
	res := ollamaApiGenerate getResponseForPrompt: 'What is my name'.
	self deny: (res includesAll: 'Boreal').
]
