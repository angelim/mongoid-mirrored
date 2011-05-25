module Mongoid
  module Mirrored
    module RootMethods
      # Define callbacks for root class that don't trigger callbacks on the mirror classes
      def define_root_callbacks
        if [:both, :from_root].include?(embedding_options[:sync_direction])
          if embedding_options[:sync_events].include?(:create) || embedding_options[:sync_events] == [:all]
            define_create_mirrors
          end
    
          if embedding_options[:sync_events].include?(:update) || embedding_options[:sync_events] == [:all]
            define_update_mirrors
          end
    
          if embedding_options[:sync_events].include?(:destroy) || embedding_options[:sync_events] == [:all]
            define_destroy_mirrors
          end
        end
      end

      def define_create_mirrors
        unless self.instance_methods.include?(:_create_mirrors)
          self.class_eval <<-EOF
            after_create  :_create_mirrors
          EOF
        end
        define_method :_create_mirrors do
    
          # each embedded class will be touched by the callbacks
          # this should be used with care or write operations could get very slow
          embedding_models[:all].each do |embedding_model|
            # attributes that will be used to define the root and embedding classes and instances
            embedding_string = embedding_model.to_s
            _embedding_klass = self.class.symbol_to_class(embedding_model)
            embedding_instance = eval(embedding_string)
      
            # Only tries to create mirrored document if the embedding instance is given
            if embedding_instance
              _embedding_klass.collection.update({ :_id => embedding_instance.id }, '$push' => {self.class.root_association => attributes.except("#{embedding_string}_id")})
            end
          end
        end
      end

      def define_update_mirrors
        unless self.instance_methods.include?(:_update_mirrors)
          self.class_eval <<-EOF
            before_update  :_update_mirrors
          EOF
        end
        # updates the mirrored document when one or more attributes of the parent document is changed
        # if the root document changes the embedding document, the mirrored document is deleted from the previous list
        # and another mirrored document is created for the new embedding document
        define_method :_update_mirrors do
          embedding_models[:all].each do |embedding_model|
      
            # attributes that will be used to define the root and embedding classes and instances
            embedding_string = embedding_model.to_s
            embedding_instance = eval(embedding_string)
            _embedding_klass = self.class.symbol_to_class(embedding_model)
      
            if embedding_instance
              if eval("#{embedding_string}_id_changed?")
                _create_mirrors
                _destroy_mirrors(eval("#{embedding_string}_id_was"))
              else
                # using positional modifier $ to find embedded document to be updated
                # traverses the attributes hash to inject positional modifier
                # eg: contents => ;comments.$.contents =>
                nested_attr = {}
                attributes.except("#{embedding_string}_id").each_pair do |k,v|
                  nested_attr["#{self.class.root_association}.$.#{k}"] = v
                end
                _embedding_klass.collection.update({"#{self.class.root_association}._id" => id}, '$set' => nested_attr )
              end
            end
          end
        end
      end

      def define_destroy_mirrors
        unless self.instance_methods.include?(:_destroy_mirrors)
          self.class_eval <<-EOF
            after_destroy  :_destroy_mirrors
          EOF
        end
        # destroys the mirrored document when the destroy method is called on the root document
        # or when the root document establishes a relationship with another embedding document
        define_method :_destroy_mirrors do |changed_embedding_instance = nil|
          embedding_models[:all].each do |embedding_model|
      
            # attributes that will be used to define the root and embedding classes and instances
            embedding_string = embedding_model.to_s
            _embedding_klass = self.class.symbol_to_class(embedding_model)
            embedding_instance = eval(embedding_string)
            if embedding_instance
              id_to_destroy = changed_embedding_instance || embedding_instance.id
              _embedding_klass.collection.update({ :_id => id_to_destroy }, '$pull' => {self.class.root_association => { :_id => id}})
            end
          end
        end
      end

      # writes the block passed to the mirrored_in method in the Root Calss
      # defines instance methods used in callbacks triggered by the root documents
      def write_fields_with_options(&block)
        index_params = ""
        index_params << ", :index => true" if embedding_options[:index]
        index_params << ", :background => true" if embedding_options[:index] && embedding_options[:background_index]
  
        embedding_models[:all].each do |embedding_model|
          self.class_eval <<-EOT
            belongs_to :#{embedding_model} #{index_params}
          EOT
        end
        # writes shared fields and methods to root document
        yield
  
        define_root_callbacks
  
      end
    end
  end
end