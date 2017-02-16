# ActiveRecord::JsonHasMany

[![Build Status](https://travis-ci.org/botandrose/active_record-json_has_many.svg)](https://travis-ci.org/botandrose/active_record-json_has_many)
[![Code Climate](https://codeclimate.com/github/botandrose/active_record-json_has_many/badges/gpa.svg)](https://codeclimate.com/github/botandrose/active_record-json_has_many)

Instead of keeping the foreign keys on the children, or in a many-to-many join table, let's keep them in a JSON array on the parent.

## Usage

```ruby
require "active_record/json_has_many"

ActiveRecord::Schema.define do
  create_table :parents do |t|
    t.text :child_ids
  end

  create_table :children
end

class Parent < ActiveRecord::Base
  json_has_many :children
end
```

This will add some familiar `has_many`-style methods:

```ruby
parent.children? #=> false

parent.children = [Child.create!, Child.create!, Child.create!]
parent.children #=> [#<Child id: 1>, #<Child id: 2>, #<Child id: 3>]

parent.child_ids = [1,2]
parent.child_ids #=> [1,2]

parent.children? #=> true
```

It also adds a scope class method for implementing the inverse relationship on the child:
```ruby
class Child
  def parents
    Parent.where_json_array_includes(child_ids: id)
  end
end

child = Child.create!
parent = Parent.create children: [child]
child.parents == [parent] #=> true
```

## Requirements

* Ruby 2.0+

## Contributing

1. Fork it ( https://github.com/[my-github-username]/active_record-json_has_many/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

