require "active_record/json_has_many/version"
require "active_record"
require "json"

module ActiveRecord
  module JsonHasMany
    def json_has_many(many, class_name: nil)
      one = many.to_s.singularize
      class_name ||= one.classify
      one_ids = :"#{one}_ids"

      serialize one_ids, JSON

      define_method one_ids do
        super() || []
      end

      define_method many do
        class_name.constantize.where(id: send(one_ids))
      end
    end
  end

  Base.extend JsonHasMany
end

