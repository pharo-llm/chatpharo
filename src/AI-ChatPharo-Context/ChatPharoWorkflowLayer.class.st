"
I tell the model **how to work with this user**: plan first, execute only what
was validated, and adapt when a tool call is refused.

A tool description says what a tool does; it does not say when the user expects
it to be used. Without me a model changes the image right away and treats a
refusal as a transient error to retry.
"
Class {
	#name : 'ChatPharoWorkflowLayer',
	#superclass : 'ChatPharoContextLayer',
	#category : 'AI-ChatPharo-Context',
	#package : 'AI-ChatPharo-Context'
}

{ #category : 'testing' }
ChatPharoWorkflowLayer >> isEnabled [

	^ self settings planValidationEnabled and: [ self settings browserToolsEnabled includes: 'propose_plan' ]
]

{ #category : 'accessing' }
ChatPharoWorkflowLayer >> linesFor: aQueryString [

	^ #( '- For a task that needs several actions or changes the image, first call propose_plan with short concrete steps. The user validates each step.'
	     '- Execute approved steps only, in order, and report each with update_plan_step (in_progress, then done or failed).'
	     '- Questions, explanations and single read-only lookups need no plan: answer directly.'
	     '- When a tool call is refused, its result carries the reason of the user. Do not retry the same call: adapt, or ask what they prefer.' )
]

{ #category : 'accessing' }
ChatPharoWorkflowLayer >> title [

	^ 'How to work with this user'
]
