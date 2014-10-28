require "active_record/json_has_many/version"
require "active_record"
require "json"

module ActiveRecord
  module JsonHasMany
    def json_has_many(field, class_name: nil)
      singularized_field = field.to_s.singularize.to_sym
      class_name ||= singularized_field.to_s.classify
      singularized_field_ids = :"#{singularized_field}_ids"

      serialize singularized_field_ids, JSON

      define_method singularized_field_ids do
        super() || []
      end

      define_method field do
        class_name.constantize.where(id: send(singularized_field_ids))
      end
    end
  end

  Base.extend JsonHasMany
end

