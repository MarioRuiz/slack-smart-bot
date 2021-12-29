
RSpec.describe SlackSmartBot, "bot_help" do
  before(:all) do
    @general_command_msg = /General commands on any channel where the Smart Bot is a member/i
    @general_nlist = /General commands on Bot channel even when the Smart Bot is not listening to you/
    @general_list = /General commands on Bot channel only when the Smart Bot is listening to you or on demand/
    @admin = /Admin commands:/
    @master_admin = /Master Admin commands:/
    @direct = /When on a private conversation with the Smart Bot, I'm always listening to you/
    @without_bot = /Commands from Channels without a bot/
    @rules = /Specific commands for this bot on this Channel/i
  end

  describe "bot help" do
    describe "master channel" do
      channel = :cmaster
      it "responds to admin user in master channel" do
        send_message "bot help expanded", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(@general_command_msg)
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
        expect(buffer(to: channel, from: :ubot).join).to match(@general_command_msg)
        expect(buffer(to: channel, from: :ubot).join).to match(@general_nlist)
        expect(buffer(to: channel, from: :ubot).join).to match(@general_list)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@admin)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@master_admin)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@direct)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@without_bot)
        expect(buffer(to: channel, from: :ubot).join).to match(/Specific commands on this Channel/i)
      end
    end
    describe "bot channel" do
      channel = :cbot2cu
      it "responds to master admin user in bot channel" do
        send_message "bot help expanded", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(@general_command_msg)
        expect(buffer(to: channel, from: :ubot).join).to match(@general_nlist)
        expect(buffer(to: channel, from: :ubot).join).to match(@general_list)
        expect(buffer(to: channel, from: :ubot).join).to match(@admin)
        expect(buffer(to: channel, from: :ubot).join).to match(@master_admin)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@direct)
        expect(buffer(to: channel, from: :ubot).join).to match(@without_bot)
        expect(buffer(to: channel, from: :ubot).join).to match(/specific commands for this bot on this Channel/i)
      end
      it "responds to admin user in bot channel" do
        send_message "bot help expanded", from: :user1, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(@general_command_msg)
        expect(buffer(to: channel, from: :ubot).join).to match(@general_nlist)
        expect(buffer(to: channel, from: :ubot).join).to match(@general_list)
        expect(buffer(to: channel, from: :ubot).join).to match(@admin)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@master_admin)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@direct)
        expect(buffer(to: channel, from: :ubot).join).to match(@without_bot)
        expect(buffer(to: channel, from: :ubot).join).to match(@rules)
      end
      it "responds to normal user in bot channel" do
        send_message "bot help expanded", from: :user2, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(@general_command_msg)
        expect(buffer(to: channel, from: :ubot).join).to match(@general_nlist)
        expect(buffer(to: channel, from: :ubot).join).to match(@general_list)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@admin)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@master_admin)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@direct)
        expect(buffer(to: channel, from: :ubot).join).to match(@without_bot)
        expect(buffer(to: channel, from: :ubot).join).to match(@rules)
      end
      it 'responds short version of the help by default' do
        send_message "bot help", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/If you want to see the \*expanded\* version/) # message
        expect(buffer(to: channel, from: :ubot).join).to match(/add shortcut NAME: COMMAND/) # first command
        expect(buffer(to: channel, from: :ubot).join).not_to match(/add sc NAME: COMMAND/) # not first command
        expect(buffer(to: channel, from: :ubot).join).to match(/It will show the routines of the channel/) # first description
        expect(buffer(to: channel, from: :ubot).join).not_to match(/it will show all the routines from all channels/) # not first description
        expect(buffer(to: channel, from: :ubot).join).to match(/add shortcut for all Spanish/) #first example
        expect(buffer(to: channel, from: :ubot).join).not_to match(/shortcut Spanish Account/) # not first example
      end
      it 'responds expanded version of the help' do
        send_message "bot help expanded", from: :uadmin, to: channel
        sleep 2
        expect(buffer(to: channel, from: :ubot).join).not_to match(/If you want to see the *expanded* version/) # message
        expect(buffer(to: channel, from: :ubot).join).to match(/`bot help`/) # first command
        expect(buffer(to: channel, from: :ubot).join).to match(/`bot help COMMAND`/) # not first command
        expect(buffer(to: channel, from: :ubot).join).to match(/it will display the help content for a random command/) # first description
        expect(buffer(to: channel, from: :ubot).join).to match(/if used 'rule' then it will display a random rule/) # not first description
        expect(buffer(to: channel, from: :ubot).join).to match(/react to #sales 1622550707.012100/) #first example
        expect(buffer(to: channel, from: :ubot).join).to match(/react to #sales p1622550707012100/) # not first example
      end
      it 'returns help searching on command description' do
        send_message "bot help 'rule' then it will display a random rule", from: :uadmin, to: channel
        sleep 2
        expect(buffer(to: channel, from: :ubot).join).to match(/suggest command/i) # message
      end
      it 'returns help searching on rule description' do
        send_message "bot help run the process", from: :uadmin, to: channel
        sleep 2
        expect(buffer(to: channel, from: :ubot).join).to match(/run something/i) # message
      end
      it 'responds on a thread if lines>50' do
        send_message "bot help", from: :uadmin, to: channel
        sleep 2
        expect(buffer(to: channel, from: :ubot).join).to match(/Since there are many lines returned the results are returned on a thread by default/)
        expect(buffer(to: channel, from: :ubot).join).to match(/^:on_thread:/)  
      end
    end

    describe "direct message" do
      it "responds to normal user in direct message when not using rules" do
        send_message "stop using rules from bot1cm", from: :user1, to: :ubot
        sleep 2
        send_message "bot help expanded", from: :user1, to: :ubot
        sleep 2
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).to match(@direct)
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).to match(/ruby RUBY_CODE/i)
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).not_to match(/These are the specific commands for that channel/)
      end
      it "responds to normal user in direct message when not using rules and calling bot rules" do
        send_message "stop using rules from bot1cm", from: :user1, to: :ubot
        sleep 2
        send_message "bot rules", from: :user1, to: :ubot
        sleep 2
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).to match(/Specific commands on this Channel/)
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).to match(/echo SOMETHING/i)
      end
      it "responds to normal user in direct message when using rules" do
        send_message "use rules from bot1cm", from: :user1, to: :ubot
        sleep 2
        send_message "bot help", from: :user1, to: :ubot
        sleep 2
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).not_to match(@direct) #not expanded
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).to match(/ruby RUBY_CODE/i)
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).to match(/These are the specific commands for that channel/)
      end
    end

    describe "on extended channel" do
      it "responds on extended channel" do
        send_message "bot help", from: :uadmin, to: :cext1
        expect(buffer(to: :cext1, from: :ubot).join).to match(@general_command_msg)
      end
    end

    describe "on external channel not extended" do
      it "doesn't respond to external demand" do
        command = "bot help"
        send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
        expect(buffer(to: :cexternal, from: :ubot).join).to  match(/I don't understand/)
        expect(buffer(to: :cexternal, from: :ubot).join).to  match(/Take in consideration when on external calls/)
      end
      it "responds" do
        command = "bot help"
        send_message "#{command}", from: :uadmin, to: :cexternal
        sleep 1
        expect(buffer(to: :cexternal, from: :ubot).join).to  match(/General commands on any channel where the Smart Bot is a member/i)
        expect(buffer(to: :cexternal, from: :ubot).join).to  match(/it will display this help. For a more detailed help/i)
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
        expect(buffer(to: channel, from: :ubot).join).to match(/Specific commands on this Channel/i)
      end
      it "responds to normal user in master channel" do
        send_message "bot rules expanded", from: :user2, to: channel
        sleep 2
        expect(buffer(to: channel, from: :ubot).join).not_to match(@general_nlist)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@general_list)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@admin)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@master_admin)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@direct)
        expect(buffer(to: channel, from: :ubot).join).not_to match(@without_bot)
        expect(buffer(to: channel, from: :ubot).join).to match(@rules)
      end
      it "responds not found" do
        send_message "bot rules SSSSSSS", from: :user2, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/I didn't find any rule with `SSSSSSS`/)
      end
      it "includes help from external loaded or required rules" do
        #for example from general_rules.rb
        send_message "bot rules echo", from: :user2, to: channel
        expect(buffer(to: channel, from: :ubot).join).not_to match(/I didn't find any rule with `echo`/)
        expect(buffer(to: channel, from: :ubot).join).to match(/echo SOMETHING/)
      end

    end
    describe "bot channel" do
      channel = :cbot2cu
      it "responds to master admin user in bot channel" do
        send_message "bot rules expanded", from: :uadmin, to: channel
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
        send_message "bot rules expanded", from: :user1, to: channel
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
        send_message "bot rules expanded", from: :user2, to: channel
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
        send_message "bot rules expanded", from: :user1, to: :ubot
        sleep 2
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).to match(@direct)
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).not_to match(/ruby RUBY_CODE/i)
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).not_to match(/These are the specific commands for that channel/)
        #expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).to match(/No rules running. You can use the command `use rules from CHANNEL/)
      end
      it "responds to normal user in direct message when using rules" do
        send_message "use rules from bot1cm", from: :user1, to: :ubot
        sleep 2
        send_message "bot rules", from: :user1, to: :ubot
        sleep 2
        expect(buffer(to: DIRECT.user1.ubot, from: :ubot).join).not_to match(@direct) #not expanded
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
      expect(buffer(to: channel, from: :ubot).join).to match(/I didn't find any command with `SSSSSSS`/)
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
