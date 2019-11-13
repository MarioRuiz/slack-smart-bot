
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

  it 'doesn\'t responds in channel with extended rules' do
    send_message @hi_bot, from: :user1, to: :cext1
    expect(buffer(to: :cext1, from: :ubot)[0]).not_to match(@hi_regexp)
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
  it "doesn't respond on extended channel" do
    send_message "!hi bot", from: :uadmin, to: :cext1
    sleep 1
    expect(buffer(to: :cext1, from: :ubot).join).to match(/I don't understand/)
  end

  describe "on external channel not extended" do
    it "doesn't respond to external demand" do
      command = "hi bot"
      send_message "<@#{UBOT}> on <##{CBOT1CM}|bot1cm> #{command}", from: :uadmin, to: :cexternal
      sleep 1
      expect(buffer(to: :cexternal, from: :ubot).join).to  match(/Take in consideration when on external calls/)
    end
  end
end
