require "active_record/json_has_many/version"
require "active_record"
require "json"

module ActiveRecord
  module JsonHasMany
    def json_has_many(many, class_name: nil)
      one = many.to_s.singularize
      one_ids = :"#{one}_ids"
      class_name ||= one.classify

      serialize one_ids, JSON

      include instance_methods(one_ids, many, class_name)
    end

    private

    def instance_methods one_ids, many, class_name
      Module.new do
        define_method one_ids do
          super() || []
        end

        define_method many do
          class_name.constantize.where(id: send(one_ids))
        end
      end
    end
  end

  Base.extend JsonHasMany
end

