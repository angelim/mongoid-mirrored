require 'spec_helper'

describe "Mongoid::Mirrored" do

  
  context "Article::CommentWithOption Mirror Class" do
    let(:mirror) { Article::CommentWithOption.new }
    
    it "should create index on association with Article" do
      CommentWithOption.collection.index_information().should include("article_id_1")
    end
  end

end
