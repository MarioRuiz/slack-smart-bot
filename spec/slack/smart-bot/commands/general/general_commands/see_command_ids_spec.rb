
RSpec.describe SlackSmartBot, "see_command_ids" do
  describe "see command ids" do
    describe "on bot" do
      channel = :cbot1cm

      before(:all) do
        send_message "see command ids", from: :uadmin , to: channel
        @resp = buffer(to: channel, from: :ubot).join
      end
      
      it "displays general commands" do
        expect(@resp).to match(/\*General Commands\*:.+add_admin/i)
      end

      it "displays on bot general" do
        expect(@resp).to match(/\*on bot general\*:.+bot_stats/i)
      end

      it "displays on bot on demand" do
        expect(@resp).to match(/\*on bot on demand\*:.+add_shortcut/i)
      end

      it "displays on bot admin" do
        expect(@resp).to match(/\*on bot admin\*:.+add_routine/i)
      end

      it "displays on bot master admin" do
        expect(@resp).to match(/\*on bot master admin\*:.+delete_message/i)
      end

      it "displays on extended" do
        expect(@resp).to match(/\*on extended\*:.+bot_rules/i)
      end

      it "displays on master" do
        expect(@resp).to match(/\*on master\*:.+create_bot/i)
      end

      it "displays on master admin" do
        expect(@resp).to match(/\*on master admin\*:.+kill_bot_on_channel/i)
      end

      it "displays on master master admin" do
        expect(@resp).to match(/\*on master master admin\*:.+exit_bot/i)
      end

    end

  end
end
