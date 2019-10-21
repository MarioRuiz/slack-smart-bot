
RSpec.describe SlackSmartBot, "bot_help" do
  before(:all) do
    @general_nlist = /General commands even when the Smart Bot is not listening to you/
    @general_list = /General commands only when the Smart Bot is listening to you or on demand/
    @admin = /Admin commands:/
    @master_admin = /Master Admin commands:/
    @direct = /When on a private conversation with the Smart Bot, I'm always listening to you/
    @without_bot = /Commands from Channels without a bot/
    @rules = /These are specific commands for this bot on this Channel/i
  end

  describe "bot help" do
    describe "master channel" do
      channel = :cmaster
      it "responds to admin user in master channel" do
        send_message "bot help", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(@general_nlist)
        expect(buffer(to: channel, from: :ubot).join).to match(@general_list)
        expect(buffer(to: channel, from: :ubot).join).to match(@admin)
        expect(buffer(to: channel, from: :ubot).join).to match(@master_admin)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@direct)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@without_bot)
        expect(buffer(to: channel, from: :ubot).join).to match(@rules)
      end
      it "responds to normal user in master channel" do
        send_message "bot help", from: :user2, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(@general_nlist)
        expect(buffer(to: channel, from: :ubot).join).to match(@general_list)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@admin)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@master_admin)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@direct)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@without_bot)
        expect(buffer(to: channel, from: :ubot).join).to match(@rules)
      end
    end
    describe "bot channel" do
      channel = :cbot2cu
      it "responds to master admin user in bot channel" do
        send_message "bot help", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(@general_nlist)
        expect(buffer(to: channel, from: :ubot).join).to match(@general_list)
        expect(buffer(to: channel, from: :ubot).join).to match(@admin)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@master_admin)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@direct)
        expect(buffer(to: channel, from: :ubot).join).to match(@without_bot)
        expect(buffer(to: channel, from: :ubot).join).to match(@rules)
      end
      it "responds to admin user in bot channel" do
        send_message "bot help", from: :user1, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(@general_nlist)
        expect(buffer(to: channel, from: :ubot).join).to match(@general_list)
        expect(buffer(to: channel, from: :ubot).join).to match(@admin)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@master_admin)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@direct)
        expect(buffer(to: channel, from: :ubot).join).to match(@without_bot)
        expect(buffer(to: channel, from: :ubot).join).to match(@rules)
      end
      it "responds to normal user in bot channel" do
        send_message "bot help", from: :user2, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(@general_nlist)
        expect(buffer(to: channel, from: :ubot).join).to match(@general_list)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@admin)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@master_admin)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@direct)
        expect(buffer(to: channel, from: :ubot).join).to match(@without_bot)
        expect(buffer(to: channel, from: :ubot).join).to match(@rules)
      end
    end

    describe "direct message" do
      it "responds to normal user in direct message when not using rules" do
        send_message "stop using rules from bot1cm", from: :user1, to: :ubot
        sleep 2
        send_message "bot help", from: :user1, to: :ubot
        sleep 2
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).to match(@direct)
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).to match(/ruby RUBY_CODE/i)
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).not_to match(/These are the specific commands for that channel/)
      end
      it "responds to normal user in direct message when using rules" do
        send_message "use rules from bot1cm", from: :user1, to: :ubot
        sleep 2
        send_message "bot help", from: :user1, to: :ubot
        sleep 2
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).to match(@direct)
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).to match(/ruby RUBY_CODE/i)
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).to match(/These are the specific commands for that channel/)
      end
    end

    describe "on extended channel" do
      it "doesn't respond" do
        send_message "!bot help", from: :uadmin, to: :cext1
        expect(buffer(to: :cext1, from: :ubot, tries: 4).join).to eq ""
      end
    end

    describe "on external channel not extended" do
      it "doesn't respond to external demand" do
        command = "bot help"
        send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
        expect(buffer(to: :cexternal, from: :ubot, tries: 4).join).to eq ""
      end
    end
  end

  describe "bot rules" do
    describe "master channel" do
      channel = :cmaster
      it "responds to admin user in master channel" do
        send_message "bot rules", from: :uadmin, to: channel
        sleep 2
        expect(buffer(to: channel, from: :ubot).join).not_to match(@general_nlist)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@general_list)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@admin)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@master_admin)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@direct)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@without_bot)
        expect(buffer(to: channel, from: :ubot).join).to match(@rules)
      end
      it "responds to normal user in master channel" do
        send_message "bot rules", from: :user2, to: channel
        sleep 2
        expect(buffer(to: channel, from: :ubot).join).not_to match(@general_nlist)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@general_list)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@admin)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@master_admin)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@direct)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@without_bot)
        expect(buffer(to: channel, from: :ubot).join).to match(@rules)
      end
    end
    describe "bot channel" do
      channel = :cbot2cu
      it "responds to master admin user in bot channel" do
        send_message "bot rules", from: :uadmin, to: channel
        sleep 2
        expect(buffer(to: channel, from: :ubot).join).not_to match(@general_nlist)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@general_list)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@admin)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@master_admin)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@direct)
        expect(buffer(to: channel, from: :ubot).join).to match(@without_bot)
        expect(buffer(to: channel, from: :ubot).join).to match(@rules)
      end
      it "responds to admin user in bot channel" do
        send_message "bot rules", from: :user1, to: channel
        sleep 2
        expect(buffer(to: channel, from: :ubot).join).not_to match(@general_nlist)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@general_list)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@admin)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@master_admin)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@direct)
        expect(buffer(to: channel, from: :ubot).join).to match(@without_bot)
        expect(buffer(to: channel, from: :ubot).join).to match(@rules)
      end
      it "responds to normal user in bot channel" do
        send_message "bot rules", from: :user2, to: channel
        sleep 2
        expect(buffer(to: channel, from: :ubot).join).not_to match(@general_nlist)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@general_list)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@admin)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@master_admin)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@direct)
        expect(buffer(to: channel, from: :ubot).join).to match(@without_bot)
        expect(buffer(to: channel, from: :ubot).join).to match(@rules)
      end
    end

    describe "direct message" do
      it "responds to normal user in direct message when not using rules" do
        send_message "stop using rules from bot1cm", from: :user1, to: :ubot
        sleep 2
        send_message "bot rules", from: :user1, to: :ubot
        sleep 2
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).to match(@direct)
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).not_to match(/ruby RUBY_CODE/i)
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).not_to match(/These are the specific commands for that channel/)
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).to match(/No rules running. You can use the command `use rules from CHANNEL/)
      end
      it "responds to normal user in direct message when using rules" do
        send_message "use rules from bot1cm", from: :user1, to: :ubot
        sleep 2
        send_message "bot rules", from: :user1, to: :ubot
        sleep 2
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).to match(@direct)
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).not_to match(/ruby RUBY_CODE/i)
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).to match(/These are the specific commands for that channel/)
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).not_to match(/No rules running. You can use the command `use rules from CHANNEL/)
      end
    end

    describe "on external channel not extended" do
      it "responds to external demand" do
        command = "bot rules"
        send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
        expect(buffer(to: :cexternal, from: :ubot, tries: 4).join).not_to eq ""
      end
      it "responds to external demand for bot rules COMMAND" do
        command = "bot rules echo"
        send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
        expect(buffer(to: :cexternal, from: :ubot, tries: 4).join).not_to eq ""
      end
    end
  end

  describe "bot help COMMAND" do
    channel = :cmaster
    it "responds not found" do
      send_message "bot help SSSSSSS", from: :uadmin, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/I didn't find any command starting by `SSSSSSS`/)
    end
    it "responds found for command" do
      send_message "bot help ruby", from: :uadmin, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/ruby RUBY_CODE/)
    end
    it "responds found for rule" do
      send_message "bot help echo", from: :uadmin, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/echo SOMETHING/)
    end
  end
end
