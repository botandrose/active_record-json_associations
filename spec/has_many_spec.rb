require "active_record/json_associations"

describe ActiveRecord::JsonAssociations do
  before do
    ActiveRecord::Base.establish_connection database_config

    silence_stream(STDOUT) do
      ActiveRecord::Schema.define do
        create_table :parents, force: true do |t|
          t.string :name
          t.text :child_ids
          t.text :fuzzy_ids
          t.timestamps
        end

        create_table :children, force: true do |t|
          t.timestamps
        end

        create_table :pets, force: true do |t|
          t.timestamps
        end
      end
    end

    class Parent < ActiveRecord::Base
      belongs_to_many :children, touch: true
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

    describe "#build_parent" do
      it "doesnt save the record" do
        parent = subject.build_parent
        expect(parent).to be_new_record
      end

      it "sets the foreign key column" do
        parent = subject.build_parent
        expect(parent.children).to eq([subject])
      end

      it "passes attributes through" do
        parent = subject.build_parent(name: "Parent")
        expect(parent.name).to eq("Parent")
      end
    end

    describe "#create_parent" do
      it "saves the record" do
        parent = subject.create_parent
        expect(parent).to be_persisted
      end

      it "sets the foreign key column" do
        parent = subject.create_parent
        expect(parent.children).to eq([subject])
      end

      it "passes attributes through" do
        parent = subject.create_parent(name: "Parent")
        expect(parent.name).to eq("Parent")
      end

      it "calls create on the model" do
        expect(Parent).to receive(:create)
        subject.create_parent
      end
    end

    describe "#create_parent!" do
      it "saves the record" do
        parent = subject.create_parent!
        expect(parent).to be_persisted
      end

      it "sets the foreign key column" do
        parent = subject.create_parent!
        expect(parent.children).to eq([subject])
      end

      it "passes attributes through" do
        parent = subject.create_parent!(name: "Parent")
        expect(parent.name).to eq("Parent")
      end

      it "calls create! on the model" do
        expect(Parent).to receive(:create!)
        subject.create_parent!
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
