require 'spec_helper'

describe "Mongoid::Mirrored" do
  it "#sync_events" do
    Comment.embedding_options[:sync_events].should == [:all]
    CommentWithOptions.embedding_options[:sync_events].should == [:create, :update]
    CommentWithLessOptions.embedding_options[:sync_events].should == [:all]
  end
  
  it "#sync_direction" do
    Comment.embedding_options[:sync_direction].should == :both
    CommentWithOptions.embedding_options[:sync_direction].should == :from_mirror
    CommentWithLessOptions.embedding_options[:sync_direction].should == :from_root
  end
  
  it "#replicate_to_siblings" do
    Comment.embedding_options[:replicate_to_siblings].should == true

    CommentWithOptions.embedding_options[:replicate_to_siblings].should == false

    CommentWithLessOptions.embedding_options[:replicate_to_siblings].should == true
  end
  
  it "#inverse_of" do
    Comment.embedding_options[:inverse_of].should == :many
    CommentWithOptions.embedding_options[:inverse_of].should == :one
    CommentWithLessOptions.embedding_options[:inverse_of].should == :many
  end
  
  it "#index" do
    Comment.embedding_options[:index].should == false
    CommentWithOptions.embedding_options[:index].should == true
    CommentWithLessOptions.embedding_options[:index].should == false
  end
  
  it "#background_index" do
    Comment.embedding_options[:background_index].should == false
    CommentWithOptions.embedding_options[:background_index].should == true
    CommentWithLessOptions.embedding_options[:background_index].should == false
  end
  
end
