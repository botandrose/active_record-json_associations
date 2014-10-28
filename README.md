# ActiveRecord::JsonHasMany

Instead of a many-to-many join table, serialize the ids into a JSON array.

## Installation

Add this line to your application's Gemfile:

    gem 'active_record-json_has_many'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_record-json_has_many

## Usage

```ruby
class Parent < ActiveRecord::Base
  has_many_json :children, class_name: "Child"
end
```

This will add some methods:

```ruby
parent.child_ids = [1,2,3]
parent.child_ids #=> [1,2,3]
parent.children => [<Child id=1>, <Child id=2>, Child id=3>]
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/active_record-json_has_many/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

