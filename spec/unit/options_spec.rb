require 'spec_helper'

describe "Mongoid::Mirrored" do
  it "#sync_events" do
    Comment.embedding_options[:sync_events].should == [:all]
    CommentWithOption.embedding_options[:sync_events].should == [:create, :update]
    CommentWithLessOption.embedding_options[:sync_events].should == [:all]
  end
  
  it "#sync_direction" do
    Comment.embedding_options[:sync_direction].should == :both
    CommentWithOption.embedding_options[:sync_direction].should == :from_mirror
    CommentWithLessOption.embedding_options[:sync_direction].should == :from_root
  end
  
  it "#replicate_to_siblings" do
    Comment.embedding_options[:replicate_to_siblings].should == true

    CommentWithOption.embedding_options[:replicate_to_siblings].should == false

    CommentWithLessOption.embedding_options[:replicate_to_siblings].should == true
  end
  
  it "#inverse_of" do
    Comment.embedding_options[:inverse_of].should == :many
    CommentWithOption.embedding_options[:inverse_of].should == :one
    CommentWithLessOption.embedding_options[:inverse_of].should == :many
  end
  
  it "#index" do
    Comment.embedding_options[:index].should == false
    CommentWithOption.embedding_options[:index].should == true
    CommentWithLessOption.embedding_options[:index].should == false
  end
  
  it "#background_index" do
    Comment.embedding_options[:background_index].should == false
    CommentWithOption.embedding_options[:background_index].should == true
    CommentWithLessOption.embedding_options[:background_index].should == false
  end
  
end
