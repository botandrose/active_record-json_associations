require "active_record/json_has_many/version"
require "json"

module ActiveRecord
  module JsonHasMany
    def json_has_many(field, class_name:)
      singularized_field = field.to_s.singularize.to_sym
      serialize :"#{singularized_field}_ids", JSON

      class_eval <<-RUBY
        def #{singularized_field}_ids
          super || []
        end

        def #{singularized_field}_ids_json
          JSON.dump(#{singularized_field}_ids)
        end

        def #{singularized_field}_ids_json= json
          self.#{singularized_field}_ids = JSON.load(json)
        end

        def #{singularized_field}_count
          #{singularized_field}_ids.count
        end

        def #{field}
          #{class_name}.where(id: #{singularized_field}_ids)
        end
      RUBY
    end
  end
end

