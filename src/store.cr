require "./store/version"

module Store
  abstract class Base(T)
    def initialize(@filename)
      unless File.exists?(@filename)
        File.open(@filename, "w") do |f|
          write(f, T.new)
        end
      end
    end

    def transaction
      File.open(@filename, "r+") do |f|
        f.flock_exclusive do
          data = read(f)

          yield(data)

          f.rewind

          write(f, data)

          f.flush
          f.truncate(f.pos)
        end
      end
    end

    abstract def read(f : IO)
    abstract def write(f : IO, data : T)
  end
end
