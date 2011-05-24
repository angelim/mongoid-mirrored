require 'spec_helper'

describe "Mongoid::Mirrored" do
  
  context "Root Class" do
    let(:comment) { Comment.new }
    
    it "should define callbacks if sync strategy is ..." do
      Comment._create_callbacks.map(&:filter).should include :create_mirror
      Comment._update_callbacks.map(&:filter).should include :update_mirror
      Comment._destroy_callbacks.map(&:filter).should include :destroy_mirror
    end

  end
  
  context "Article::Comment Mirror Class" do
    let(:mirror) { Article::Comment.new }
    
    it "should define callbacks for sync strategy" do
      mirror._create_callbacks.map(&:filter).should include :_create_root
      mirror._update_callbacks.map(&:filter).should include :_update_root
      mirror._destroy_callbacks.map(&:filter).should include :_destroy_root
    end
  end
  
  context "Article::CommentWithOption Mirror Class" do
    let(:mirror) { Article::CommentWithOption.new }
    
    it "should define callbacks for sync strategy" do
      mirror._create_callbacks.map(&:filter).should include :_create_root
      mirror._update_callbacks.map(&:filter).should include :_update_root
      mirror._destroy_callbacks.map(&:filter).should_not include :_destroy_root
    end
  end
  
  context "Article::CommentWithLessOption Mirror Class" do
    let(:mirror) { Article::CommentWithLessOption.new }

    it "should define callbacks for sync strategy" do
      mirror._create_callbacks.map(&:filter).should_not include :_create_root
      mirror._update_callbacks.map(&:filter).should_not include :_update_root
      mirror._destroy_callbacks.map(&:filter).should_not include :_destroy_root
    end
  end
end
