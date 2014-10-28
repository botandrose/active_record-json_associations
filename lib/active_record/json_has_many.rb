require "active_record/json_has_many/version"
require "active_record"
require "json"

module ActiveRecord
  module JsonHasMany
    def json_has_many(field, class_name: nil)
      singularized_field = field.to_s.singularize.to_sym
      class_name ||= singularized_field.to_s.classify
      serialize :"#{singularized_field}_ids", JSON

      class_eval <<-RUBY
        def #{singularized_field}_ids
          super || []
        end

        def #{field}
          #{class_name}.where(id: #{singularized_field}_ids)
        end
      RUBY
    end
  end

  Base.extend JsonHasMany
end

