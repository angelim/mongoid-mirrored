class Article
  include Mongoid::Document
  
  field :title
  index :title
  field :content
  field :published, :type => Boolean, :default => false

  embeds_many :comments, :class_name => "Article::Comment"
end
  