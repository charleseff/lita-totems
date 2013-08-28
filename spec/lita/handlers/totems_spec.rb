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
      send_message("totems create chicken")
      expect(replies.last).to eq("Created totem chicken.")

      send_message("totems create chicken")
      expect(replies.last).to eq("Error: totem chicken already exists.")
    end
  end

  describe "destroy" do
    def send_destroy_message
      send_message("totems destroy chicken")
    end

    context "totem is present" do
      before do
        send_message("totems create chicken")
      end

      it "kicks successfully" do
        send_destroy_message
        expect(replies.last).to eq("Destroyed totem chicken.")
      end

    end
    context "totem isn't present" do
      it "kicks unsuccessfully" do
        send_destroy_message
        expect(replies.last).to eq("Error: totem chicken doesn't exist.")
      end

    end

  end

end
