
RSpec.describe SlackSmartBot, "poster" do
  describe "poster" do
    describe "on external channel" do
      uno = ':transparent_square::transparent_square::transparent_square::transparent_square:
      :transparent_square::transparent_square::black_square::transparent_square:
      :transparent_square::black_square::black_square::transparent_square:
      :transparent_square::transparent_square::black_square::transparent_square:
      :transparent_square::transparent_square::black_square::transparent_square:
      :transparent_square::transparent_square::black_square::transparent_square:
      :transparent_square::transparent_square::transparent_square::transparent_square:'.gsub(' ','')
      channel = :cexternal

      it "doesn't poster if message > 15 chars" do
        send_message "poster xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join).to match(/Too long. Max 15 chars/i)
      end
      it "poster MESSAGE" do
        send_message "poster 1", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join.gsub(' ','')).to eq(uno)
      end
      it "poster :EMOTICON_TEXT: MESSAGE" do
        send_message "poster :lol: 1", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join.gsub(' ','')).to eq(uno.gsub(':black_square:',':lol:'))
      end
      it "poster :EMOTICON_TEXT: :EMOTICON_BACKGROUND: MESSAGE" do
        send_message "poster :lol: :look: 1", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join.gsub(' ','')).to eq(uno.gsub(':black_square:',':lol:').gsub(':transparent_square:',':look:'))
      end
      it "poster MINUTESm MESSAGE" do
        send_message "poster 2m 1", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join.gsub(' ','')).to eq(uno)
      end
      it "pposter MESSAGE" do
        send_message "pposter 1", from: :uadmin, to: channel
        expect(buffer(to: channel, from: :ubot).join.gsub(' ','')).to eq(uno)
      end

    end

  end
end
