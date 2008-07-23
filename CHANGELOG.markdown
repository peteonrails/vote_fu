2008-07-20
==========
* Protect against mass assignment misvotes using attr\_accessible
* Update acts\_as mixins to use self.class.name instead of the deprecated self.type.name

2008-07-15
==========
* Added examples directory
* Changed this file to markdown format for GitHub goodness
* Added a commented out unique index in the migration generator for "one person, one vote"
* Removed votes\_controller.rb from lib/ and moved to examples

2008-07-10
==========

* Added a generator class for the migration. 
* Implemented rails/init.rb
* Implemented capability to use any model as the initiator of votes.
* Implemented acts\_as\_voter methods.
