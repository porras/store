# Store [![Build Status](https://travis-ci.org/porras/store.svg)](https://travis-ci.org/porras/store)

Store is a file based storage library for Crystal. It's heavily inspired by [Ruby's
PStore](http://www.rubydoc.info/stdlib/pstore/PStore), although the API is different enough not to keep that P in the
name. Store's job is to easily allow local file based persistence to any serializable data structure, avoiding problems
like data corruption or race conditions.

Store requires Crystal 0.9.0.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  store:
    github: porras/store
```

## Usage

First things first, you need to require the builtin store you want to use (the only one at this point is `JSON::Store`):

```crystal
require "store/json"
```

To use it, you need to instantiate the store, passing the type of the persisted data, and a file name. The persisted
data structure must be serializable in the selected format (this is checked at compile time):

```crystal
json_store = JSON::Store(Array(String)).new("names.json")
```

We can use custom types, provided that we make them serializable using Crystal's serialization macros:

```crystal
class ContactDetails
  JSON.mapping({phone_number: String, address: String})
end

address_book_by_name = JSON::Store(Hash(String, ContactDetails)).new("address_book.json")
```

or even:

```crystal
class ContactDetails
  JSON.mapping({phone_number: String, address: String})
end

class AddressBook
  JSON.mapping({owner: String, addresses: Hash(String, ContactDetails)})
end

address_book = JSON::Store(AddressBook).new("address_book.json")
```

### Accessing the data

In order to read or write, we'll need to open a transaction, using the `transaction` method. This method expectes a
block, to which the data will be yielded. We can of course read that data, but also mutate it, and the changes will be
saved:

```crystal
store = JSON::Store(Array(String)).new("ips.json")

store.transaction do |ips|
  ips << "173.194.32.216" unless ips.includes?("173.194.32.216")
end
```

The data will be saved (atomically, that is, all or nothing) when the block finishes.

### Extension

As we saw, Store includes a generic store in JSON format. But it's easy to create our own store, if we want to a
different format (possible examples are YAML, MessagePack, Protocol Buffers, or even a custom defined format). In order
to do so, we need to inherit from `Store::Base(T)` and define the methods `#read(f : IO)` and `#write(f : IO, data :
T)`. See `src/store/json.cr` for reference.

## Contributing

1. [Fork it](https://github.com/porras/store/fork)
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [porras](https://github.com/porras) - Sergio Gil - creator, maintainer
