class Comment
  include Mongoid::Document
  include Mongoid::Mirrored
  
  field :dummy
  mirrored_in :article, :sync => :auto do
    field :author
    field :contents
    field :like_count, :type => Integer, :default => 0
  end
end