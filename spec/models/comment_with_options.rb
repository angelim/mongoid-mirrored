class CommentWithOptions
  include Mongoid::Document
  include Mongoid::Mirrored
  
  field :dummy
  mirrored_in :article,
              :inverse_of => :one, 
              :sync_direction => :from_mirror,
              :sync_events => [:create, :update], 
              :index => true,
              :background_index => true,
              :replicate_to_siblings => false do
                
    field :author
    field :contents
    field :like_count, :type => Integer, :default => 0
  end
end