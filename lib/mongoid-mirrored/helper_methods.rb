module Mongoid
  module Mirrored
    module HelperMethods
      def extract_options(*args)
        options = args.extract_options!
        self.embedding_models = {:all => args, :current => nil}
        self.embedding_options = options
        
        # set defaults
        self.embedding_options[:sync_events] ||= :all
        self.embedding_options[:sync_events] = [self.embedding_options[:sync_events]] unless embedding_options[:sync_events].is_a? Array
        self.embedding_options[:sync_direction] ||= :both
        self.embedding_options[:replicate_to_siblings] = true if self.embedding_options[:replicate_to_siblings].nil?
        self.embedding_options[:inverse_of] ||= :many
        self.embedding_options[:index] = false if self.embedding_options[:index].nil?
        self.embedding_options[:background_index] = false if self.embedding_options[:background_index].nil?
      end
      
      # name of the association used by the embedding class
      # eg: comments
      def root_association
        inverse_of = @root_klass.name.underscore
        inverse_of = inverse_of.pluralize if embedding_options[:inverse_of] == :many
        inverse_of
      end
      
      def symbol_to_class(symbol)
        begin
          symbol.to_s.classify.constantize 
        rescue
          Object.const_set symbol.to_s.classify, Class.new 
        ensure
          symbol.to_s.classify.constantize 
        end
      end
    end
  end
end
  