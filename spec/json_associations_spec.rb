require "active_record/json_associations"

describe ActiveRecord::JsonAssociations do
  before do
    ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

    silence_stream(STDOUT) do
      ActiveRecord::Schema.define do
        create_table :parents do |t|
          t.text :child_ids
          t.text :fuzzy_ids
          t.timestamps
        end

        create_table :children do |t|
          t.timestamps
        end

        create_table :pets do |t|
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
 
  describe ".belongs_to_many :children" do
    subject { Parent.new }
    let!(:winner) { Parent.create! }

    describe ".child_ids_including" do
      context "finds records with the specified id" do
        let(:child) { Child.create! }

        it "as the whole json array" do
          parent = Parent.create(children: [child])
          expect(Parent.child_ids_including(child.id)).to eq [parent]
        end

        it "at the beginning of the json array" do
          parent = Parent.create(children: [child, Child.create!])
          expect(Parent.child_ids_including(child.id)).to eq [parent]
        end

        it "in the middle of the json array" do
          parent = Parent.create(children: [Child.create!, child, Child.create!])
          expect(Parent.child_ids_including(child.id)).to eq [parent]
        end

        it "at the end of the json array" do
          parent = Parent.create(children: [Child.create!, child])
          expect(Parent.child_ids_including(child.id)).to eq [parent]
        end
      end

      context "finds records including any of the specified array of ids" do
        let(:peter) { Child.create! }
        let(:paul) { Child.create! }

        it "both as the whole json array" do
          parent = Parent.create(children: [peter, paul])
          expect(Parent.child_ids_including(any: [peter.id, paul.id])).to eq [parent]
        end

        it "one as the whole json array" do
          parent = Parent.create(children: [peter])
          expect(Parent.child_ids_including(any: [peter.id, paul.id])).to eq [parent]
        end

        it "the other as the whole json array" do
          parent = Parent.create(children: [paul])
          expect(Parent.child_ids_including(any: [peter.id, paul.id])).to eq [parent]
        end

        it "both at the beginning of the json array" do
          parent = Parent.create(children: [peter, paul, Child.create!])
          expect(Parent.child_ids_including(any: [peter.id, paul.id])).to eq [parent]
        end

        it "one at the beginning of the json array" do
          parent = Parent.create(children: [peter, Child.create!])
          expect(Parent.child_ids_including(any: [peter.id, paul.id])).to eq [parent]
        end

        it "the other at the beginning of the json array" do
          parent = Parent.create(children: [paul, Child.create!])
          expect(Parent.child_ids_including(any: [peter.id, paul.id])).to eq [parent]
        end

        it "both in the middle of the json array" do
          parent = Parent.create(children: [Child.create!, peter, paul, Child.create!])
          expect(Parent.child_ids_including(any: [peter.id, paul.id])).to eq [parent]
        end

        it "one in the middle of the json array" do
          parent = Parent.create(children: [Child.create!, peter, Child.create!])
          expect(Parent.child_ids_including(any: [peter.id, paul.id])).to eq [parent]
        end

        it "the other in the middle of the json array" do
          parent = Parent.create(children: [Child.create!, paul, Child.create!])
          expect(Parent.child_ids_including(any: [peter.id, paul.id])).to eq [parent]
        end

        it "both at the end of the json array" do
          parent = Parent.create(children: [Child.create!, peter, paul])
          expect(Parent.child_ids_including(any: [peter.id, paul.id])).to eq [parent]
        end

        it "one at the end of the json array" do
          parent = Parent.create(children: [Child.create!, peter])
          expect(Parent.child_ids_including(any: [peter.id, paul.id])).to eq [parent]
        end

        it "the other at the end of the json array" do
          parent = Parent.create(children: [Child.create!, paul])
          expect(Parent.child_ids_including(any: [peter.id, paul.id])).to eq [parent]
        end
      end
    end

    describe "touch: true" do
      around do |example|
        old_zone = Time.zone
        Time.zone = "UTC"
        example.run
        Time.zone = old_zone
      end

      it "touches associated records when touch option is true" do
        old_time = 1.year.ago.round
        new_time = 1.second.ago.round
        Timecop.freeze(new_time) do
          children = [Child.create!(updated_at: old_time), Child.create!(updated_at: old_time)]
          fuzzies = [Pet.create!(updated_at: old_time), Pet.create!(updated_at: old_time)]
          parent = Parent.create!(children: children, fuzzies: fuzzies)
          expect(children.each(&:reload).map(&:updated_at)).to eq [new_time, new_time]
          expect(fuzzies.each(&:reload).map(&:updated_at)).to eq [old_time, old_time]
        end
      end
    end

    describe "#child_ids" do
      it "is empty by default" do
        expect(subject.child_ids).to eq []
      end

      it "is an accessor" do
        subject.child_ids = [1,2,3]
        expect(subject.child_ids).to eq [1,2,3]
      end

      it "can be pushed to" do
        subject.child_ids << 1
        subject.child_ids << 2
        subject.child_ids << 3
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

      it "finds the children by id order" do
        subject.child_ids = [3,2,1]
        expect(subject.children).to eq children.reverse
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

