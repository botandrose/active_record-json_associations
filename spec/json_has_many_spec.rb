require "active_record/json_has_many"
require "byebug"

describe ActiveRecord::JsonHasMany do
  before do
    ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

    silence_stream(STDOUT) do
      ActiveRecord::Schema.define do
        create_table :parents do |t|
          t.string :child_ids
          t.string :fuzzy_ids
        end

        create_table :children do |t|
        end

        create_table :pets do |t|
        end
      end
    end

    class Parent < ActiveRecord::Base
      json_has_many :children
      json_has_many :fuzzies, class_name: "Pet"
    end

    class Child < ActiveRecord::Base
    end

    class Pet < ActiveRecord::Base
    end
  end
 
  subject { Parent.new }

  describe "#child_ids" do
    it "is empty by default" do
      expect(subject.child_ids).to eq []
    end

    it "is an accessor" do
      subject.child_ids = [1,2,3]
      expect(subject.child_ids).to eq [1,2,3]
    end
  end

  describe "#children" do
    let(:children) { [Child.create!, Child.create!, Child.create!] }

    it "returns an empty array when there are no children" do
      expect(subject.children).to eq []
    end

    it "finds the children by id" do
      subject.child_ids = [1,2,3]
      expect(subject.children).to eq children
    end
  end

  context "when overriding class name" do
    let(:pets) { [Pet.create!, Pet.create!, Pet.create!] }

    it "returns an empty array when there are no children" do
      expect(subject.fuzzies).to eq []
    end

    it "finds the children by id" do
      subject.fuzzy_ids = [1,2,3]
      expect(subject.fuzzies).to eq pets
    end
  end
end

