require "spec_helper"

describe Lita::Handlers::Totems, lita_handler: true do
  it { routes("totems add foo").to(:add) }
  it { routes("totem add foo").to(:add) }
  it { routes("totem join foo").to(:add) }
  it { doesnt_route("totems add ").to(:add) }
  it { doesnt_route("tote add foo").to(:add) }
  it { routes("totems kick foo").to(:kick) }
  it { routes("totems kick foo bob").to(:kick) }

  describe "create" do
    it "creates a totem" do
      send_message('totems create chicken')
      expect(replies.last).to eq('Created totem "chicken".')

      send_message('totems create chicken')
      expect(replies.last).to eq('Error: totem "chicken" already exists.')
    end
  end

  describe "destroy" do
    def send_destroy_message
      send_message('totems destroy chicken')
    end

    context "totem is present" do
      before do
        send_message('totems create chicken')
      end

      it "kicks successfully" do
        send_destroy_message
        expect(replies.last).to eq('Destroyed totem "chicken".')
      end

    end
    context "totem isn't present" do
      it "kicks unsuccessfully" do
        send_destroy_message
        expect(replies.last).to eq(%{Error: totem "chicken" doesn't exist.})
      end

    end

  end

  describe "add" do
    let(:carl) { Lita::User.create(123, name: "Carl") }
    let(:user_generator) { Class.new do
      def initialize
        @id = 0
      end

      def generate
        @id += 1
        Lita::User.create(@id, name: "person_#{@id}")
      end
    end.new
    }

    context "totem exists" do
      before do
        send_message("totems create chicken")
      end

      context "when nobody is in line" do
        it "gives totem to the user" do
          send_message("totems add chicken", as: carl)
          expect(replies.last).to eq('Carl, you now have totem "chicken".')
        end
      end
      context "when people are in line" do
        before do
          send_message("totems add chicken", as: user_generator.generate)
          send_message("totems add chicken", as: user_generator.generate)
        end
        it "adds user to the queue" do
          send_message("totems add chicken", as: carl)
          expect(replies.last).to eq('Carl, you are 2nd in line for totem "chicken".')
        end
      end
    end

    context "when the totem doesn't exist" do
      it "lets user know" do
        send_message("totems add chicken", as: carl)
        expect(replies.last).to eq('Error: there is no totem "chicken".')

      end

    end


  end

end
