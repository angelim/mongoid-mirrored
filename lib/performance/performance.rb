require "benchmark"
require "mongoid"
require "mongoid-mirrored"

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
  has_many :comments
  
end

class Comment
  include Mongoid::Document
  include Mongoid::Timestamps
  field :contents
  
  belongs_to :post, :index => true
end

puts "----------------------------------------------------"
puts "Benchmark for referenced documents"
puts "----------------------------------------------------"

Benchmark.bm do |bm|
  500.times do 
    Post.create
  end
  
  posts = Post.all.to_a
  
  bm.report "creating comments from root collection" do
    10000.times do
      Comment.create(:post => rand_post(posts))
    end
  end
  
  bm.report "updating comments from root collection" do
    Comment.all.each_with_index do |c,i|
      c.update_attribute(:contents, i)
    end
  end
  
  bm.report "traversing posts with comments" do
    10000.times do 
      p = rand_post(posts)
      p.comments.each do |c|
        (con ||= []) << c.contents
      end
    end
  end
  
  bm.report "deleting comments from root collection" do
    Comment.all.map(&:destroy)
  end
  
  bm.report "creating comments from embedding collection" do
    10000.times do
      p = rand_post(posts)
      p.comments.create
    end
  end
  
  bm.report "updating comments from embedding collection" do
    posts.each do |p|
      p.comments.each_with_index do |c,i|
        c.update_attribute(:contents, i)
      end
    end
  end
  
  bm.report "deleting comments from embedding collection" do
    posts.each do |p|
      p.comments.map(&:destroy)
    end
  end
end

Mongoid.master.collections.select {|c| c.name !~ /system/ }.each(&:drop)

Object.send :remove_const, "Post"
class Post
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :title
  embeds_many :comments, :class_name => "Post::Comment"
end

Object.send :remove_const, "Comment"
class Comment
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Mirrored
  
  field :contents
  
  belongs_to :post
  
  mirrored_in :post, :index => true do
    field :contents
    field :counter, :type => Integer
  end
end

puts "----------------------------------------------------"
puts "Benchmark for mirrored documents"
puts "----------------------------------------------------"
Benchmark.bm do |bm|
  500.times do 
    Post.create
  end
  
  posts = Post.all.to_a
  
  bm.report "creating comments from root collection" do
    10000.times do
      Comment.create(:post => rand_post(posts))
    end
  end
  
  bm.report "updating comments from root collection" do
    Comment.all.each_with_index do |c,i|
      c.update_attribute(:contents, i)
    end
  end
  
  bm.report "traversing posts with comments" do
    10000.times do 
      p = rand_post(posts)
      p.comments.each do |c|
        (con ||= []) << c.contents
      end
    end
  end
  
  bm.report "deleting comments from root collection" do
    Comment.all.map(&:destroy)
  end
  
  bm.report "creating comments from embedding collection" do
    10000.times do
      p = rand_post(posts)
      p.comments.create
    end
  end
  
  bm.report "updating comments from embedding collection" do
    posts.each do |p|
      p.comments.each_with_index do |c,i|
        c.update_attribute(:contents, i)
      end
    end
  end
  
  bm.report "deleting comments from embedding collection" do
    posts.each do |p|
      p.comments.map(&:destroy)
    end
  end
end