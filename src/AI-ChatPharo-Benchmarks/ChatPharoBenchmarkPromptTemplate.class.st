"
Responsible for turning a `ChatPharoBenchmarkCase` into the final prompt
string we send to the LLM.

Why a separate class? Because the *exact* wording of the prompt is a variable
in any honest benchmark. Want to compare two prompting strategies? Swap
templates. Want a more constrained prompt for rawLLM (so it can't be ""helped""
by conversational wandering)? Same class, different template.

The default template is deliberately minimalistic: it gives the LLM the
class's structural context and asks for a single Pharo method body inside a
```smalltalk …``` block. The code extractor later pulls the block out.

Place-holders supported in the template string:
  `{className}`, `{superclassName}`, `{selector}`, `{protocol}`,
  `{instanceVariableNames}`, `{classComment}`, `{goldSource}` (for
  explanation-kind cases only).
"
Class {
	#name : 'ChatPharoBenchmarkPromptTemplate',
	#superclass : 'Object',
	#instVars : [
		'methodGenerationTemplate',
		'methodExplanationTemplate',
		'classGenerationTemplate',
		'snippetCompletionTemplate'
	],
	#category : 'AI-ChatPharo-Benchmarks',
	#package : 'AI-ChatPharo-Benchmarks',
	#tag : 'Runner'
}

{ #category : 'accessing' }
ChatPharoBenchmarkPromptTemplate class >> default [

	^ self new
]

{ #category : 'defaults' }
ChatPharoBenchmarkPromptTemplate >> defaultClassGenerationTemplate [

	^ 'You are writing Pharo Smalltalk.

Generate the class definition for **{className}** with superclass **{superclassName}**.

Class responsibility (from the original class comment):
{classComment}

Instance variables expected: {instanceVariableNames}

Respond with a single fenced code block containing the class definition in Tonel / Pharo syntax. Do not include methods.

```smalltalk
```'
]

{ #category : 'defaults' }
ChatPharoBenchmarkPromptTemplate >> defaultMethodExplanationTemplate [

	^ 'Explain, in a short paragraph, what the following Pharo Smalltalk method does.
Do not rewrite the code.

Class: {className} (superclass: {superclassName})
Selector: {selector}
Protocol: {protocol}

```smalltalk
{goldSource}
```'
]

{ #category : 'defaults' }
ChatPharoBenchmarkPromptTemplate >> defaultMethodGenerationTemplate [

	^ 'You are writing Pharo Smalltalk. Implement the method below.

Class: {className}
Superclass: {superclassName}
Instance variables: {instanceVariableNames}
Protocol: {protocol}
Selector: {selector}

Class responsibility (from the original class comment, trimmed):
{classComment}

Constraints:
- Output ONE Pharo method, starting with its message pattern (no class-side braces).
- Do NOT wrap it in a method category declaration.
- Respond with EXACTLY one fenced code block and nothing else:

```smalltalk
<your method here>
```'
]

{ #category : 'defaults' }
ChatPharoBenchmarkPromptTemplate >> defaultSnippetCompletionTemplate [

	^ 'Complete the following Pharo Smalltalk code. Respond with a single fenced code block.

```smalltalk
{goldSource}
```'
]

{ #category : 'initialization' }
ChatPharoBenchmarkPromptTemplate >> initialize [

	super initialize.
	methodGenerationTemplate := self defaultMethodGenerationTemplate.
	methodExplanationTemplate := self defaultMethodExplanationTemplate.
	classGenerationTemplate := self defaultClassGenerationTemplate.
	snippetCompletionTemplate := self defaultSnippetCompletionTemplate
]

{ #category : 'accessing' }
ChatPharoBenchmarkPromptTemplate >> methodExplanationTemplate [

	^ methodExplanationTemplate
]

{ #category : 'accessing' }
ChatPharoBenchmarkPromptTemplate >> methodExplanationTemplate: aString [

	methodExplanationTemplate := aString
]

{ #category : 'accessing' }
ChatPharoBenchmarkPromptTemplate >> methodGenerationTemplate [

	^ methodGenerationTemplate
]

{ #category : 'accessing' }
ChatPharoBenchmarkPromptTemplate >> methodGenerationTemplate: aString [

	methodGenerationTemplate := aString
]

{ #category : 'private' }
ChatPharoBenchmarkPromptTemplate >> render: templateString for: aCase [

	| result ivars |
	result := templateString.
	ivars := (aCase instanceVariableNames ifNil: [ #(  ) ])
		         inject: ''
		         into: [ :acc :name |
		         acc isEmpty
			         ifTrue: [ name ]
			         ifFalse: [ acc , ' ' , name ] ].
	result := result copyReplaceAll: '{className}' with: (aCase className ifNil: [ '?' ]).
	result := result copyReplaceAll: '{superclassName}' with: (aCase superclassName ifNil: [ 'Object' ]).
	result := result copyReplaceAll: '{selector}' with: (aCase selector ifNil: [ '' ]).
	result := result copyReplaceAll: '{protocol}' with: (aCase protocol ifNil: [ 'accessing' ]).
	result := result copyReplaceAll: '{instanceVariableNames}' with: ivars.
	result := result copyReplaceAll: '{classComment}' with: (aCase classComment ifNil: [ '' ]).
	result := result copyReplaceAll: '{goldSource}' with: (aCase goldSource ifNil: [ '' ]).
	^ result
]

{ #category : 'rendering' }
ChatPharoBenchmarkPromptTemplate >> renderFor: aCase [
	"Pick the right template based on case kind and expand placeholders."

	| template |
	template := aCase kind = #methodGeneration ifTrue: [ methodGenerationTemplate ]
		            ifFalse: [
			            aCase kind = #methodExplanation ifTrue: [ methodExplanationTemplate ]
				            ifFalse: [
					            aCase kind = #classGeneration ifTrue: [ classGenerationTemplate ]
						            ifFalse: [ snippetCompletionTemplate ] ] ].
	^ self render: template for: aCase
]
