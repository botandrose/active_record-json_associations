require "active_record/json_associations"

describe ActiveRecord::JsonAssociations do
  before do
    ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

    silence_stream(STDOUT) do
      ActiveRecord::Schema.define do
        create_table :parents do |t|
          t.text :child_ids
          t.text :fuzzy_ids
        end

        create_table :children

        create_table :pets
      end
    end

    class Parent < ActiveRecord::Base
      belongs_to_many :children
      belongs_to_many :fuzzies, class_name: "Pet"
    end

    class Child < ActiveRecord::Base
      has_many :parents, json_foreign_key: true
    end

    class Pet < ActiveRecord::Base
      has_many :parents, json_foreign_key: :fuzzy_ids

      # ensure that regular .has_many invocations still work
      has_many :fallback_parents
      has_many :fallback_parents_with_options, class_name: "Pet"
      has_many :fallback_parents_with_scope, -> { order(:id) }
    end
  end
 
  describe ".belongs_to_many :children" do
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

    describe "#child_ids=" do
      it "normalizes to integers" do
        subject.child_ids = ["1",2,"3"]
        expect(subject.child_ids).to eq [1,2,3]
      end

      it "ignores empty strings" do
        subject.child_ids = ["","1","2","3"]
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

      it "is an accessor" do
        subject.children = children
        expect(subject.children).to eq children
      end
    end

    describe "#children?" do
      let(:children) { [Child.create!, Child.create!, Child.create!] }

      it "returns false when there are no children" do
        expect(subject.children?).to be_falsey
      end

      it "returns true when there are children" do
        subject.children = children
        expect(subject.children?).to be_truthy
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

  describe ".has_many :parents, json_foreign_key: true" do
    subject { Child.create! }

    let(:parents) { [Parent.create!, Parent.create!, Parent.create!] }

    describe "#parent_ids" do
      it "is empty by default" do
        expect(subject.parent_ids).to eq []
      end

      it "is an accessor" do
        subject.parent_ids = parents.map(&:id)
        expect(subject.parent_ids).to eq parents.map(&:id)
      end
    end

    describe "#parent_ids=" do
      before { parents } # ensure parents exist

      it "normalizes to integers" do
        subject.parent_ids = ["1",2,"3"]
        expect(subject.parent_ids).to eq [1,2,3]
      end

      it "ignores empty strings" do
        subject.parent_ids = ["","1","2","3"]
        expect(subject.parent_ids).to eq [1,2,3]
      end
    end

    describe "#parents" do
      it "returns an empty array when there are no parents" do
        expect(subject.parents).to eq []
      end

      it "finds the children by id" do
        subject.parent_ids = parents.map(&:id)
        expect(subject.parents).to eq parents
      end

      it "is an accessor" do
        subject.parents = parents
        expect(subject.parents).to eq parents
      end

      context "finds records with the specified id" do
        let(:child) { Child.create! }

        it "as the whole json array" do
          parent = Parent.create(children: [child])
          expect(child.parents).to eq [parent]
        end

        it "at the beginning of the json array" do
          parent = Parent.create(children: [child, Child.create!])
          expect(child.parents).to eq [parent]
        end

        it "in the middle of the json array" do
          parent = Parent.create(children: [Child.create!, child, Child.create!])
          expect(child.parents).to eq [parent]
        end

        it "at the end of the json array" do
          parent = Parent.create(children: [Child.create!, child])
          expect(child.parents).to eq [parent]
        end
      end
    end

    describe "#parents?" do
      it "returns false when there are no parents" do
        expect(subject.parents?).to be_falsey
      end

      it "returns true when there are parents" do
        subject.parents = parents
        expect(subject.parents?).to be_truthy
      end
    end
  end

  describe ".has_many :parents, json_foreign_key: :fuzzy_ids" do
    subject { Pet.create! }

    let(:parents) { [Parent.create!, Parent.create!, Parent.create!] }

    describe "#parent_ids" do
      it "is empty by default" do
        expect(subject.parent_ids).to eq []
      end

      it "is an accessor" do
        subject.parent_ids = parents.map(&:id)
        expect(subject.parent_ids).to eq parents.map(&:id)
      end
    end

    describe "#parents" do
      it "returns an empty array when there are no parents" do
        expect(subject.parents).to eq []
      end

      it "finds the parents by id" do
        subject.parent_ids = parents.map(&:id)
        expect(subject.parents).to eq parents
      end

      it "is an accessor" do
        subject.parents = parents
        expect(subject.parents).to eq parents
      end

      context "finds records with the specified id" do
        let(:pet) { Pet.create! }

        it "as the whole json array" do
          parent = Parent.create(fuzzies: [pet])
          expect(pet.parents).to eq [parent]
        end

        it "at the beginning of the json array" do
          parent = Parent.create(fuzzies: [pet, Pet.create!])
          expect(pet.parents).to eq [parent]
        end

        it "in the middle of the json array" do
          parent = Parent.create(fuzzies: [Pet.create!, pet, Pet.create!])
          expect(pet.parents).to eq [parent]
        end

        it "at the end of the json array" do
          parent = Parent.create(fuzzies: [Pet.create!, pet])
          expect(pet.parents).to eq [parent]
        end
      end
    end

    describe "#parents?" do
      it "returns false when there are no parents" do
        expect(subject.parents?).to be_falsey
      end

      it "returns true when there are parents" do
        subject.parents = parents
        expect(subject.parents?).to be_truthy
      end
    end
  end
end

