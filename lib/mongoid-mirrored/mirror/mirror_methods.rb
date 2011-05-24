module Mongoid
  module Mirrored
    module MirrorMethods
      
      def embeds_mirror_in(_embedding_model, mirror_klass)
        # mongoid macro embedded_in
        # eg: embedded_in :post, :inverse_of => :comments
        
        mirror_klass.class_eval <<-EOT
          embedded_in :#{_embedding_model}, :inverse_of => :#{root_association}
        EOT
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
    end
  end
end
