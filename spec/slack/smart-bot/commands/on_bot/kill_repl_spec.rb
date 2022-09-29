RSpec.describe SlackSmartBot, "kill_repl" do
  describe "on channel bot" do
    channel = :cbot1cm
    user = :user1

    before(:all) do
      send_message "!repl runreplkill ", from: user, to: channel
      sleep 5
      send_message "sleep 20", from: user, to: channel
      sleep 22
      send_message "puts 'done'", from: user, to: channel
      sleep 2
      send_message "bye", from: user, to: channel
      clean_buffer()
    end
    before(:each) do
      send_message "!run repl runreplkill", from: user, to: channel
      @repl_id = buffer(to: channel, from: :ubot).join.scan(/\(id:\s+(\w+)\)/).join
      expect(@repl_id).not_to eq ''
    end
    after(:all) do
      send_message "bye bot", from: user, to: channel
    end

    it "displays the repl id doesn't exist" do
      send_message "!kill repl xxxxxxxxx", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/The run repl with id xxxxxxxxx doesn't exist/i)
    end

    it 'cannot kill a repl run by other user' do
      send_message "!kill repl #{@repl_id}", from: :user2, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Only smartbotuser1 or a master admin can kill this repl/i)      
    end

    it 'the runner can kill the repl' do
      send_message "!kill repl #{@repl_id}", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/The repl runreplkill \(id: #{@repl_id}\) has been killed/i)
    end

    it 'master admin can kill the repl' do
      send_message "!kill repl #{@repl_id}", from: :uadmin, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/The repl runreplkill \(id: #{@repl_id}\) has been killed/i)
    end

  end
end
