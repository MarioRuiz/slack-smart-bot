
RSpec.describe SlackSmartBot, "allow_access" do
    describe "on channel bot" do
      channel = :cbot1cm
      user = :user1
  
      before(:all) do
        send_message "!set_access", from: user, to: channel
      end
      after(:all) do
        send_message "!unset_access", from: user, to: channel
        send_message "bye bot", from: user, to: channel
      end
      
      it "works when access granted" do
        send_message "!ruby puts 'a'", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot)[-1]).to match(/^a$/)
      end
  
      it "displays not allowed if user doesn't have access to the command bot_help" do
        send_message "!bot help", from: user, to: channel
        expect(buffer(to: channel, from: :ubot)[-1]).to match(/^You don't have access to use this command, please contact an Admin to be able to use it/)
      end
      it "displays not allowed if user doesn't have access to the command bot_rules" do
        send_message "!bot rules", from: user, to: channel
        expect(buffer(to: channel, from: :ubot)[-1]).to match(/^You don't have access to use this command, please contact an Admin to be able to use it/)
      end
      it "displays not allowed if user doesn't have access to the command bot_status" do
        send_message "!bot status", from: user, to: channel
        expect(buffer(to: channel, from: :ubot)[-1]).to match(/^You don't have access to use this command, please contact an Admin to be able to use it/)
      end
      it "displays not allowed if user doesn't have access to the command use_rules" do
        send_message "!use rules from #bot2cu", from: user, to: channel
        expect(buffer(to: channel, from: :ubot)[-1]).to match(/^You don't have access to use this command, please contact an Admin to be able to use it/)
      end
      it "displays not allowed if user doesn't have access to the command add_shortcut" do
        send_message "!add shortcut ss: echo a", from: user, to: channel
        expect(buffer(to: channel, from: :ubot)[-1]).to match(/^You don't have access to use this command, please contact an Admin to be able to use it/)
      end
      it "displays not allowed if user doesn't have access to the command delete_shortcut" do
        send_message "!delete shortcut ss", from: user, to: channel
        expect(buffer(to: channel, from: :ubot)[-1]).to match(/^You don't have access to use this command, please contact an Admin to be able to use it/)
      end
      it "displays not allowed if user doesn't have access to the command see_shortcuts" do
        send_message "!see shortcuts", from: user, to: channel
        expect(buffer(to: channel, from: :ubot)[-1]).to match(/^You don't have access to use this command, please contact an Admin to be able to use it/)
      end
      it "displays not allowed if user doesn't have access to the command ruby_code" do
        send_message "!ruby puts 'a'", from: user, to: channel
        expect(buffer(to: channel, from: :ubot)[-1]).to match(/^You don't have access to use this command, please contact an Admin to be able to use it/)
      end
      it "displays not allowed if user doesn't have access to the command repl" do
        send_message "!repl", from: user, to: channel
        expect(buffer(to: channel, from: :ubot)[-1]).to match(/^You don't have access to use this command, please contact an Admin to be able to use it/)
      end
      it "displays not allowed if user doesn't have access to the command create_bot" do
        send_message "!create bot on #bot2cm", from: user, to: channel
        expect(buffer(to: channel, from: :ubot)[-1]).to match(/^You don't have access to use this command, please contact an Admin to be able to use it/)
      end
      
    end
end