class Comment
  include Mongoid::Document
  include Mongoid::Mirrored
  
  field :dummy
  mirrored_in :article, :user do
    field :author
    field :contents
    field :like_count, :type => Integer, :default => 0
    
    def foo
      "bar"
    end
  end
end
