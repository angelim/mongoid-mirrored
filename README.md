Mongoid::Mirrored
====================

Helper module for mirroring root documents in embedded collections. Works with [Mongoid](https://github.com/mongoid/mongoid). 

When adopting the mindset of document base storages we can understand the advantages of representing a document with all its related content as opposed to the relational database approach of referencing information scattered across a number of other collections. That doesn't only help in understanding better the data model we have in our hands, but also usually provides better read performances in our applications. Although the document based mindset can come naturally for most of us, some still struggle when trying to adopt this new paradigm (myself included) and end up modeling our data closely of what we would have done in a relational database. Sometimes that happens because can't be sure of that data access patterns in advance or we just fear denormalization. 

Mongoid provides an intuitive interface to reference documents among different collections, but that comes at a cost. As MongoDB doesn't support joins and relying heavily on relational data reads, that could be a problem for some applications. Unfortunately, Mongoid doens't support embedding collections while maintaining an independent root collection and that is exactly the intention with mirrored documents.  

I couldn't find anything that helped me with that, but this [discussion](http://groups.google.com/group/mongoid/browse_thread/thread/b5e2bccf77457043) at the mongoid group where Durran stated that it was unlikely that mongoid would go in that direction. 

This gem has been inspired by that conversation and also [Mongoid::Denormalize](https://github.com/logandk/mongoid_denormalize) which you should definitelly check out if you have similar needs.

I'm not an experienced developer(in fact I work as a Product Manager and develop only to bootstrap proofs of concept) and I'm new to document database storages. Please feel free to contribute to this gem or point out the correct approach for this.

Installation
------------

Add the gem to your Bundler `Gemfile`:

    gem 'mongoid-mirrored'

Or install with RubyGems:

    $ gem install mongoid-mirrored


Usage
-----

In your root(master) model:

	# Include the helper module
	include Mongoid::Mirrored

	# Define wich fields and methods will be shared among root and embedded classes
	mirrored_in :articles, :users, :sync_direction => :both, :sync_events => :all do
		field :contents, :type => String
		field :vote_ratio, :type => Float
	
		def calculate_vote_ratio
			# do something with votes
		end
	end
    

Example
-------

	# The conventioned name for the mirrored class is "#{embedding_class}::{root_class}"

	class Post
	  embeds_many :comments, :class_name => "Post::Comment"
	end

	class User
	  embeds_many :comments, :class_name => "User::Comment"
	end

	# The Root Class should establish with which classes it is supposed to sync documents.
	# Everything declared within the block will be shared between the root and mirrored 
	# documents (eg. fields, instance methods, class methods)

	class Comment
		mirrored_in :post, :user, :sync_direction => :both do
			field :contents
			field :vote_ratio, :type => Integer
			def	foo
			 "bar"
			end
		end
	end

Options
-------
	
	sync_events
	-----------
		:all(default) => sync master and mirrored documents on :after_create, :after_update and :after_destroy callbacks
		:create => syncs only on :after_create
		:update => syncs only on :after_update
		:destroy => syncs only on :after_destroy
	this options accepts an Array of events (eg: [:create, :destroy])	
	
	sync_direction
	--------------
		:both(default) => syncs documents on both directions. From master(root) to mirrors and from mirror to master
		:from_root => syncs only from master to mirrors
		:from_mirror => syncs only from mirror to master
		
	replicate_to_siblings
	---------------------
	true(default) => perform operations on the mirror's siblings 
	(eg: article.comments.create(:user_id => user.id) will replicate the document on the User::Comment collection)

	inverse_of
	----------
	:one => 
	:many(default)
	
	index
	-----
	false(default) => determines whether the root collection will create an index on the embedding collection's foreign_key
	
	index_background
	----------------
	false(default) => determines whether the aforementioned index will run on background
	
	
Rake tasks
----------

should include tasks to re-sync


Known issues
------------

- The helper does not support multiple calls of the mirrored_in method
- Changing parents from the embedded association does not update target documents. Use the master collection to change associations.
	- eg post.comments.first.update_attribute(:post_id => Post.create) does not include the comment in the new Post comments list

Performance
------------
I ran a [benchmark](https://github.com/angelim/mongoid-mirrored/blob/master/perf/benchmark.rb) on my computer with the following results

Benchmark for referenced documents

	                                                                     user     system      total        real
	creating 10000 comments in 200 posts from root collection       7.820000   0.250000   8.070000   (8.252877)
	updating 10000 comments from root collection                    5.080000   0.250000   5.330000   (5.583467)
	# traversing posts with comments 10000 times                    0.670000   0.010000   0.680000   (0.772653)
	finding posts from the 1000 newest comments                     0.530000   0.040000   0.570000   (0.647710)
	deleting 10000 comments from root collection                    2.710000   0.180000   2.890000   (3.238750)
	creating 10000 comments in 200 posts from embedding collection  8.270000   0.210000   8.480000   (8.530049)
	updating 10000 comments from embedding collection               9.830000   0.360000  10.190000   (10.76156)
	deleting 10000 comments from embedding collection               4.750000   0.240000   4.990000   (5.217647)

Benchmark for mirrored documents

	                                                                      user     system      total        real
	creating 10000 comments in 200 posts from root collection       14.870000    0.450000  15.320000  (15.476777)
	updating 10000 comments from root collection                    25.590000    0.970000  26.560000  (36.910317)
	# traversing posts with comments 10000 times                    0.200000     0.000000   0.200000   (0.211826)
	finding posts from the 1000 newest comments                     0.190000   0.000000   0.190000     (0.198631)
	deleting 10000 comments from root collection                    17.880000    0.820000  18.700000  (21.626592)
	creating 10000 comments in 200 posts from embedding collection  7.100000     0.340000   7.440000  ( 8.562442)
	updating 10000 comments from embedding collection               5.030000     0.300000   5.330000  ( 6.058490)
	deleting 10000 comments from embedding collection               2.540000     0.130000   2.670000  ( 2.733644)

Credits
-------

Copyright (c) 2011 Alexandre Angelim, released under the MIT license.