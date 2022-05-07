
RSpec.describe SlackSmartBot, "see_routine_result" do
  describe "on channel bot" do
    channel = :cbot1cm
    user = :uadmin
    
    before(:all) do
      sleep 1
      send_message "delete routine example", from: user, to: channel
    end

    after(:each) do
      sleep 1
      send_message "delete routine example", from: user, to: channel
    end
    it "displays no routine with that name" do
      send_message "see result routine example", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/There isn't a routine with that name/)
    end
    it "displays error if not admin" do
      send_message "see result routine example", from: :user1, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Only admin users can see the routines results/)
    end
    it "displays result routine when calling see result routine" do
      send_message "add routine example every 60s !ruby puts 'Sam'", from: user, to: channel
      sleep 6
      clean_buffer()
      send_message "see result routine example", from: user, to: channel
      res = buffer(to: channel, from: :ubot).join
      expect(res).to match(/Results from routine run/)
      expect(res).to match(/Sam/)      
    end
    it "displays result routine when calling see routine result" do
      send_message "add routine example every 60s !ruby puts 'Sam'", from: user, to: channel
      sleep 6
      clean_buffer()
      send_message "see routine result example", from: user, to: channel
      res = buffer(to: channel, from: :ubot).join
      expect(res).to match(/Results from routine run/)
      expect(res).to match(/Sam/)      
    end
    it "displays result routine when calling result routine" do
      send_message "add routine example every 60s !ruby puts 'Sam'", from: user, to: channel
      sleep 6
      clean_buffer()
      send_message "result routine example", from: user, to: channel
      res = buffer(to: channel, from: :ubot).join
      expect(res).to match(/Results from routine run/)
      expect(res).to match(/Sam/)      
    end
    it "displays result routine when calling see result routine for a bgroutine" do
      send_message "add bgroutine example every 60s !ruby puts 'Sam'", from: user, to: channel
      sleep 6
      clean_buffer()
      send_message "see result routine example", from: user, to: channel
      res = buffer(to: channel, from: :ubot).join
      expect(res).to match(/Results from routine run/)
      expect(res).to match(/Sam/)      
    end
  end
end
