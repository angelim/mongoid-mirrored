require 'spec_helper'

describe "Mongoid::Mirrored" do

  context "Embedding Class" do
    it "should embeds the mirrored document under the correct class name" do
      Article.reflect_on_association(:comments).class_name.should == "Article::Comment"
    end
  end
  
  context "Root Class" do
    let(:comment) { Comment.new }
    it "should include shared fields with correct type and default definition" do
      comment.fields.should have_key "author"
      comment.fields.should have_key "contents"
      comment.fields.should have_key "like_count"
      comment.fields["like_count"].type.should == Integer
      comment.fields["like_count"].default.should == 0
    end
    it "should reflect on association with Article" do
      comment.fields.should have_key "article_id"
      comment.reflect_on_association(:article).macro.should == :referenced_in
    end
    it "should define callbacks if sync strategy is ..." do
      Comment._create_callbacks.map(&:filter).should include :create_mirror
      Comment._update_callbacks.map(&:filter).should include :update_mirror
      Comment._destroy_callbacks.map(&:filter).should include :destroy_mirror
    end
    
    context "operating from root" do
      let(:article) { Article.create }
      it "should push a new comment to the article's comment collection" do
        comment = Comment.create(:article => article)
        article.reload
        article.comments.map(&:id).should include comment.id
      end
    end
  end
  
  context "Mirror Class" do
    let(:mirror) { Article::Comment.new }
    it "should include shared fields with correct type and default definition" do
      mirror.fields.should have_key "author"
      mirror.fields.should have_key "contents"
      mirror.fields.should have_key "like_count"
      mirror.fields["like_count"].type.should == Integer
      mirror.fields["like_count"].default.should == 0
    end
    it "should reflect on association with Article" do
      mirror.reflect_on_association(:article).macro.should == :embedded_in
    end
    it "should define callbacks if sync strategy is ..." do
      mirror._create_callbacks.map(&:filter).should include :create_root
      mirror._update_callbacks.map(&:filter).should include :update_root
      mirror._destroy_callbacks.map(&:filter).should include :destroy_root
    end
  end
end
