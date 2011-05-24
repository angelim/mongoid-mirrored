# tirar callbacks desta definicao
module Mongoid
  module Mirrored
    def self.included(base)
      base.send(:extend, ClassMethods)
      base.send :cattr_accessor, :embedding_models
      base.send :cattr_accessor, :embedding_options
    end
    
    module ClassMethods
      def extract_options(*args)
        options = args.extract_options!
        self.embedding_models = args
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
      
      def define_after_create_callback(_embedding_model, mirror_klass)
        unless mirror_klass.instance_methods.include?(:_create_root)
          mirror_klass.class_eval <<-EOF
            after_create  :_create_root
          EOF
        end

        mirror_klass.class_eval <<-EOF
          def _create_root
            #{@root_klass}.collection.insert(attributes.merge(:#{_embedding_model}_id => #{_embedding_model}.id))
          end
        EOF
      end
      def define_after_update_callback(_embedding_model, mirror_klass)
        unless mirror_klass.instance_methods.include?(:_update_root)
          mirror_klass.class_eval <<-EOF
            after_update  :_update_root
          EOF
        end

        mirror_klass.class_eval <<-EOF
           def _update_root
             #{@root_klass}.collection.update({ :_id => id }, '$set' => attributes.except('_id'))
           end
         EOF
      end
      
      def define_after_destroy_callback(_embedding_model, mirror_klass)
        unless mirror_klass.instance_methods.include?(:_destroy_root)
          mirror_klass.class_eval <<-EOF
            after_destroy  :_destroy_root
          EOF
        end

        mirror_klass.class_eval <<-EOF
           def _destroy_root
             #{@root_klass}.collection.update({ :_id => id }, '$set' => attributes.except('_id'))
           end
         EOF
      end
      
      def define_after_create_siblings(_embedding_model, mirror_klass)
        unless mirror_klass.instance_methods.include?(:_create_siblings)
          mirror_klass.class_eval <<-EOF
            after_create  :_create_siblings
          EOF
        end
        mirror_klass.class_eval <<-EOF
          def _create_siblings
            #{embedding_models}.each do |sibling|
              _sibling = sibling.to_s
              next if sibling == :#{_embedding_model}
              sibling_klass = sibling.to_s.classify.constantize
              if self[_sibling+"_id"]
                sibling_klass.collection.update({ :_id => self[_sibling+"_id"] }, '$push' => {:#{root_association} => attributes.merge(:#{_embedding_model}_id => #{_embedding_model}.id)})
              end
            end
          end
        EOF
      end
      
      def define_after_update_siblings(_embedding_model, mirror_klass)
        unless mirror_klass.instance_methods.include?(:_update_siblings)
          mirror_klass.class_eval <<-EOF
            after_update  :_update_siblings
          EOF
        end
        mirror_klass.class_eval <<-EOF
          def _update_siblings
            #{embedding_models}.each do |sibling|
              _sibling = sibling.to_s
              next if sibling == :#{_embedding_model}
              sibling_klass = sibling.to_s.classify.constantize
              if self[_sibling+"_id"]
                nested_attr = {}
                attributes.except("#{_embedding_model}_id").each_pair do |k,v|
                  nested_attr["#{root_association}.$."+k] = v
                end
                sibling_klass.collection.update({"#{root_association}._id" => id}, '$set' => nested_attr )
              end
            end
          end
        EOF
      end
      
      def define_after_destroy_siblings(_embedding_model, mirror_klass)
        unless mirror_klass.instance_methods.include?(:_destroy_siblings)
          mirror_klass.class_eval <<-EOF
            after_destroy  :_destroy_siblings
          EOF
        end
        mirror_klass.class_eval <<-EOF
          def _destroy_siblings
            #{embedding_models}.each do |sibling|
              _sibling = sibling.to_s
              next if sibling == :#{_embedding_model}
              sibling_klass = sibling.to_s.classify.constantize
              if self[_sibling+"_id"]
                sibling_klass.collection.update({ :_id => self[_sibling+"_id"] }, '$pull' => {:#{root_association} => { :_id => id}})
              end
            end
          end
        EOF
      end
      
      # Define callbacks for mirror class that don't trigger callbacks on the root class
      def define_mirror_callbacks_for(_embedding_model, mirror_klass)
        if [:both, :from_mirror].include?(embedding_options[:sync_direction])
          if embedding_options[:sync_events].include?(:create) || embedding_options[:sync_events] == [:all]
            define_after_create_callback(_embedding_model, mirror_klass)
            if embedding_options[:replicate_to_siblings] && embedding_models.size > 1
              define_after_create_siblings(_embedding_model, mirror_klass)
            end
          end
          
          if embedding_options[:sync_events].include?(:update) || embedding_options[:sync_events] == [:all]
            define_after_update_callback(_embedding_model, mirror_klass)
            if embedding_options[:replicate_to_siblings] && embedding_models.size > 1
              define_after_update_siblings(_embedding_model, mirror_klass)
            end
          end
          
          if embedding_options[:sync_events].include?(:destroy) || embedding_options[:sync_events] == [:all]
            define_after_destroy_callback(_embedding_model, mirror_klass)
            if embedding_options[:replicate_to_siblings] && embedding_models.size > 1
              define_after_destroy_siblings(_embedding_model, mirror_klass)
            end
          end
        end
      end
      
      # name of the association used by the embedding class
      # eg: comments
      def root_association
        inverse_of = @root_klass.name.underscore
        inverse_of = inverse_of.pluralize if embedding_options[:inverse_of] == :many
        inverse_of
      end
      
      def embeds_mirror_in(_embedding_model, mirror_klass)
        # mongoid macro embedded_in
        # eg: embedded_in :post, :inverse_of => :comments
        
        mirror_klass.class_eval <<-EOT
          embedded_in :#{_embedding_model}, :inverse_of => :#{root_association}
        EOT
      end
      
      def embedding_klass(embedding_sym)
        begin
          _embedding_klass = embedding_sym.to_s.classify.constantize 
        rescue
          Object.const_set embedding_sym.to_s.classify, Class.new 
        ensure
          _embedding_klass = embedding_sym.to_s.classify.constantize 
        end
      end
      
      def mirrored_in(*args, &block)
        extract_options(*args)
        write_fields_with_options { yield }
        @root_klass = self
        # creates a Mirrored class for each embedding model
        embedding_models.each do |embedding_model|
          mirror_klass = Class.new do
            include Mongoid::Document
            
            # includes all fields and methods declared when calling mirrored_in
            class_eval &block
          end
          
          define_mirror_callbacks_for(embedding_model, mirror_klass)
          embeds_mirror_in(embedding_model, mirror_klass)
          _embedding_klass = embedding_klass(embedding_model)
          
          # Creates the mirrored class Embedding::Root
          _embedding_klass.const_set self.name, mirror_klass
        end
      end
      
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
          embedding_models.each do |embedding_model|
            # attributes that will be used to define the root and embedding classes and instances
            embedding_string = embedding_model.to_s
            _embedding_klass = self.class.embedding_klass(embedding_model)
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
          embedding_models.each do |embedding_model|
            
            # attributes that will be used to define the root and embedding classes and instances
            embedding_string = embedding_model.to_s
            embedding_instance = eval(embedding_string)
            _embedding_klass = self.class.embedding_klass(embedding_model)
            
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
          embedding_models.each do |embedding_model|
            
            # attributes that will be used to define the root and embedding classes and instances
            embedding_string = embedding_model.to_s
            _embedding_klass = self.class.embedding_klass(embedding_model)
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
        
        embedding_models.each do |embedding_model|
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