# qdo um mirror mudar, avisar o root para atualizar outros filhos
# dar opcao de nao atualizar mais no futuro
# processar varias chamadas do mirrored_in
# ter callbacks para cada modelo embedado
# indexes opcionais
# sync_events => :all(default), :create, :update, :destroy
# sync_direction => :both(default), :from_root, :from_mirror
# replicate_to_siblings => true(default)
# inverse_of => :posts

module Mongoid
  module Mirrored
    def self.included(base)
      base.send(:extend, ClassMethods)
      base.after_create    :create_mirror
      base.before_update   :update_mirror  
      base.before_destroy  :destroy_mirror
      base.send :cattr_accessor, :embedding_models
      base.send :cattr_accessor, :embedding_options
    end
    
    module ClassMethods
      # Class method that creates the mirrored model
      # the Embedding Class should define a relation to the Root Class
      # using the convention name for the mirrored document "#{embedding_class}::{root_class}"
      #   class Post
      #     embeds_many :comments, :class_name => "Post::Comment"
      #   end
      # 
      #   class User
      #     embeds_many :comments, :class_name => "User::Comment"
      #   end
      # 
      # The Root Class should establish with which classes it is supposed to sync documents
      # and whether the belongs_to macro should be called.
      # Everything declared within the block will be shared between the root and all mirrored 
      # documents (eg. fields, instance methods, class methods)
      #   class Comment
      #    mirrored_in :post, :user, :inverse_of => :posts, :sync_events => :all do
      #      field :contents
      #      field :counter, :type => Integer
      #    end
      #   end
      #  
      # all operations on either side(root or mirrored) will be synched
      

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
      
      # Define callbacks for mirror class that don't trigger callbacks on the root class
      def define_mirror_callbacks_for(_embedding_model, mirror_klass)
        if [:both, :from_mirror].include?(embedding_options[:sync_direction])
          if ([:all, :create] & embedding_options[:sync_events]).size == embedding_options[:sync_events].size
            mirror_klass.class_eval <<-EOF
              after_create  :_create_root
              def _create_root
                #{@root_klass}.collection.insert(attributes.merge(:#{_embedding_model}_id => #{_embedding_model}.id))
              end
            EOF
          end
          
          if ([:all, :update] & embedding_options[:sync_events]).size == embedding_options[:sync_events].size
            mirror_klass.class_eval <<-EOF
              after_update  :_update_root
              def _update_root
                #{@root_klass}.collection.update({ :_id => id }, '$set' => attributes.except('_id'))
              end
            EOF
          end
          
          if ([:all, :destroy] & embedding_options[:sync_events]).size == embedding_options[:sync_events].size
            mirror_klass.class_eval <<-EOF
              after_destroy  :_destroy_root
              def destroy_root
                #{@root_klass}.collection.remove({ :_id => id })
              end
            EOF
          end
        end
      end
      
      def embeds_mirror_in(_embedding_model, mirror_klass)
        # mongoid macro embedded_in
        # eg: embedded_in :post, :inverse_of => :comments
        inverse_of = @root_klass.name.underscore
        inverse_of.pluralize if embedding_options[:inverse_of] == :many

        
        mirror_klass.class_eval <<-EOT
          embedded_in :#{_embedding_model}, :inverse_of => :#{inverse_of}
        EOT
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
          
          _embedding_model = embedding_model.to_s
          embedding_klass = _embedding_model.classify.constantize
          
          # Creates the mirrored class Embedding::Root
          embedding_klass.const_set self.name, mirror_klass
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
        yield
        
        root_klass = self
        # name of the association used by the embedding class
        # eg: comments
        root_association = root_klass.name.downcase.pluralize
        
        # Defining callbacks for the root document
        define_method :create_mirror do
          
          # each embedded class will be touched by the callbacks
          # this should be used with care or write operations could get very slow
          embedding_models.each do |embedding_model|
            # attributes that will be used to define the root and embedding classes and instances
            embedding_string = embedding_model.to_s
            embedding_klass = embedding_string.classify.constantize
            embedding_instance = eval(embedding_string)
            
            # Only tries to create mirrored document if the embedding instance is given
            if embedding_instance
              # eg: Post.comments.create(attributes.merge!(:skip_callbacks => true).except(:post_id))
              embedding_klass.collection.update({ :_id => embedding_instance.id }, '$push' => {root_association => attributes.except("#{embedding_string}_id")})
            end
          end
        end
        # updates the mirrored document when one or more attributes of the parent document is changed
        # if the root document changes the embedding document, the mirrored document is deleted from the previous list
        # and another mirrored document is created for the new embedding document
        define_method :update_mirror do
          embedding_models.each do |embedding_model|
            
            # attributes that will be used to define the root and embedding classes and instances
            embedding_string = embedding_model.to_s
            embedding_klass = embedding_string.classify.constantize
            embedding_instance = eval(embedding_string)
            
            if embedding_instance
              if eval("#{embedding_string}_id_changed?")
                create_mirror
                destroy_mirror(eval("#{embedding_string}_id_was"))
              else
                # using positional modifier $ to find embedded document to be updated
                # traverses the attributes hash to inject positional modifier
                # eg: contents => ;comments.$.contents =>
                nested_attr = {}
                attributes.except("#{embedding_string}_id").each_pair do |k,v|
                  nested_attr["#{root_association}.$.#{k}"] = v
                end
                embedding_klass.collection.update({"#{root_association}._id" => id}, '$set' => nested_attr )
              end
            end
          end
        end
        # destroys the mirrored document when the destroy method is called on the root document
        # or when the root document establishes a relationship with another embedding document
        define_method :destroy_mirror do |changed_embedding_instance = nil|
          embedding_models.each do |embedding_model|
            
            # attributes that will be used to define the root and embedding classes and instances
            embedding_string = embedding_model.to_s
            embedding_klass = embedding_string.classify.constantize
            embedding_instance = eval(embedding_string)
            if embedding_instance
              id_to_destroy = changed_embedding_instance || embedding_instance.id
              embedding_klass.collection.update({ :_id => id_to_destroy }, '$pull' => {root_association => { :_id => id}})
            end
          end
        end
      end
    end
  end
end