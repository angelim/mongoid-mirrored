class CommentWithLessOptions
  include Mongoid::Document
  include Mongoid::Mirrored
  
  field :dummy
  mirrored_in :article,
              :sync_direction => :from_root,
              :replicate_to_siblings => true do
                
    field :author
    field :contents
    field :like_count, :type => Integer, :default => 0
  end
end
