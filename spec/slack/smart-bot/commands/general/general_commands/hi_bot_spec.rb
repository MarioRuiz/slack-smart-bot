
RSpec.describe SlackSmartBot, "hi_bot" do
  before(:each) do
    salutations = ["example", "<@#{UBOT}>", "bot", "smart"]
    hi = "Hello|Hallo|Hi|Hola|What's up|Hey|Hæ"
    @hi_bot = "#{hi.split("|").sample} #{salutations.sample}"
    @hi_regexp = /(#{hi})\suser1/i
  end

  it "responds in master channel" do
    send_message @hi_bot, from: :user1, to: :cmaster
    expect(buffer(to: :cmaster, from: :ubot)[0]).to match(@hi_regexp)
  end
  it "responds in direct message" do
    send_message @hi_bot, from: :user1, to: :ubot
    expect(buffer(to: DIRECT.user1.ubot, from: :ubot)[0]).to match(@hi_regexp)
  end
  it "responds in bot channel" do
    send_message @hi_bot, from: :user1, to: :cbot1cm
    expect(buffer(to: :cbot1cm, from: :ubot)[0]).to match(@hi_regexp)
  end

  it 'responds in channel with extended rules' do
    send_message @hi_bot, from: :user1, to: :cext1
    expect(buffer(to: :cext1, from: :ubot)[0]).to match(@hi_regexp)
  end

  it 'doesn\'t responds in private channel with extended rules' do
    send_message @hi_regexp, from: :user1, to: :cprivext
    expect(buffer(to: :cprivext, from: :ubot)[0]).not_to match(@hi_regexp)
  end
  it "doesn't respond if listening and '- hi bot'" do
    send_message "hi bot", from: :user1, to: :cbot1cm
    sleep 1
    clean_buffer()
    send_message "- hi bot", from: :user1, to: :cbot1cm
    expect(buffer(to: :cbot1cm, from: :ubot).join).to eq ""
  end
  it "responds to `hi bot`" do
    send_message "`hi bot`", from: :user1, to: :cbot1cm
    sleep 1
    expect(buffer(to: :cbot1cm, from: :ubot)[0]).to match(@hi_regexp)
  end
  it "responds to *hi bot*" do
    send_message "*hi bot*", from: :user1, to: :cbot1cm
    sleep 1
    expect(buffer(to: :cbot1cm, from: :ubot)[0]).to match(@hi_regexp)
  end
  it "responds to _hi bot_" do
    send_message "_hi bot_", from: :user1, to: :cbot1cm
    sleep 1
    expect(buffer(to: :cbot1cm, from: :ubot)[0]).to match(@hi_regexp)
  end
  it "responds on extended channel" do
    send_message "hi bot", from: :user1, to: :cext1
    sleep 1
    expect(buffer(to: :cext1, from: :ubot)[0]).to match(@hi_regexp)
  end

  describe "on external channel not extended" do
    it "responds" do
      command = "hi bot"
      send_message "#{command}", from: :uadmin, to: :cexternal
      sleep 1
      expect(buffer(to: :cexternal, from: :ubot).join).to  match(/You are on a channel where the SmartBot is just a member/i)
    end
  end

  #todo: add tests for Slack Threads
  #todo: add tests for react method
  #todo: add tests for unreact method
  #todo: add tests for listening on slack threads

end
