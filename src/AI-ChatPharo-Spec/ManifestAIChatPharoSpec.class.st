"
Please describe the package using the class comment of the included manifest class. The manifest class also includes other additional metadata for the package. These meta data are used by other tools such as the SmalllintManifestChecker and the critics Browser
"
Class {
	#name : 'ManifestAIChatPharoSpec',
	#superclass : 'PackageManifest',
	#category : 'AI-ChatPharo-Spec-Manifest',
	#package : 'AI-ChatPharo-Spec',
	#tag : 'Manifest'
}

{ #category : 'code-critics' }
ManifestAIChatPharoSpec class >> ruleDeadBlockRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGMethodDefinition #(#ChatPharoPresenter #defaultLayout #false)) #'2026-02-25T21:08:14.058696+02:00') )
]
