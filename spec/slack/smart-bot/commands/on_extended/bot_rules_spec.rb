
RSpec.describe SlackSmartBot, "bot_rules" do
  describe "extended channel" do
    channel = :cext1
    user = :uadmin

    it "responds to bot rules" do
      send_message "bot rules", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Rules from channel bot1cm/)
      expect(buffer(to: channel, from: :ubot).join).to match(/To run the commands on this extended channel, add `!`, `!!` or `\^` before the command./)
      expect(buffer(to: channel, from: :ubot).join).to match(/which rules for bot1cm/)
    end
    it "responds to bot rules COMMAND" do
      send_message "bot rules which", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/which rules for bot1cm/)
      send_message "bot rules aaaaa", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/I didn't find any command with `aaaaa`/)
    end
    it 'returns help searching on rule description' do
      send_message "bot help run the process", from: user, to: channel
      sleep 2
      expect(buffer(to: channel, from: :ubot).join).to match(/run something/i) # message
    end
  end
end
