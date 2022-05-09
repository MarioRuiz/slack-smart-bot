RSpec.describe SlackSmartBot, "see_command_ids" do
  describe "see command ids" do
    describe "using channel" do
      channel = :cbot1cm

      before(:all) do
        send_message "use rules from bot2cu", from: :uadmin, to: channel
        send_message "see command ids", from: :uadmin, to: channel
        @resp = buffer(to: channel, from: :ubot).join
      end

      after(:all) do
        send_message "stop using rules from bot2cu", from: :uadmin, to: channel
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

      it "doesn't display on extended" do
        expect(@resp).not_to match(/\*on extended\*:.+bot_rules/i)
      end

      it "doesn't display on master" do
        expect(@resp).not_to match(/\*on master\*:.+create_bot/i)
      end

      it "doesn't display on master admin" do
        expect(@resp).not_to match(/\*on master admin\*:.+kill_bot_on_channel/i)
      end

      it "doesn't display on master master admin" do
        expect(@resp).not_to match(/\*on master master admin\*:.+exit_bot/i)
      end

      it "displays general rules" do
        expect(@resp).to match(/\*general rules\*:.+echo/i)
      end

      it "displays rules" do
        expect(@resp).to match(/\*rules\*:.+doom/i)
      end
    end
  end
end
