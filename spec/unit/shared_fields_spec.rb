require 'spec_helper'

describe "Mongoid::Mirrored" do

  
  context "Root Class" do
    let(:comment) { Comment.new }
    
    it "should include shared fields with correct type and default definition" do
      comment.fields.should have_key "author"
      comment.fields.should have_key "contents"
      comment.fields.should have_key "like_count"
      comment.fields["like_count"].type.should == Integer
      comment.fields["like_count"].default.should == 0
    end
  end
  
  context "Article::Comment Mirror Class" do
    let(:mirror) { Article::Comment.new }
    
    it "should include shared fields with correct type and default definition" do
      mirror.fields.should have_key "author"
      mirror.fields.should have_key "contents"
      mirror.fields.should have_key "like_count"
      mirror.fields["like_count"].type.should == Integer
      mirror.fields["like_count"].default.should == 0
    end
  end

end
