require "mongoid-mirrored/mirror/mirror_methods.rb"
require "mongoid-mirrored/root/root_methods.rb"
require "mongoid-mirrored/helper_methods.rb"

module Mongoid
  module Mirrored
    def self.included(base)
      base.send(:extend, ClassMethods)
      base.send :cattr_accessor, :embedding_models
      base.send :cattr_accessor, :embedding_options
      base.send :cattr_accessor, :mirror_klass
    end
    
    module ClassMethods
      include Mongoid::Mirrored::MirrorMethods
      include Mongoid::Mirrored::RootMethods
      include Mongoid::Mirrored::HelperMethods
      
      def mirrored_in(*args, &block)
        extract_options(*args)
        write_fields_with_options { yield }
        @root_klass = self
        # creates a Mirrored class for each embedding model
        embedding_models[:all].each do |embedding_model|
          self.embedding_models[:current] = embedding_model
          mirror_klass = Class.new do
            include Mongoid::Document
            
            # includes all fields and methods declared when calling mirrored_in
            class_eval &block
          end
          self.mirror_klass = mirror_klass
          define_mirror_attributes
          define_mirror_callbacks
          embeds_mirror
          _embedding_klass = symbol_to_class(embedding_model)
          
          # Creates the mirrored class Embedding::Root
          _embedding_klass.const_set self.name, mirror_klass
        end
      end
    end
  end
end