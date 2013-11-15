# Oat [![Build Status](https://travis-ci.org/ismasan/oat.png)](https://travis-ci.org/ismasan/oat)

Adapters-based API serializers with Hypermedia support for Ruby apps.

## What

Oat lets you design your API payloads succintingly while sticking to your media type of choice (hypermedia or not). 
The details the media type are dealt with by pluggable adapters.

## Serializers

You extend from [Oat::Serializer](https://github.com/ismasan/oat/blob/master/lib/oat/serializer.rb) to define your own resource serializers.

```ruby
class ProductSerializer < Oat::Serializer
  adapter Oat::Adapters::HAL

  schema do
    type "product"
    link :self, href: product_url(item)
    properties do |props|
      props.title item.title
      props.price item.price
      props.description item.blurb
    end
  end

end
```

Then in your app (for example a Rails controller)

```ruby
product = Product.find(params[:id])
render json: ProductSerializer.new(product)
```

## Adapters

Using the included [HAL](http://stateless.co/hal_specification.html) adapter, the `ProductSerializer` above would render the following JSON:

```json
{
    "_links": {
        "self": {"href": "http://example.com/products/1"}
    },
    "title": "Some product",
    "price": 1000,
    "description": "..."
}
```

You can easily swap adapters. The same `ProductSerializer`, this time using the [Siren](https://github.com/kevinswiber/siren) adapter:

```ruby
adapter Oat::Adapters::Siren
```

... Renders this JSON:

```json
{
    "class": ["product"],
    "links": [
        { "rel": [ "self" ], "href": "http://example.com/products/1" }
    ],
    "properties": {
        "title": "Some product",
        "price": 1000,
        "description": "..."
    }
}
```
At the moment Oat ships with adapters for [HAL](http://stateless.co/hal_specification.html), [Siren](https://github.com/kevinswiber/siren) and [JsonAPI](http://jsonapi.org/), but it's easy to write your own.

## Nested serializers

TODO

## Custom adapters.

Adapters let you simplify your API payload design by making it more domain specific.

An adapter class provides a `data` object (just a Hash) that stores your data in the structure you want. An adapter's public methods are exposed to your serializers.

Let's say you're building a social API and want your payload definitions to express the concept of "friendship". You want your serializers to look like:

```ruby
class UserSerializer < Oat::Serializer
  adapter SocialAdapter

  schema do
    name item.name
    email item.email

    # Friend entity
    friends item.friends do |friend, friend_serializer|
      friend_serializer.name friend.name
      friend_serializer.email friend.email
    end
  end
end
```

A custom media type could return JSON looking looking like this:

```json
{
    "name": "Joe",
    "email": "joe@email.com",
    "friends": [
        {"name": "Jane", "email":"jane@email.com"},
        ...
    ]
}
```

The adapter for that would be:

```ruby
class SocialAdapter < Oat::Adapter

  def name(value)
    data[:name] = value
  end

  def email(value)
    data[:email] = value
  end

  def friends(friend_list, serializer_class = nil, &block)
    data[:friends] = friend_list.map do |obj|
      serializer_from_block_or_class(obj, serializer_class, &block)
    end
  end
end
```

But you can easily write an adapter that turns your domain-specific serializers into HAL-compliant JSON.

```ruby
class SocialHalAdapter < Oat::Adapters::HAL

  def name(value)
    property :name, value
  end

  def email(value)
    property :email, value
  end

  def friends(friend_list, serializer_class = nil, &block)
    entities :friends, friend_list, serializer_class, &block
  end
end
```

The result for the SocialHalAdapter is:

```json
{
    "name": "Joe",
    "email": "joe@email.com",
    "_embedded": {
        "friends": [
            {"name": "Jane", "email":"jane@email.com"},
            ...
        ]
    }
}
```

You can take a look at [the built-in Hypermedia adapters](https://github.com/ismasan/oat/tree/master/lib/oat/adapters) for guidance.

## Switching adapters dinamically

Adapters can also be passed as argument to serializer instances.

```ruby
ProductSerializer.new(product, nil, Oat::Adapters::HAL)
```

That means that your app could switch adapters on run time depending, for example, on the request's `Accept` header or anything you need.

## Installation

Add this line to your application's Gemfile:

    gem 'oat'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install oat

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
