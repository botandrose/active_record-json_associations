require "active_record"
require "json"

module ActiveRecord
  module JsonAssociations
    FIELD_INCLUDE_SCOPE_BUILDER_PROC = proc do |context, field, id|
      using_json = context.columns_hash[field.to_s].type == :json

      if using_json
        context.where("JSON_CONTAINS(#{field}, ?, '$')", id.to_json)
      else
        context.where("#{field}='[#{id}]'").or(
          context.where("#{field} LIKE '[#{id},%'")).or(
            context.where("#{field} LIKE '%,#{id},%'")).or(
              context.where("#{field} LIKE '%,#{id}]'"))
      end
    end
    private_constant :FIELD_INCLUDE_SCOPE_BUILDER_PROC

    def belongs_to_many(many, class_name: nil, touch: nil)
      one = many.to_s.singularize
      one_ids = :"#{one}_ids"
      one_ids_equals = :"#{one_ids}="
      many_equals = :"#{many}="
      many_eh = :"#{many}?"

      class_name ||= one.classify

      using_json = columns_hash[one_ids.to_s].type == :json

      if !using_json
        if ActiveRecord.version >= Gem::Version.new("7.1")
          serialize one_ids, coder: JSON
        else
          serialize one_ids, JSON
        end
      end

      if touch
        after_commit do
          unless no_touching?
            method = respond_to?(:saved_changes) ? :saved_changes : :previous_changes
            old_ids, new_ids = send(method)[one_ids.to_s]
            ids = Array(send(one_ids)) | Array(old_ids) | Array(new_ids)
            scope = class_name.constantize.where(self.class.primary_key => ids)

            if scope.respond_to?(:touch) # AR 6.0+
              scope.touch_all
            elsif self.class.respond_to?(:touch_attributes_with_time) # AR 5.1+
              scope.update_all self.class.touch_attributes_with_time
            else # AR 5.0
              attributes = timestamp_attributes_for_update_in_model.inject({}) do |attributes, key|
                attributes.merge(key => current_time_from_proper_timezone)
              end
              scope.update_all attributes
            end
          end
        end
      end

      extend Module.new {
        define_method :"#{one_ids}_including" do |id|
          raise "can't query for a record that does not have an id!" if id.blank?
          if id.is_a?(Hash)
            Array(id[:any]).inject(none) do |context, id|
              context.or(FIELD_INCLUDE_SCOPE_BUILDER_PROC.call(self, one_ids, id))
            end
          else
            FIELD_INCLUDE_SCOPE_BUILDER_PROC.call(self, one_ids, id)
          end
        end
      }

      include Module.new {
        define_method one_ids do
          super().tap do |value|
            return send(one_ids_equals, []) if value.nil?
          end
        end

        define_method one_ids_equals do |ids|
          super Array(ids).select(&:present?).map(&:to_i).uniq
        end

        define_method many do
          klass = class_name.constantize
          scope = klass.all

          ids = send(one_ids)
          scope.where!(klass.primary_key => ids)

          fragments = []
          fragments += ["#{klass.primary_key} NOT IN (#{ids.map(&:to_s).join(",")})"] if ids.any?
          fragments += ids.reverse.map { |id| "#{klass.primary_key}=#{id}" }
          order_by_ids = fragments.join(", ")
          scope.order!(Arel.sql(order_by_ids))
        end

        define_method many_equals do |collection|
          send one_ids_equals, collection.map(&:id)
        end

        define_method many_eh do
          send(one_ids).any?
        end
      }
    end

    def has_many many, scope = nil, **options, &extension
      unless (scope.is_a?(Hash) && scope[:json_foreign_key]) || (options.is_a?(Hash) && options[:json_foreign_key])
        return super
      end

      if scope.is_a?(Hash)
        options = scope
        scope   = nil
      end

      one = many.to_s.singularize
      one_ids = :"#{one}_ids"
      one_ids_equals = :"#{one_ids}="
      many_equals = :"#{many}="
      many_eh = :"#{many}?"
      build_one = :"build_#{one}"
      create_one = :"create_#{one}"
      create_one_bang = :"create_#{one}!"

      class_name = options[:class_name] || one.classify
      klass = class_name.constantize

      foreign_key = options[:json_foreign_key]
      foreign_key = :"#{model_name.singular}_ids" if foreign_key == true

      include Module.new {
        define_method one_ids do
          send(many).pluck(:id)
        end

        define_method one_ids_equals do |ids|
          normalized_ids = Array(ids).select(&:present?).map(&:to_i).uniq
          send many_equals, klass.find(normalized_ids)
        end

        define_method many do
          FIELD_INCLUDE_SCOPE_BUILDER_PROC.call(klass, foreign_key, id)
        end

        define_method many_equals do |collection|
          collection.each do |record|
            new_id_array = Array(record.send(foreign_key)) | [id]
            raise "FIXME: Cannot assign during creation, because no id has yet been reified." if new_id_array.any?(&:nil?)
            record.update foreign_key => new_id_array
          end
        end

        define_method many_eh do
          send(many).any?
        end

        define_method build_one do |attributes={}|
          klass.new attributes.merge!(foreign_key => [id])
        end

        define_method create_one do |attributes={}|
          klass.create attributes.merge!(foreign_key => [id])
        end

        define_method create_one_bang do |attributes={}|
          klass.create! attributes.merge!(foreign_key => [id])
        end
      }
    end
  end

  Base.extend JsonAssociations
end

