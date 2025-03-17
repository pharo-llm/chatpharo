"
Base class and specific implementations for different models used in API interactions.

•	fullName: Constructs the full name of the model for API requests.
•	name: Abstract method to return the model's name, implemented by subclasses.
"
Class {
	#name : 'OQwen2Model',
	#superclass : 'OModel',
	#category : 'AI-ChatPharo-API',
	#package : 'AI-ChatPharo',
	#tag : 'API'
}

{ #category : 'accessing' }
OQwen2Model class >> b7 [
	<ollamaInit: 'qwen2:7b'>
	^ self new
		tag: '7b';
		yourself
]

{ #category : 'accessing' }
OQwen2Model class >> b72 [
	<ollamaInit: 'qwen2:72b'>
	^ self new
		tag: '72b';
		yourself
]

{ #category : 'accessing' }
OQwen2Model >> name [
	^ 'qwen2'
]
