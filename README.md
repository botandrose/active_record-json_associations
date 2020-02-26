# ActiveRecord::JsonAssociations

[![Build Status](https://travis-ci.org/botandrose/active_record-json_associations.svg)](https://travis-ci.org/botandrose/active_record-json_associations)
[![Code Climate](https://codeclimate.com/github/botandrose/active_record-json_associations/badges/gpa.svg)](https://codeclimate.com/github/botandrose/active_record-json_associations)

Instead of keeping the foreign keys on the children, or in a many-to-many join table, let's keep them in a JSON array on the parent.

## Usage

```ruby
require "active_record/json_associations"

ActiveRecord::Schema.define do
  create_table :parents do |t|
    t.text :child_ids
  end

  create_table :children
end

class Parent < ActiveRecord::Base
  belongs_to_many :children
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

And a scope method for finding records assocatied with an id:

```ruby
Parent.child_ids_including(2) # => [<Parent child_ids: [1,2,3]>]
```

It also adds an `json_foreign_key` option to `has_many` for specifying that the foreign keys are in a json array.

```ruby
class Child
  has_many :parents, json_foreign_key: true # infers :child_ids, but can be overridden
end

child = Child.create!
parent = Parent.create children: [child]
child.parents == [parent] #=> true
```

## Requirements

* ActiveRecord 5.0+

## Contributing

1. Fork it ( https://github.com/botandrose/active_record-json_associations/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

