# ActiveRecord::JsonAssociations

[![CI Status](https://github.com/botandrose/active_record-json_associations/actions/workflows/ci.yml/badge.svg)](https://github.com/botandrose/active_record-json_associations/actions/workflows/ci.yml)
[![Code Climate](https://codeclimate.com/github/botandrose/active_record-json_associations/badges/gpa.svg)](https://codeclimate.com/github/botandrose/active_record-json_associations)

Instead of keeping the foreign keys on the children, or in a many-to-many join table, let's keep them in a JSON array on the parent.

## Usage

```ruby
require "active_record/json_associations"

ActiveRecord::Schema.define do
  create_table :parents do |t|
    t.json :child_ids, default: []
  end

  create_table :children
end

class Parent < ActiveRecord::Base
  belongs_to_many :children
end
```

**Note:** The `child_ids` column must be a native JSON type. Text columns are not supported.

This will add some familiar `has_many`-style methods:

```ruby
parent.children? #=> false

parent.children = [Child.create!, Child.create!, Child.create!]
parent.children #=> [#<Child id: 1>, #<Child id: 2>, #<Child id: 3>]

parent.child_ids = [1,2]
parent.child_ids #=> [1,2]

parent.children? #=> true
```

And a scope method for finding records associated with an id:

```ruby
Parent.child_ids_including(2) # => [<Parent child_ids: [1,2,3]>]
```

Or any of a specified array of ids:

```ruby
Parent.child_ids_including(any: [2,4,5]) # => [<Parent child_ids: [1,2,3]>]
```

`touch: true` can be specified on belongs_to_many to touch the associated records' timestamps when the record is modified.

It also adds an `json_foreign_key` option to `has_many` for specifying that the foreign keys are in a json array.

```ruby
class Child
  has_many :parents, json_foreign_key: true # infers :child_ids, but can be overridden
end

child = Child.create!
parent = Parent.create children: [child]
child.parents == [parent] #=> true
```

I can't figure out how to support building records off the association, so instead there are the `has_one`/`belongs_to` builder methods:

```ruby
child.build_parent
child.create_parent
child.create_parent!

# also supports optional attributes:

child.build_parent(name: "Momma")
```

## Requirements

* Ruby 3.2+
* ActiveRecord 7.2+
* Database with JSON column support (MySQL, PostgreSQL, SQLite 3.9+)

## Contributing

1. Fork it ( https://github.com/botandrose/active_record-json_associations/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

