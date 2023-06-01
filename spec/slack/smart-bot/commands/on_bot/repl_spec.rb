
RSpec.describe SlackSmartBot, "repl" do
  describe "on channel bot" do
    channel = :cbot1cm
    user = :user1

    after(:each) do
      send_message "quit", from: user, to: channel
      send_message "quit", from: :user2, to: channel
    end

    after(:all) do
      send_message "bye bot", from: user, to: channel
    end

    it 'starts a repl with repl command' do
      send_message "!repl", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Session name: \*\w+_\d+\*/)
    end
    it 'starts a repl with irb command' do
      send_message "!irb", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Session name: \*\w+_\d+\*/)
    end
    it 'starts a repl with live command' do
      send_message "!live", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Session name: \*\w+_\d+\*/)
    end

    it "generates a repl session name if not supplied" do
      send_message "!repl", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Session name: \*\w+_\d+\*/)
    end

    it "uses the repl session name if supplied" do
      send_message "!repl example", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Session name: \*example/)
    end

    it "generates a new session name when already exists" do
      send_message "!repl example", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/Session name: \*example\d+\*/)
    end

    it 'ends the session when sending quit' do
      send_message "!repl", from: user, to: channel
      send_message "quit", from: user, to: channel
      sleep 0.5 if SIMULATE

      expect(buffer(to: channel, from: :ubot).join).to match(/REPL session finished: \w+_\d+/)
    end
    it 'ends the session when sending exit' do
      send_message "!repl", from: user, to: channel
      send_message "exit", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/REPL session finished: \w+_\d+/)
    end
    it 'ends the session when sending exit' do
      send_message "!repl", from: user, to: channel
      send_message "bye", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/REPL session finished: \w+_\d+/)
    end
    #todo: This test is not running on travis but locally. Investigate the reason
    it 'executes the .smart-bot-repl file', :avoid_travis do
      send_message "!repl prerun ", from: user, to: channel
      send_message "puts LOLO", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/beautiful/i)
    end
    it 'creates repls with option clean' do
      send_message "!clean repl", from: user, to: channel
      send_message "puts LOLO", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).not_to match(/beautiful/i)
    end

    #todo: This test is not running on travis but locally. Investigate the reason
    it 'responds continuosly', :avoid_travis do
      send_message "!repl", from: user, to: channel
      send_message "a = 2222", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/2222/)
      send_message "a += 3", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/2225/)
    end

    it "doesn't allow to add collaborator if on another repl" do
      send_message "!repl", from: user, to: channel
      send_message "!repl", from: :user2, to: channel
      send_message "add collaborator <@#{USER2}>", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match("Sorry, <@#{USER2}> is already in a repl. Please ask her/him to quit it first")
    end

    it "adds collaborator" do
      send_message "!repl", from: user, to: channel
      send_message "add collaborator <@#{USER2}>", from: user, to: channel
      sleep 1
      expect(buffer(to: channel, from: :ubot).join).to match("Collaborator added. Now <@#{USER2}> can interact with this repl.")
      send_message "a = 3 + 97", from: user, to: channel
      sleep 1
      clean_buffer()
      send_message "puts a", from: :user2, to: channel
      sleep 1
      expect(buffer(to: channel, from: :ubot).join).to match(/100/)
    end

    it "removes collaborator" do
      send_message "!repl", from: user, to: channel
      send_message "add collaborator <@#{USER2}>", from: user, to: channel
      sleep 1
      send_message "quit", from: :user2, to: channel
      sleep 1
      expect(buffer(to: channel, from: :ubot).join).to match("Collaborator <@#{USER2}> removed.")
      send_message "a = 3 + 97", from: user, to: channel
      sleep 1
      clean_buffer()
      send_message "puts a", from: :user2, to: channel
      expect(buffer(to: channel, from: :ubot).join).not_to match(/100/)
    end

    it "removes session and collaborator when creator quitting" do
      send_message "!repl", from: user, to: channel
      send_message "add collaborator <@#{USER2}>", from: user, to: channel
      send_message "quit", from: user, to: channel
      clean_buffer()
      send_message "puts 'love321'", from: :user2, to: channel
      expect(buffer(to: channel, from: :ubot).join).not_to include('love321')
      send_message "puts 'love678'", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).not_to include('love678')
    end
    it 'displays methods of an object' do
      send_message "!repl", from: user, to: channel
      send_message "ls Wrong", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/uninitialized constant Wrong/)
      send_message "ls Operations", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to match(/\*`get`\* \(api_version: API_VERSION\)/)
      message = "*`list`* (giveme, opt='', api_version: API_VERSION, uno: 1, dos: 2,"
      expect(buffer(to: channel, from: :ubot).join).to include(message)
      expect(buffer(to: channel, from: :ubot).join).to include("tres: 3, cuatro: 4, cinco: 5,")
      expect(buffer(to: channel, from: :ubot).join).to include("seis: 6, siete: 7, ocho: 8, lobo:, mando:)")
      expect(buffer(to: channel, from: :ubot).join).to include("*`list_async`* (api_version: API_VERSION)")
      expect(buffer(to: channel, from: :ubot).join).to include("*`no_parameters`* ...")
      expect(buffer(to: channel, from: :ubot).join).to include("*`no_parenthesis`* api_version: API_VERSION, love: true, number: 0 ...")
      expect(buffer(to: channel, from: :ubot).join).to include("*`print`* (value, api_version: API_VERSION, love: true, number: 0)")
    end
    it 'displays the documentation of a method' do
      send_message "!repl", from: user, to: channel
      send_message "doc Wrong", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to include("No documentation found for Wrong. The object doesn't exist or it is not accessible")
      send_message "doc Wrong.wrong", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to include("No documentation found for Wrong.wrong. The object doesn't exist or it is not accessible")
      send_message "doc Operations.wrong", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to include("undefined method `wrong' for module `Operations'")
      send_message "doc Operations::Wrong", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to include("No documentation found for Operations::Wrong. The object doesn't exist or it is not accessible")
      send_message "doc Operations::Wrong.wrong", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to include("No documentation found for Operations::Wrong.wrong. The object doesn't exist or it is not accessible")
      send_message "doc Operations", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to include("No documentation found for Operations. The object doesn't exist or it is not accessible")
      send_message "doc Operations.list", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to include("/repl_required_example.rb:27")
      expect(buffer(to: channel, from: :ubot).join).to include("*operationId*: Operations_List, method: get")
      expect(buffer(to: channel, from: :ubot).join).to include("*`api-version`*: (string) (required) The API version to use for this operation.")
      expect(bufferc(to: channel, from: :ubot).join).to include("*`list`* (giveme, opt='', api_version: API_VERSION, uno: 1, dos: 2,")
      send_message "doc Operations::Two", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to include("No documentation found for Operations::Two. The object doesn't exist or it is not accessible")
      send_message "doc Operations::Two.love", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to include("/repl_required_example.rb:96")
      send_message "doc Operations::Two.love2", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to include("/repl_required_example.rb:110")
      send_message "doc SMExample", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to include("No documentation found for SMExample. The object doesn't exist or it is not accessible")
      send_message "doc SMExample.initialize", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to include("/repl_required_example.rb:126")
      expect(buffer(to: channel, from: :ubot).join).to include("some text to explain the initialize method")
      expect(bufferc(to: channel, from: :ubot).join).to include("*`initialize`* ...")
      send_message "doc SMExample.initialize.print", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to include("/repl_required_example.rb:131")
      send_message "doc SMExample.print", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to include("/repl_required_example.rb:131")
      send_message "doc SMExample.love", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to include("/repl_required_example.rb:135")
      send_message "doc love_print", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to include("/repl_required_example.rb:141")
      send_message "doc wrong_print", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to include("No documentation found for wrong_print. The object doesn't exist or it is not accessible")
      send_message "doc print", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to include("No documentation found for print. The object doesn't exist or it is not accessible")
    end

    it 'displays the source code of a method' do
      send_message "!repl", from: user, to: channel
      send_message "src Wrong", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to include("No source code found for Wrong. The object doesn't exist or it is not accessible")
      send_message "source Wrong", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to include("No source code found for Wrong. The object doesn't exist or it is not accessible")
      send_message "code Wrong", from: user, to: channel
      expect(bufferc(to: channel, from: :ubot).join).to include("No source code found for Wrong. The object doesn't exist or it is not accessible")
      send_message "code Operations.list", from: user, to: channel
      expect(buffer(to: channel, from: :ubot).join).to include("/repl_required_example.rb:27")
      expect(buffer(to: channel, from: :ubot).join).to include("def self.list(giveme, opt='', api_version: API_VERSION, uno: 1, dos: 2,")
      expect(bufferc(to: channel, from: :ubot).join).to include("responses: {")
    end

  end
end
