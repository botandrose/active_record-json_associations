# ActiveRecord::JsonHasMany

[![Build Status](https://travis-ci.org/botandrose/active_record-json_has_many.svg)](https://travis-ci.org/botandrose/active_record-json_has_many)

Instead of keeping the foreign keys on the children, or in a many-to-many join table, let's keep them in a JSON array on the parent.

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
  has_many_json :children
end
```

This will add some methods:

```ruby
parent.child_ids = [1,2,3]
parent.child_ids #=> [1,2,3]
parent.children => [<Child id=1>, <Child id=2>, Child id=3>]
```

## Requirements

* Ruby 2.0+

## Contributing

1. Fork it ( https://github.com/[my-github-username]/active_record-json_has_many/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

