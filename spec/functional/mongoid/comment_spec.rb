# test methods
# test from_mirror
require 'spec_helper'

describe "Comment" do
  let(:article) { Article.create }
  let(:user) { User.create }
  context "creating from the root collection" do
    it "should create document in root collection" do
      c = Comment.create(:article => article, :contents => "root", :author => "root_author" )
      Comment.where(:contents => "root").first.should == c
    end
    
    it "should create similar document in each embedding collection" do
      c  = Comment.create(:article => article, :user => user, :contents => "root", :author => "root_author" )
      article.reload
      article.comments.find(c.id.to_s).should_not be_nil
      user.reload
      user.comments.find(c.id.to_s).should_not be_nil
    end
    
  end
  
  context "creating from the embedding collection" do
    it "should create document in root collection" do
      c = article.comments.create(:contents => "embedding", :author => "embedding_author")
      Comment.find(c.id).should_not be_nil
    end
    
    it "should create similar document in embedding collection" do
      c = article.comments.create(:contents => "embedding", :author => "embedding_author")
      article.reload
      c.article.should == article
    end
    
    it "should replicate document to sibling collections" do
      c = article.comments.create(:user_id => user.id, :contents => "embedding", :author => "embedding_author")
      user.reload
      user.comments.find(c.id).should_not be_nil
    end
  end

  context "updating from the root collection" do
    it "should update document in root collection" do
      c  = Comment.create(:article => article, :contents => "root", :author => "root_author" )
      c.update_attributes(:contents => "new_root", :author => "new_author_root")
      Comment.where(:contents => "new_root", :author => "new_author_root").first.should == c

    end
    
    it "should update document in embedding collection with new attributes" do
      c  = Comment.create(:article => article, :user => user, :contents => "root", :author => "root_author" )
      c.update_attributes(:contents => "new_root", :author => "new_author_root")
      article.reload
      article.comments.where(:contents => "new_root", :author => "new_author_root").first.id.should == c.id
      user.reload
      user.comments.where(:contents => "new_root", :author => "new_author_root").first.id.should == c.id
    end
    context "switching embedding document" do
      it "should delete comment from embedding original collection" do
        c = article.comments.create(:contents => "embedding", :author => "embedding_author")
        Comment.first.update_attributes(:article_id =>  Article.create.id, :user_id => User.create.id)
        article.reload
        article.comments.should be_empty
        user.reload
        user.comments.should be_empty
      end
      it "should create comment in new embedding collection" do
        c = article.comments.create(:contents => "embedding", :author => "embedding_author")
        Comment.first.update_attribute(:article_id, Article.create.id)
        Article.last.comments.where(:contents => "embedding").should_not be_empty
      end
    end
  end
  
  context "updating from the embedding collection" do
    it "should update document in root collection with new attributes" do
      c = article.comments.create(:contents => "embedding", :author => "embedding_author")
      c.update_attributes(:contents => "new_embedding", :author => "new_author_embedding")
      Comment.where(:contents => "new_embedding", :author => "new_author_embedding").first.id.should == c.id
    end
    
    it "should update similar document in embedding collection" do
      c = article.comments.create(:contents => "embedding", :author => "embedding_author")
      c.update_attributes(:contents => "new_embedding", :author => "new_author_embedding")
      article.reload
      article.comments.where(:contents => "new_embedding", :author => "new_author_embedding").first.id.should == c.id
    end
    
    it "should replicate changes to sibling collections" do
      c = article.comments.create(:user_id => user.id, :contents => "embedding", :author => "embedding_author")
      c.update_attributes(:contents => "new_embedding", :author => "new_author_embedding")
      user.reload
      user.comments.find(c.id).contents.should == "new_embedding"
    end
  end
  
  context "destroying from the root collection" do
    it "should destroy document in root collection" do
      c  = Comment.create(:article => article, :user => user, :contents => "root", :author => "root_author" )
      c.destroy
      Comment.where(:content => "root").should be_empty
    end
    
    it "should destroy similar document in each embedding collection" do
      c  = Comment.create(:article => article, :user => user, :contents => "root", :author => "root_author" )
      c.destroy
      article.reload
      article.comments.where(:contents => "root").should be_empty
      user.reload
      user.comments.where(:contents => "root").should be_empty
    end
  end
  
  context "destroy from the embedding collection" do
    it "should destroy document in root collection" do
      c = article.comments.create(:contents => "embedding", :author => "embedding_author")
      c.destroy
      Comment.where(:content => "embedding").should be_empty
    end
    
    it "should destroy similar document from embedding collection" do
      c = article.comments.create(:contents => "embedding", :author => "embedding_author")
      c.destroy
      article.reload
      article.comments.where(:content => "embedding").should be_empty
    end
    
    it "should destroy document from sibling collections" do
      c = article.comments.create(:user_id => user.id, :contents => "embedding", :author => "embedding_author")
      c.destroy
      user.reload
      user.comments.where(:_id => c.id).should be_empty
    end
  end
  
end
