'From Squeak3.7 of ''4 September 2004'' [latest update: #5989] on 9 December 2008 at 4:45:40 pm'!
	| element end i startDate |
	
	element _ element + (schedule at: i).
		i _ i + 1.
	i _ 1.
	[ element <= end ] whileTrue: [
	aBlock value: element.
		i _ i + 1.
.