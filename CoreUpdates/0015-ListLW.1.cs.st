'From Squeak3.7 of ''4 September 2004'' [latest update: #5989] on 11 May 2008 at 8:52:43 am'!

	self privateMoveBy: delta.
	owner ifNotNil:[
		owner isTextMorph ifTrue:[owner adjustTextAnchor: self]].! !
	"Private!! Relocate me and all of my subMorphs by recursion. Subclasses that implement different coordinate systems may override this method."

	self privateMoveBy: delta.
	owner ifNotNil:[
		owner isTextMorph ifTrue:[owner adjustTextAnchor: self]].! !
	"This message is sent to a dropped morph after it has been dropped on -- and been accepted by -- a drop-sensitive morph"

	| aWindow |
	self formerOwner: nil.
	self formerPosition: nil.
	(aWindow := aMorph ownerThatIsA: OldSystemWindow) 
		ifNotNil: [aWindow isActive ifFalse: [aWindow activate]].
	self isInWorld ifTrue: [self world startSteppingSubmorphsOf: self].
	"Note an unhappy inefficiency here:  the startStepping... call will often have already been called in the sequence leading up to entry to this method, but unfortunately the isPartsDonor: call often will not have already happened, with the result that the startStepping... call will not have resulted in the startage of the steppage."! !