# frozen_string_literal: true

require "active_record"
require "json"

module ActiveRecord
  module JsonAssociations
    ORDER_BY_IDS_PROC = proc do |scope, ids|
      if ids.empty?
        scope
      else
        pk = scope.klass.primary_key
        quoted_ids = ids.map { |id| scope.connection.quote(id) }
        order_sql = case scope.connection.adapter_name
        when "Mysql2", "Trilogy"
          "FIELD(#{pk}, #{quoted_ids.join(",")})"
        when "PostgreSQL"
          "array_position(ARRAY[#{quoted_ids.join(",")}], #{pk})"
        else
          fragments = ids.each_with_index.map { |id, i| "WHEN #{quoted_ids[i]} THEN #{i}" }
          "CASE #{pk} #{fragments.join(" ")} END"
        end
        scope.order!(Arel.sql(order_sql))
      end
    end
    private_constant :ORDER_BY_IDS_PROC

    FIELD_INCLUDE_SCOPE_BUILDER_PROC = proc do |context, field, id|
      unless context.columns_hash[field.to_s].type == :json
        raise ArgumentError, "#{field} column must be of type :json"
      end

      sanitized_id = id.to_i

      case context.connection.adapter_name
      when "Mysql2", "Trilogy"
        context.where("JSON_CONTAINS(#{field}, ?, '$')", sanitized_id.to_json)
      when "PostgreSQL"
        context.where("#{field}::jsonb @> ?::jsonb", [sanitized_id].to_json)
      else
        context.where("EXISTS (SELECT 1 FROM json_each(#{field}) WHERE value = ?)", sanitized_id)
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

      unless columns_hash[one_ids.to_s].type == :json
        raise ArgumentError, "#{one_ids} column must be of type :json"
      end

      if touch
        after_commit do
          unless no_touching?
            old_ids, new_ids = saved_changes[one_ids.to_s]
            ids = Array(send(one_ids)) | Array(old_ids) | Array(new_ids)
            class_name.constantize.where(self.class.primary_key => ids).touch_all
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
          ids = send(one_ids).map(&:to_i)
          scope = klass.where(klass.primary_key => ids)
          ORDER_BY_IDS_PROC.call(scope, ids)
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

      foreign_key = options[:json_foreign_key]
      foreign_key = :"#{model_name.singular}_ids" if foreign_key == true

      pending_associations_var = :"@pending_#{many}"

      after_create do
        if (pending = instance_variable_get(pending_associations_var))
          instance_variable_set(pending_associations_var, nil)
          send(many_equals, pending)
        end
      end

      include Module.new {
        define_method one_ids do
          send(many).pluck(:id)
        end

        define_method one_ids_equals do |ids|
          klass = class_name.constantize
          normalized_ids = Array(ids).select(&:present?).map(&:to_i).uniq
          send many_equals, klass.find(normalized_ids)
        end

        define_method many do
          klass = class_name.constantize
          FIELD_INCLUDE_SCOPE_BUILDER_PROC.call(klass, foreign_key, id)
        end

        define_method many_equals do |collection|
          if new_record?
            instance_variable_set(pending_associations_var, collection)
          else
            collection.each do |record|
              new_id_array = Array(record.send(foreign_key)) | [id]
              record.update foreign_key => new_id_array
            end
          end
        end

        define_method many_eh do
          send(many).any?
        end

        define_method build_one do |attributes={}|
          klass = class_name.constantize
          klass.new attributes.merge!(foreign_key => [id])
        end

        define_method create_one do |attributes={}|
          klass = class_name.constantize
          klass.create attributes.merge!(foreign_key => [id])
        end

        define_method create_one_bang do |attributes={}|
          klass = class_name.constantize
          klass.create! attributes.merge!(foreign_key => [id])
        end
      }
    end
  end

  Base.extend JsonAssociations
end

