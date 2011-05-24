class User
  include Mongoid::Document
  field :name
  embeds_many :comments, :class_name => "User::Comment"
end