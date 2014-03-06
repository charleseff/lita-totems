require "spec_helper"

describe Lita::Handlers::Totems, lita_handler: true do
  it { routes("totems add foo").to(:add) }
  it { routes("totem add foo").to(:add) }
  it { routes("totem join foo").to(:add) }
  it { doesnt_route("totems add ").to(:add) }
  it { doesnt_route("tote add foo").to(:add) }
  it { routes("totems kick foo").to(:kick) }
  it { routes("totems kick foo bob").to(:kick) }
  it { routes("totems").to(:info) }
  it { routes("totems info").to(:info) }
  it { routes("totems info chicken").to(:info) }

  let(:totem_creator) { Class.new do
    def initialize
      @id = 0
    end

    def create(container)
      @id  += 1
      name = "totem_#{@id}"
      container.send_message("totems create #{name}")
      name
    end
  end.new
  }

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
  let(:another_user) { user_generator.generate }
  let(:yet_another_user) { user_generator.generate }

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
          expect(replies.last).to eq('Carl, you are #2 in line for totem "chicken".')
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

  describe "yield" do
    before do
      send_message("totems create chicken")
    end

    context "when user has one totem" do
      before do
        Timecop.freeze("2014-03-01 11:00:00") do
          send_message("totems add chicken", as: carl)
        end
      end

      context "someone else is in line" do
        before do
          Timecop.freeze("2014-03-01 12:00:00") do
            send_message("totems add chicken", as: another_user)
          end
        end
        it "yields that totem, gives to the next person in line" do
          expect(robot).to receive(:send_messages) do |target, message|
            expect(target.id).to eq(another_user.id)
            expect(message).to eq(%{You are now in possession of totem "chicken."})
          end
          send_message("totems yield", as: carl)
          # todo: check for message to other user
          expect(replies.last).to eq("You have yielded the totem to #{another_user.id}.")
        end
        it "updates the waiting since value for the new holder" do
          Timecop.freeze("2014-03-01 13:00:00") do
            send_message("totems info chicken")
            expect(replies.last).to eq <<-END
1. Carl (held for 2h)
2. Test User (waiting for 1h)
            END
            send_message("totems yield", as: carl)
            send_message("totems info chicken")
            expect(replies.last).to eq <<-END
1. Test User (held for 0s)
            END
          end
        end
      end
      context "nobody else is in line" do
        it "yields the totem" do
          send_message("totems yield", as: carl)
          expect(replies.last).to eq(%{You have yielded the "chicken" totem.})
        end
      end
    end
    context "when user has no totems" do
      it "sends an error" do
        send_message("totems yield", as: carl)
        expect(replies.last).to eq("Error: You do not have any totems to yield.")
      end
    end
    context "when user has multiple totems" do
      let(:other_totem) { totem_creator.create(self) }
      before do
        send_message("totems add chicken", as: carl)
        send_message("totems add #{other_totem}", as: carl)
      end
      context "when specifying a totem" do
        context "user doesn't have that totem" do
          it "sends error message" do
            send_message("totems yield duck", as: carl)
            expect(replies.last).to eq(%{Error: You don't own the "duck" totem.})
          end
        end
        context "user has that totem" do
          it "yields totem" do
            send_message("totems yield chicken", as: carl)
            expect(replies.last).to eq(%{You have yielded the "chicken" totem.})
          end

        end
      end
      context "when not specifying a totem" do
        it "sends a message about which totem it can yield" do
          send_message("totems yield", as: carl)
          expect(replies.last).to eq(%{You must specify a totem to yield.  Totems you own: ["chicken", "#{other_totem}"]})
        end
      end

    end

  end

  describe "kick" do
    before do
      send_message("totems create chicken")
    end
    context "there is a user owning the totem" do
      before do
        send_message("totems add chicken", as: another_user)
        send_message("totems add chicken", as: carl)
      end
      it "should notify that user that she has been kicked" do
        expect(robot).to receive(:send_messages) do |target, message|
          expect(target.id).to eq(another_user.id)
          expect(message).to eq(%{You have been kicked from totem "chicken".})
        end
        send_message("totems kick chicken")

      end
      it "should notify next user in line that she now has the totem" do
        send_message("totems kick chicken")
        expect(replies.last).to eq(%{You are now in possession of totem "chicken".})
      end

    end

    context "nobody owns that totem" do
      it "sends an error" do
        send_message("totems kick chicken")
        expect(replies.last).to eq(%{Error: Nobody owns totem "chicken" so you can't kick someone from it.})
      end
    end
  end

  describe "info" do
    before do
      Timecop.freeze("2014-03-01 12:00:00") do
        send_message("totems create chicken")
        send_message("totems create duck")
        send_message("totems create ball")
        send_message("totems add chicken", as: carl)
        send_message("totems add chicken", as: another_user)
        send_message("totems add chicken", as: yet_another_user)
        send_message("totems add duck", as: yet_another_user)
        send_message("totems add duck", as: carl)
      end
    end
    context "totem is passed" do
      it "shows info for just that totem" do
        Timecop.freeze("2014-03-01 13:00:00") do
          send_message("totems info chicken")
          expect(replies.last).to eq <<-END
1. Carl (held for 1h)
2. Test User (waiting for 1h)
3. person_2 (waiting for 1h)
          END
        end
      end
    end

    context "totem isn't passed" do
      it "shows info for all totems" do
        Timecop.freeze("2014-03-02 13:00:00") do
          send_message("totems info")
          expect(replies.last).to include <<-END
- chicken
  1. Carl (held for 1d 1h)
  2. Test User (waiting for 1d 1h)
  3. person_2 (waiting for 1d 1h)
          END
          expect(replies.last).to include <<-END
- duck
  1. person_2 (held for 1d 1h)
  2. Carl (waiting for 1d 1h)
          END
          expect(replies.last).to include <<-END
- ball
          END
        end
      end
    end

  end

end
