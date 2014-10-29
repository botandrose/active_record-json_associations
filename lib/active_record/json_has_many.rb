require "active_record/json_has_many/version"
require "active_record"
require "json"

module ActiveRecord
  module JsonHasMany
    def json_has_many(many, class_name: nil)
      one = many.to_s.singularize
      one_ids = :"#{one}_ids"
      one_ids_equals = :"#{one_ids}="
      class_name ||= one.classify
      many_equals = :"#{many}="

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
      }
    end
  end

  Base.extend JsonHasMany
end

