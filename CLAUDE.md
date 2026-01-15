# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About

ActiveRecord::JsonAssociations is a Ruby gem that provides an alternative to traditional many-to-many join tables by storing foreign keys in a JSON array on the parent record.

## Development Commands

```bash
# Run all tests
bundle exec rake

# Run a single spec file
bundle exec rspec spec/belongs_to_many_spec.rb

# Run a specific test by line number
bundle exec rspec spec/belongs_to_many_spec.rb:42

# Test against specific Rails versions using Appraisal
BUNDLE_GEMFILE=gemfiles/rails_7.1.gemfile bundle exec rake
BUNDLE_GEMFILE=gemfiles/rails_8.0.gemfile bundle exec rake
```

## Architecture

The gem extends `ActiveRecord::Base` with a single module (`ActiveRecord::JsonAssociations`) that provides two main class methods:

- **`belongs_to_many`** - Stores foreign keys as a JSON array in a text/json column on the parent model. Provides `children`, `children=`, `child_ids`, `child_ids=`, `children?` methods plus a `child_ids_including` scope for querying.

- **`has_many :json_foreign_key`** - The inverse relationship. When a child model uses this option, it can find parents that reference it via their JSON arrays. Also provides `build_parent`, `create_parent`, `create_parent!` builder methods.

Both methods support native JSON columns (using `JSON_CONTAINS`) or text columns (using `LIKE` queries with serialized JSON).

## Testing

Tests use RSpec with an in-memory SQLite database. Each spec file sets up its own schema and model classes. Use `focus: true` on individual specs during development.
