
RSpec.describe SlackSmartBot, "see_announcements" do
  describe "see announcements" do
    describe "on external channel" do
      it "see announcements" do
        send_message "add announcement Doom1", from: :user1, to: :cexternal
        add_buffer = bufferc(to: :cexternal, from: :ubot).join
        num = add_buffer.scan(/id:\s(\d+)\)/).join
        expect(add_buffer).to match(/The announcement has been added/i)
        send_message "see announcements", from: :user1, to: :cexternal
        expect(bufferc(to: :cexternal, from: :ubot).join).to match(/#{num} :white_square: \*_\d\d\d\d\/\d\d\/\d\d_\* \d\d:\d\d smartbotuser1 \*:\*\s+Doom1/i)
      end
      it "see statements" do
        send_message "add announcement Doom1", from: :user1, to: :cexternal
        add_buffer = bufferc(to: :cexternal, from: :ubot).join
        num = add_buffer.scan(/id:\s(\d+)\)/).join
        expect(add_buffer).to match(/The announcement has been added/i)
        send_message "see statements", from: :user1, to: :cexternal
        expect(bufferc(to: :cexternal, from: :ubot).join).to match(/#{num} :white_square: \*_\d\d\d\d\/\d\d\/\d\d_\* \d\d:\d\d smartbotuser1 \*:\*\s+Doom1/i)
      end
      it "see messages" do
        send_message "add announcement Doom1", from: :user1, to: :cexternal
        add_buffer = bufferc(to: :cexternal, from: :ubot).join
        num = add_buffer.scan(/id:\s(\d+)\)/).join
        expect(add_buffer).to match(/The announcement has been added/i)
        send_message "see messages", from: :user1, to: :cexternal
        expect(bufferc(to: :cexternal, from: :ubot).join).to match(/#{num} :white_square: \*_\d\d\d\d\/\d\d\/\d\d_\* \d\d:\d\d smartbotuser1 \*:\*\s+Doom1/i)
      end
      it "see declarations" do
        send_message "add announcement Doom1", from: :user1, to: :cexternal
        add_buffer = bufferc(to: :cexternal, from: :ubot).join
        num = add_buffer.scan(/id:\s(\d+)\)/).join
        expect(add_buffer).to match(/The announcement has been added/i)
        send_message "see declarations", from: :user1, to: :cexternal
        expect(bufferc(to: :cexternal, from: :ubot).join).to match(/#{num} :white_square: \*_\d\d\d\d\/\d\d\/\d\d_\* \d\d:\d\d smartbotuser1 \*:\*\s+Doom1/i)
      end
      it "see red announcements" do
        send_message "add red announcement Doom1", from: :user1, to: :cexternal
        add_buffer = bufferc(to: :cexternal, from: :ubot).join
        num = add_buffer.scan(/id:\s(\d+)\)/).join
        expect(add_buffer).to match(/The announcement has been added/i)
        send_message "see red announcements", from: :user1, to: :cexternal
        expect(bufferc(to: :cexternal, from: :ubot).join).to match(/#{num} :large_red_square: \*_\d\d\d\d\/\d\d\/\d\d_\* \d\d:\d\d smartbotuser1 \*:\*\s+Doom1/i)
      end
      it "see green announcements" do
        send_message "add green announcement Doom1", from: :user1, to: :cexternal
        add_buffer = bufferc(to: :cexternal, from: :ubot).join
        num = add_buffer.scan(/id:\s(\d+)\)/).join
        expect(add_buffer).to match(/The announcement has been added/i)
        send_message "see green announcements", from: :user1, to: :cexternal
        expect(bufferc(to: :cexternal, from: :ubot).join).to match(/#{num} :large_green_square: \*_\d\d\d\d\/\d\d\/\d\d_\* \d\d:\d\d smartbotuser1 \*:\*\s+Doom1/i)
      end
      it "see yellow announcements" do
        send_message "add yellow announcement Doom1", from: :user1, to: :cexternal
        add_buffer = bufferc(to: :cexternal, from: :ubot).join
        num = add_buffer.scan(/id:\s(\d+)\)/).join
        expect(add_buffer).to match(/The announcement has been added/i)
        send_message "see yellow announcements", from: :user1, to: :cexternal
        expect(bufferc(to: :cexternal, from: :ubot).join).to match(/#{num} :large_yellow_square: \*_\d\d\d\d\/\d\d\/\d\d_\* \d\d:\d\d smartbotuser1 \*:\*\s+Doom1/i)
      end
      it "see white announcements" do
        send_message "add white announcement Doom1", from: :user1, to: :cexternal
        add_buffer = bufferc(to: :cexternal, from: :ubot).join
        num = add_buffer.scan(/id:\s(\d+)\)/).join
        expect(add_buffer).to match(/The announcement has been added/i)
        send_message "see white announcements", from: :user1, to: :cexternal
        expect(bufferc(to: :cexternal, from: :ubot).join).to match(/#{num} :white_square: \*_\d\d\d\d\/\d\d\/\d\d_\* \d\d:\d\d smartbotuser1 \*:\*\s+Doom1/i)
      end
      it "see EMOJI announcements" do
        send_message "add :green_heart: announcement Doom1", from: :user1, to: :cexternal
        add_buffer = bufferc(to: :cexternal, from: :ubot).join
        num = add_buffer.scan(/id:\s(\d+)\)/).join
        expect(add_buffer).to match(/The announcement has been added/i)
        send_message "see :green_heart: announcements", from: :user1, to: :cexternal
        expect(bufferc(to: :cexternal, from: :ubot).join).to match(/#{num} :green_heart: \*_\d\d\d\d\/\d\d\/\d\d_\* \d\d:\d\d smartbotuser1 \*:\*\s+Doom1/i)
      end
      it "see announcements other channel not on DM" do
        send_message "see announcements #extended1", from: :user1, to: :cexternal
        expect(bufferc(to: :cexternal, from: :ubot).join).to match(/Go to <##{CEXT1}> and call the command from there/i)
      end
      
      it "see announcements other channel on DM but not master admin" do
        send_message "add announcement Doom1", from: :user1, to: :cext1
        add_buffer = bufferc(to: :cext1, from: :ubot).join
        num = add_buffer.scan(/id:\s(\d+)\)/).join
        expect(add_buffer).to match(/The announcement has been added/i)
        send_message "see announcements #extended1", from: :user1, to: DIRECT.user1.ubot
        expect(bufferc(to: DIRECT.user1.ubot, from: :ubot).join).to match(/Go to <##{CEXT1}> and call the command from there/i)
      end
      it "see announcements other channel on DM and master admin" do
        send_message "add announcement Doom1", from: :user1, to: :cext1
        add_buffer = bufferc(to: :cext1, from: :ubot).join
        num = add_buffer.scan(/id:\s(\d+)\)/).join
        expect(add_buffer).to match(/The announcement has been added/i)
        send_message "see announcements #extended1", from: :uadmin, to: DIRECT.uadmin.ubot
        expect(bufferc(to: DIRECT.uadmin.ubot, from: :ubot).join).to match(/#{num} :white_square: \*_\d\d\d\d\/\d\d\/\d\d_\* \d\d:\d\d smartbotuser1 \*:\*\s+Doom1/i)
      end
      it "see all announcements not on DM" do
        send_message "see all announcements", from: :uadmin, to: :cexternal
        expect(bufferc(to: :cexternal, from: :ubot).join).to match(/Only master admins on a DM with the SmarBot can call this command/i)
      end
      it "see all announcements on DM and not master admin" do
        send_message "see all announcements", from: :user1, to: DIRECT.user1.ubot
        expect(bufferc(to: DIRECT.user1.ubot, from: :ubot).join).to match(/Only master admins on a DM with the SmarBot can call this command/i)
      end
      it "see all announcements on DM and master admin" do
        send_message "add announcement Doom1", from: :user1, to: :cext1
        add_buffer = bufferc(to: :cext1, from: :ubot).join
        num = add_buffer.scan(/id:\s(\d+)\)/).join
        expect(add_buffer).to match(/The announcement has been added/i)
        send_message "see all announcements", from: :uadmin, to: DIRECT.uadmin.ubot
        expect(bufferc(to: DIRECT.uadmin.ubot, from: :ubot).join).to match(/#{num} :white_square: \*_\d\d\d\d\/\d\d\/\d\d_\* \d\d:\d\d smartbotuser1 \*:\*\s+Doom1/i)
      end
    end
  end
end
