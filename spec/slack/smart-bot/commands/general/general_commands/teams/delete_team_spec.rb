
RSpec.describe SlackSmartBot, "delete_team" do
  describe "delete team" do
    describe "on DM" do
      channel = DIRECT.uadmin.ubot
      user = :uadmin

      before(:each) do
        send_message "add team exampledel members <##{CEXTERNAL}|external_channel> : info", from: user , to: channel
      end

      it 'is not possible to be called from a DM' do
        send_message "delete team exampledel", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/This command cannot be called from a DM/i)
      end
    end

    describe "on external channel" do
      channel = :cexternal
      user = :uadmin
      before(:each) do
        send_message "add team exampledel members <##{CEXTERNAL}|external_channel> : info", from: user , to: channel
        clean_buffer()
      end
      after(:all) do
        send_message "yes", from: user , to: channel
      end
      it "displays error message if team doesn't exist" do
        team_name = 'xxxxxxxxx'
        send_message "delete team #{team_name}", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/It seems like the team \*#{team_name}\* doesn't exist/i)
      end

      it "only a member of the team, the creator or a Master admin to be able to delete the team" do
        send_message "delete team exampledel", from: :user2, to: :cbot2cu
        expect(buffer(to: :cbot2cu, from: :ubot).join).to match(/You have to be a member of the team, the creator or a Master admin to be able to delete this team/i)
      end

      it "can be cancelled the team deletion" do
        send_message "delete team exampledel", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/do you really want to delete the exampledel team\? \(yes\/no\)/i)
        send_message "no", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Ok, the team was not deleted/i)        
      end

      it "displays confirmation message and error if not yes or no answered" do
        send_message "delete team exampledel", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/do you really want to delete the exampledel team\? \(yes\/no\)/i)
        send_message "blahblah", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/I don't understand/i)
        expect(buffer(to: channel, from: :ubot).join).to match(/do you really want to delete the exampledel team\? \(yes\/no\)/i)
        send_message "yes", from: user, to: channel
      end

      it "deletes the team specified" do
        send_message "delete team exampledel", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/do you really want to delete the exampledel team\? \(yes\/no\)/i)
        send_message "yes", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/The team exampledel has been deleted/i)
        send_message "exampledel team", from: user, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/There are no teams added yet. Use `add team` command to add a team/i)
      end
    end
  end
end
