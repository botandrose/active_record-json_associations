require "active_record"
require "json"

module ActiveRecord
  module JsonAssociations
    def belongs_to_many(many, class_name: nil)
      one = many.to_s.singularize
      one_ids = :"#{one}_ids"
      one_ids_equals = :"#{one_ids}="
      class_name ||= one.classify
      many_equals = :"#{many}="
      many_eh = :"#{many}?"

      serialize one_ids, JSON

      include Module.new {
        define_method one_ids do
          super() || []
        end

        define_method many do
          class_name.constantize.where(id: send(one_ids))
        end

        define_method many_equals do |collection|
          send one_ids_equals, collection.map(&:id)
        end

        define_method many_eh do
          send(one_ids).any?
        end
      }
    end

    def has_many many, scope = nil, options = {}, &extension
      unless scope.try(:[], :json_foreign_key) || options.try(:[], :json_foreign_key)
        return super
      end

      if scope.is_a?(Hash)
        options = scope
        scope   = nil
      end

      foreign_key = options[:json_foreign_key]
      one = many.to_s.singularize
      class_name ||= one.classify
      klass = class_name.constantize

      one_ids = :"#{one}_ids"
      one_ids_equals = :"#{one_ids}="
      many_equals = :"#{many}="
      many_eh = :"#{many}?"

      include Module.new {
        define_method one_ids do
          send(many).pluck(:id)
        end

        define_method one_ids_equals do |ids|
          send many_equals, klass.find(ids)
        end

        define_method many do
          klass.where("#{foreign_key} LIKE '[#{id}]'").or(
            klass.where("#{foreign_key} LIKE '[#{id},%'")).or(
            klass.where("#{foreign_key} LIKE '%,#{id},%'")).or(
            klass.where("#{foreign_key} LIKE '%,#{id}]'"))
        end

        define_method many_equals do |collection|
          collection.each do |record|
            new_id_array = Array(record.send(foreign_key)) | [id]
            record.update foreign_key => new_id_array
          end
        end

        define_method many_eh do
          send(many).any?
        end
      }
    end
  end

  Base.extend JsonAssociations
end

