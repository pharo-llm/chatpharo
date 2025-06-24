Class {
	#name : 'ChatPharoBrowserEnvironmentTest',
	#superclass : 'TestCase',
	#instVars : [
		'env'
	],
	#category : 'AI-ChatPharo-Tests-Env',
	#package : 'AI-ChatPharo-Tests',
	#tag : 'Env'
}

{ #category : 'running' }
ChatPharoBrowserEnvironmentTest >> setUp [ 
   super setUp.
   env := ChatPharoBrowserEnvironment new.

]

{ #category : 'running' }
ChatPharoBrowserEnvironmentTest >> testClassLookupIsCaseInsensitive [ 

   self assert: (env classNamed: 'string') == String.
]

{ #category : 'running' }
ChatPharoBrowserEnvironmentTest >> testFindMethodsWithSubstringCapsAt50 [ 

   | reply |
   reply := env applyFunctionFindMethodsWithSubstring:
               (Dictionary with:'substring'->'initialize').
   self assert: (reply at:'methods') size <= 50.
]

{ #category : 'running' }
ChatPharoBrowserEnvironmentTest >> testGetPackagesIncludesSelfPackage [ 

   | reply |
   reply := env applyFunctionGetPackages: Dictionary new.
   self assert: ((reply at:'packages') includes: 'AI-ChatPharo').
]
