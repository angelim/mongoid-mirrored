module Mongoid
  module Mirrored
    module MirrorMethods
      
      def define_mirror_attributes
        mirror_klass.class_eval <<-EOF
          cattr_accessor :mirror_attributes
          self.mirror_attributes = {
                                    :root => {:association => :#{root_association}, :klass => #{self}},
                                    :embedding => {
                                                   :sym => :#{embedding_models[:current]}, 
                                                   :id => :#{embedding_models[:current]}_id,
                                                   :instance => "#{embedding_models[:current]}",
                                                   :klass => #{symbol_to_class(embedding_models[:current])},
                                                   :models => #{embedding_models[:all]}
                                                   }
                                    }
          EOF
      end
      
      def embeds_mirror
        # mongoid macro embedded_in
        # eg: embedded_in :post, :inverse_of => :comments
        
        mirror_klass.class_eval <<-EOT
          embedded_in mirror_attributes[:embedding][:sym], :inverse_of => mirror_attributes[:root][:association]
        EOT
      end
      
      def define_after_create_callback
        unless mirror_klass.instance_methods.include?(:_create_root)
          mirror_klass.class_eval <<-EOF
            after_create  :_create_root
          EOF
        end

        # Comment.collection.insert(attributes.merge(:post_id => post.id))
        mirror_klass.class_eval <<-EOF
          def _create_root
            mirror_attributes[:root][:klass].collection.insert(attributes.merge(mirror_attributes[:embedding][:id] => eval(mirror_attributes[:embedding][:instance]).id))
          end
        EOF
      end
      
      def define_after_update_callback
        unless mirror_klass.instance_methods.include?(:_update_root)
          mirror_klass.class_eval <<-EOF
            after_update  :_update_root
          EOF
        end
        
        # Comment.collection.update({ :_id => id}, '$set' => attributes.except('_id'))
        mirror_klass.class_eval <<-EOF
           def _update_root
             #{@root_klass}.collection.update({ :_id => id }, '$set' => attributes.except('_id'))
           end
         EOF
      end

      def define_after_destroy_callback
        unless mirror_klass.instance_methods.include?(:_destroy_root)
          mirror_klass.class_eval <<-EOF
            after_destroy  :_destroy_root
          EOF
        end

        # Comment.collection.remove({ :id => id}, '$set' => attributes)
        mirror_klass.class_eval <<-EOF
           def _destroy_root
             #{@root_klass}.collection.remove({ :_id => id })
           end
         EOF
      end

      def define_after_create_siblings
        unless mirror_klass.instance_methods.include?(:_create_siblings)
          mirror_klass.class_eval <<-EOF
            after_create  :_create_siblings
          EOF
        end
        
        mirror_klass.class_eval <<-EOF
          def _create_siblings
            mirror_attributes[:embedding][:models].each do |sibling|
              _sibling = sibling.to_s
              next if sibling == mirror_attributes[:embedding][:sym]
              sibling_klass = sibling.to_s.classify.constantize
              if self[_sibling+"_id"]
                sibling_klass.collection.update(
                  { :_id => self[_sibling+"_id"] }, 
                  '$push' => { 
                    mirror_attributes[:root][:association] => attributes.merge(mirror_attributes[:embedding][:id] => eval(mirror_attributes[:embedding][:instance]).id)
                   }
                )
              end
            end
          end
        EOF
      end

      def define_after_update_siblings
        unless mirror_klass.instance_methods.include?(:_update_siblings)
          mirror_klass.class_eval <<-EOF
            after_update  :_update_siblings
          EOF
        end
        mirror_klass.class_eval <<-EOF
          def _update_siblings
            #{embedding_models[:all]}.each do |sibling|
              _sibling = sibling.to_s
              next if sibling == mirror_attributes[:embedding][:sym]
              sibling_klass = sibling.to_s.classify.constantize
              if self[_sibling+"_id"]
                nested_attr = {}
                attributes.except(mirror_attributes[:embedding][:id]).each_pair do |k,v|
                  nested_attr[mirror_attributes[:root][:association].to_s + ".$." + k] = v
                end
                sibling_klass.collection.update({mirror_attributes[:root][:association].to_s+"._id" => id}, '$set' => nested_attr )
              end
            end
          end
        EOF
      end

      def define_after_destroy_siblings
        unless mirror_klass.instance_methods.include?(:_destroy_siblings)
          mirror_klass.class_eval <<-EOF
            after_destroy  :_destroy_siblings
          EOF
        end
        mirror_klass.class_eval <<-EOF
          def _destroy_siblings
            mirror_attributes[:embedding][:models].each do |sibling|
              _sibling = sibling.to_s
              next if sibling == mirror_attributes[:embedding][:sym]
              sibling_klass = sibling.to_s.classify.constantize
              if self[_sibling+"_id"]
                sibling_klass.collection.update({ :_id => self[_sibling+"_id"] }, '$pull' => { mirror_attributes[:root][:association] => { :_id => id}})
              end
            end
          end
        EOF
      end

      # Define callbacks for mirror class that don't trigger callbacks on the root class
      def define_mirror_callbacks
        if [:both, :from_mirror].include?(embedding_options[:sync_direction])
          if embedding_options[:sync_events].include?(:create) || embedding_options[:sync_events] == [:all]
            define_after_create_callback
            if embedding_options[:replicate_to_siblings] && embedding_models[:all].size > 1
              define_after_create_siblings
            end
          end
    
          if embedding_options[:sync_events].include?(:update) || embedding_options[:sync_events] == [:all]
            define_after_update_callback
            if embedding_options[:replicate_to_siblings] && embedding_models[:all].size > 1
              define_after_update_siblings
            end
          end
    
          if embedding_options[:sync_events].include?(:destroy) || embedding_options[:sync_events] == [:all]
            define_after_destroy_callback
            if embedding_options[:replicate_to_siblings] && embedding_models[:all].size > 1
              define_after_destroy_siblings
            end
          end
        end
      end
    end
  end
end
