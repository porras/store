require "./spec_helper"

struct City
  def initialize(@name, @country, @lat, @lon)
  end

  JSON.mapping({
    name:    String,
    country: String,
    lat:     Float64,
    lon:     Float64,
  })
end

struct Person
  def initialize(@name, @age, @city)
  end

  JSON.mapping({
    name: String,
    age:  Int32,
    city: City,
  })
end

class Dummy
  def initialize(@value)
  end

  JSON.mapping({
    value: Int32,
  })
end

class Nullable
  def initialize
  end

  property value

  JSON.mapping({
    value: {type: String, nilable: true},
  })
end

Spec.before_each { File.delete("/tmp/data.json") if File.exists?("/tmp/data.json") }

describe Store do
  context "JSON" do
    context "Hash(String, Int32)" do
      it "stores and reads values" do
        store = JSON::Store(Hash(String, Int32)).new("/tmp/data.json")

        store.transaction do |data|
          data["key1"] = 1
          data["key2"] = 2
        end

        store.transaction do |data|
          data["key1"].should eq(1)
          data["key2"].should eq(2)
        end

        store.transaction do |data|
          data["key1"] += 1
          data["key2"] += 1
        end

        store.transaction do |data|
          data["key1"].should eq(2)
          data["key2"].should eq(3)
        end

        data = Hash(String, Int32).from_json(File.read("/tmp/data.json"))
        data["key1"].should eq(2)
        data["key2"].should eq(3)
      end

      it "removed data" do
        store = JSON::Store(Hash(String, Int32)).new("/tmp/data.json")

        store.transaction do |data|
          data["key1"] = 1
          data["key2"] = 2
        end

        store.transaction do |data|
          data.delete("key1")
        end

        store.transaction do |data|
          data["key1"]?.should be_nil
          data["key2"].should eq(2)
        end
      end
    end

    context "custom serializable data" do
      it "stores and reads values" do
        store = JSON::Store(Array(Person)).new("/tmp/data.json")

        store.transaction do |people|
          people.size.should eq(0)

          people << Person.new("Sergio", 35, City.new("Berlin", "Germany", 52.516667, 13.383333))
        end

        store.transaction do |people|
          people.size.should eq(1)

          people.first.name.should eq("Sergio")
          people.first.age.should eq(35)
          people.first.city.name.should eq("Berlin")
          people.first.city.country.should eq("Germany")

          people << Person.new("Fulano", 32, City.new("Madrid", "Spain", 40.383333, -3.716667))
        end

        store.transaction do |people|
          people.size.should eq(2)

          people.last.name.should eq("Fulano")
          people.last.age.should eq(32)
          people.last.city.name.should eq("Madrid")
          people.last.city.country.should eq("Spain")
        end

        store.transaction do |people|
          people.first.age += 1
        end
      end
    end

    context "mutable data" do
      it "can be mutated" do
        store = JSON::Store(Array(Dummy)).new("/tmp/data.json")

        store.transaction do |data|
          data << Dummy.new(1)
        end

        store.transaction do |data|
          data.first.value.should eq(1)
          data.first.value += 1
        end

        store.transaction do |data|
          data.first.value.should eq(2)
        end
      end
    end

    context "custom data as root" do
      it "can be initialized and then mutated" do
        store = JSON::Store(Nullable).new("/tmp/data.json")

        store.transaction do |nullable|
          nullable.value.should be_nil
          nullable.value = "Hello"
        end

        store.transaction do |nullable|
          nullable.value.should eq("Hello")
        end
      end
    end
  end
end
