
RSpec.describe SlackSmartBot, "ping_team" do
  describe "ping team" do
    describe "on DM" do
      channel = DIRECT.uadmin.ubot
      user = :uadmin

      before(:each) do
        send_message "add team example dev <@#{USER1}> <@#{USER2}> <@UXXXXXXXX> members <##{CEXTERNAL}|external_channel> contact_us <##{CEXTERNAL}|external_channel> : beautiful info", from: user , to: channel
      end
      after(:all) do
        send_message "delete team example", from: user , to: channel
        send_message "yes", from: user , to: channel
      end

      it 'is not possible to be called from a DM' do
        send_message "ping team example dev this is the message", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/This command cannot be called from a DM/i)
        send_message "contact team example dev this is the message", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/This command cannot be called from a DM/i)
      end
    end

    describe "on external channel" do
      channel = :cexternal
      user = :uadmin
      before(:all) do
        send_message "add team example dev <@#{USER1}> <@#{USER2}> <@UXXXXXXXX> members <##{CEXTERNAL}|external_channel> contact_us <##{CEXTERNAL}|external_channel> : beautiful info", from: user , to: channel
        clean_buffer()
      end
      after(:all) do
        send_message "delete team example", from: user , to: channel
        send_message "yes", from: user , to: channel
      end

      it "displays error message if team doesn't exist" do
        team_name = 'xxxxxxxxx'
        send_message "ping team #{team_name} dev this is the message", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/It seems like the team \*#{team_name}\* doesn't exist/i)
        send_message "contact team #{team_name} dev this is the message", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/It seems like the team \*#{team_name}\* doesn't exist/i)
      end

      it "displays error message if member type doesn't exist" do
        team_name = 'example'
        member_type = 'xxxxx'
        message = "The member type #{member_type} doesn't exist, please call `see team #{team_name}`"
        send_message "ping team #{team_name} #{member_type} this is the message", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/#{message}/i)
        send_message "contact team #{team_name} #{member_type} this is the message", from: user, to: channel
        expect(bufferc(to: channel, from: :ubot).join).to match(/#{message}/i)
      end

      it "contacts all members" do
        send_message "contact team example all this is the message", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/:email: \*contact example team all\*/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/from <@marioruizs>/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/to[\s<>@\w+,]+<@smartbotuser1>/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/to[\s<>@\w+,]+<@smartbotuser2>/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/to[\s<>@\w+,]+<@marioruizs>/i)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/to[\s<>@\w+,]+<@xxx>/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/> this is the message/i)
      end

      it "contacts members type" do
        send_message "contact team example dev this is the message", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/:email: \*contact example team dev\*/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/from <@marioruizs>/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/to[\s<>@\w+,]+<@smartbotuser1>/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/to[\s<>@\w+,]+<@smartbotuser2>/i)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/to[\s<>@\w+,]+<@marioruizs>/i)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/to[\s<>@\w+,]+<@xxx>/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/> this is the message/i)
      end

      it "pings all members" do
        send_message "ping team example all this is the message", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/:large_green_circle: \*ping example team all\*/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/from <@marioruizs>/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/to[\s<>@\w+,]+<@smartbotuser1>/i)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/to[\s<>@\w+,]+<@smartbotuser2>/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/to[\s<>@\w+,]+<@marioruizs>/i)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/to[\s<>@\w+,]+<@xxx>/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/> this is the message/i)
      end

      it "pings members type" do
        send_message "ping team example dev this is the message", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/:large_green_circle: \*ping example team dev\*/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/from <@marioruizs>/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/to[\s<>@\w+,]+<@smartbotuser1>/i)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/to[\s<>@\w+,]+<@smartbotuser2>/i)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/to[\s<>@\w+,]+<@marioruizs>/i)
        expect(buffer(to: channel, from: :ubot).join).not_to match(/to[\s<>@\w+,]+<@xxx>/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/> this is the message/i)
      end

      it "displays there are no available members" do
        send_message "update team example delete <@#{USER1}>", from: user, to: channel
        clean_buffer()
        send_message "ping team example dev this is the message", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/It seems like there are no available dev members on example team. Please call `see team example`/i)
        send_message "update team example add dev <@#{USER1}>", from: user, to: channel
      end


    end
  end
end
