require 'spec_helper'

describe "Mongoid::Mirrored" do

  context "Embedding Class" do
    it "should embeds the mirrored document under the correct class name" do
      Article.reflect_on_association(:comments).class_name.should == "Article::Comment"
    end
  end
  
  context "Root Class" do
    let(:comment) { Comment.new }

    it "should reflect on association with Article" do
      comment.fields.should have_key "article_id"
      comment.reflect_on_association(:article).macro.should == :referenced_in
    end
  end
  
  context "Article::Comment Mirror Class" do
    let(:mirror) { Article::Comment.new }

    it "should reflect on association with Article" do
      mirror.reflect_on_association(:article).macro.should == :embedded_in
      mirror.reflect_on_association(:article).inverse_of.should == :comments
    end

  end
  
  context "Article::CommentWithOption Mirror Class" do
    let(:mirror) { Article::CommentWithOption.new }

    it "should reflect on association with Article" do
      mirror.reflect_on_association(:article).macro.should == :embedded_in
      mirror.reflect_on_association(:article).inverse_of.should == :comment_with_option
    end

  end
  
  context "Article::CommentWithLessOption Mirror Class" do
    let(:mirror) { Article::CommentWithLessOption.new }
    
    it "should reflect on association with Article" do
      mirror.reflect_on_association(:article).macro.should == :embedded_in
      mirror.reflect_on_association(:article).inverse_of.should == :comment_with_less_options
    end

  end
end
