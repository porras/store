require "../store"
require "json"

class JSON::Store(T) < Store::Base(T)
  private def read(f : IO)
    T.from_json(f)
  end

  private def write(f : IO, data : T)
    data.to_json(f)
  end
end
