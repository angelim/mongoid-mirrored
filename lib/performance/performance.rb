require "benchmark"
require "mongoid"

def rand_post(posts)
  posts[rand(posts.size)]
end

Mongoid.configure do |config|
  config.master = Mongo::Connection.new.db("mongoid_perf_test")
end
Mongoid.logger = Logger.new($stdout)

Mongoid.master.collections.select {|c| c.name !~ /system/ }.each(&:drop)

class Post
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :title
  # embeds_many :comments, :class_name => "Post::Comment"
  has_many :comments
  
end

class Comment
  include Mongoid::Document
  include Mongoid::Timestamps
  field :contents
  # include Mongoid::Mirrored
  
  # mirrored_in :post, :belongs => true do
  #   field :contents
  #   field :counter, :type => Integer
  # end
  belongs_to :post, :index => true
end

Benchmark.bm do |bm|
  10000.times do 
    Post.create
  end
  
  posts = Post.all.to_a
  
	bm.report "criando comments da raiz" do
		10000.times do
			Comment.create(:post => rand_post(posts))
		end
	end
	
	bm.report "atualizando comments da raiz" do
		Comment.all.each_with_index do |c,i|
			c.update_attribute(:contents, i)
		end
	end
	
	
	bm.report "leitura de var no relacionamento" do
	  posts.each do |p|
  	  p.comments.each do |c|
  	    (con ||= []) << c.contents
      end
    end
  end
	
	bm.report "apagando comments da raiz" do
		Comment.all.map(&:destroy)
	end
	
	bm.report "criando comments do embedded" do
		10000.times do
		  p = rand_post(posts)
			p.comments.create
		end
	end
	
	bm.report "atualizando comments da embedded" do
    posts.each do |p|
  		p.comments.each_with_index do |c,i|
  			c.update_attribute(:contents, i)
  		end
  	end
	end
	
	bm.report "apagando comments da embedded" do
	  posts.each do |p|
  		p.comments.map(&:destroy)
  	end
	end	
end

Mongoid.master.collections.select {|c| c.name !~ /system/ }.each(&:drop)

class Post
  embeds_many :comments, :class_name => "Post::Comment"
  # Post.collection.create_index "comments._id"
end

class Comment
  include Mongoid::Mirrored
  
  mirrored_in :post, :belongs => true do
    field :contents
    field :counter, :type => Integer
  end
end


Benchmark.bm do |bm|
  10000.times do 
    Post.create
  end
  
  posts = Post.all.to_a
  
	bm.report "criando comments da raiz" do
		10000.times do
			Comment.create(:post => rand_post(posts))
		end
	end
	
	bm.report "atualizando comments da raiz" do
		Comment.all.each_with_index do |c,i|
			c.update_attribute(:contents, i)
		end
	end
	
	
	bm.report "leitura de var no relacionamento" do
	  posts.each do |p|
  	  p.comments.each do |c|
  	    (con ||= []) << c.contents
      end
    end
  end
	
	bm.report "apagando comments da raiz" do
		Comment.all.map(&:destroy)
	end
	
	bm.report "criando comments do embedded" do
		10000.times do
		  p = rand_post(posts)
			p.comments.create
		end
	end
	
	bm.report "atualizando comments da embedded" do
    posts.each do |p|
  		p.comments.each_with_index do |c,i|
  			c.update_attribute(:contents, i)
  		end
  	end
	end
	
	bm.report "apagando comments da embedded" do
	  posts.each do |p|
  		p.comments.map(&:destroy)
  	end
	end	
end