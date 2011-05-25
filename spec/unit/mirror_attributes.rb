require 'spec_helper'

describe "Mongoid::Mirrored" do
  
  context "Mirror Attributes" do
    let(:mirror) { Article::Comment.new }
    
    it "should define class accessor attribute for root association" do
      mirror.class.mirror_attributes[:root][:association].should == :comments
    end
    
    it "should define class accessor attribute for root class" do
      mirror.class.mirror_attributes[:root][:klass].should == Comment
    end
    
    it "should define class accessor attribute for embedding sym" do
      mirror.class.mirror_attributes[:embedding][:sym].should == :article
    end
    
    it "should define class accessor for mirror embedding class" do
      mirror.class.mirror_attributes[:embedding][:klass].should == Article
    end
    
    it "should define class accessor for mirror embedding id" do
      mirror.class.mirror_attributes[:embedding][:id].should == :article_id
    end
    
    it "should define class accessor for mirror embedding instance" do
      mirror.class.mirror_attributes[:embedding][:klass].should == "article"
    end
    
  end

end
