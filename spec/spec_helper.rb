require "coveralls"
Coveralls.wear!
require_relative "spec_helper_utils"

# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# The generated `.rspec` file contains `--require spec_helper` which will cause
# this file to always be loaded, without a need to explicitly require it in any
# files.
#
# Given that it is always loaded, you are encouraged to keep this file as
# light-weight as possible. Requiring heavyweight dependencies from this file
# will add to the boot time of your test suite on EVERY test run, even for an
# individual file that may not need all of that loaded. Instead, consider making
# a separate helper file that requires the additional dependencies and performs
# the additional setup, and require it from the spec files that actually need
# it.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.before(:suite) do
    File.new("./spec/bot/buffer_copy.log", "w")
    unless ENV["RUNNING"] == "true"
      File.new("./spec/bot/buffer_complete.log", "w")
      require "fileutils"
      FileUtils.rm_rf(Dir["./spec/bot/logs/*"])
      FileUtils.rm_rf(Dir["./spec/bot/routines/*"])
      FileUtils.rm_rf(Dir["./spec/bot/routines/**/*"])
      FileUtils.rm_rf(Dir["./spec/bot/shortcuts/*"])
      FileUtils.rm_rf(Dir["./spec/bot/stats/*"])
      FileUtils.rm_rf(Dir["./spec/bot/shares/*"])
      FileUtils.rm_rf(Dir["./spec/bot/status/*"])
      FileUtils.rm_rf(Dir["./spec/bot/announcements/*"])
      FileUtils.rm_rf(Dir["./spec/bot/repl/**/*"])
      File.delete("./spec/bot/rules/rules_imported.rb") if File.exists?("./spec/bot/rules/rules_imported.rb")
      File.delete("./spec/bot/smart-bot-example_teams.rb") if File.exists?("./spec/bot/smart-bot-example_teams.rb")

      @settings = {
        nick: "example", # the smart bot name
        token: ENV["SSB_TOKEN"], # the API Slack token
        testing: true,
        simulate: ENV['SIMULATE']=='true',
        masters: ['marioruizs'],
        master_channel: 'master_channel',
        path: './spec/bot/',
        file: 'smart-bot-example.rb',
        start_bots: false,
        stats: true,
        nick_id: 'UMSRCRTAR',
      }
      if @settings.simulate
        require_relative 'bot/client.rb'
        @settings.client = csettings.client
      end
      
      Thread.new do
        sb = SlackSmartBot.new(@settings)
        while sb.config.simulate do
          sb.listen_simulate()
          sleep 0.2
        end
      end
      sleep 2

      Thread.new do
        settings = @settings.deep_copy
        settings.channel = 'bot1cm'
        settings.rules_file = "/rules/CN0595D50/slack-smart-bot_rules_CN0595D50_marioruizs.rb"
        settings.admins =["marioruizs"]
        sb = SlackSmartBot.new(settings)
        while sb.config.simulate do
          sb.listen_simulate()
          sleep 0.2
        end
      end
      sleep 2

      Thread.new do
        settings = @settings.deep_copy
        settings.channel = 'bot2cu'
        settings.rules_file = "/rules/CN1EFTKQB/slack-smart-bot_rules_CN1EFTKQB_smartbotuser1.rb"
        settings.admins = ['smartbotuser1','marioruizs']

        sb = SlackSmartBot.new(settings)
        while sb.config.simulate do
          sb.listen_simulate()
          sleep 0.2
        end
      end
      sleep 1

      unless SIMULATE
        started = false
        tries = 0
        while !started and tries < 5
          sleep 10
          if buffer(to: :cmaster, from: :ubot)[0].include?("Smart Bot started")
            started = true
          else
            tries += 1
          end
        end
        expect(started).to eq true
      else
        sleep 10
        #expect(buffer(to: :cstatus, from: :ubot).join).to match(/:large_green_circle: The *SmartBot* on #bot1cm is up and running again./)
      end
    end
    clean_buffer()
  end
  config.after(:suite) do
    unless ENV["RUNNING"] == "true"
      send_message "close bot", from: :uadmin, to: :cmaster
      expect(bufferc(to: :cmaster, from: :ubot).join).to match(/are you sure\?/)
      send_message "yes", from: :uadmin, to: :cmaster
      expect(buffer(to: :cmaster, from: :ubot).join).to match(/Game over/)
      sleep 10
      expect(buffer(to: :cstatus, from: :ubot).join).to match(/:red_circle: The admin closed SmartBot on \*<#CN0595D50|bot1cm>\*/)
      expect(buffer(to: :cstatus, from: :ubot).join).to match(/:red_circle: The admin closed SmartBot on \*<#CN1EFTKQB|bot2cu>\*/)
      clean_buffer()
      send_message "hi bot", from: :uadmin, to: :cmaster
      send_message "hi bot", from: :uadmin, to: :cbot1cm
      send_message "hi bot", from: :uadmin, to: :cbot2cu
      expect(buffer(to: :cmaster, from: :ubot).join).to eq ""
      expect(buffer(to: :cbot1cm, from: :ubot).join).to eq ""
      expect(buffer(to: :cbot2cu, from: :ubot).join).to eq ""
    end
  end

  config.before(:each) do
    clean_buffer()
  end

  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end
  
  config.example_status_persistence_file_path = "spec/examples.txt"

  # This option will default to `:apply_to_host_groups` in RSpec 4 (and will
  # have no way to turn it off -- the option exists only for backwards
  # compatibility in RSpec 3). It causes shared context metadata to be
  # inherited by the metadata hash of host groups and examples, rather than
  # triggering implicit auto-inclusion in groups with matching metadata.
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_excluding :avoid_travis => ENV['AVOID_TRAVIS'].to_s=='true'
  # The settings below are suggested to provide a good initial experience
  # with RSpec, but feel free to customize to your heart's content.
=begin
  # This allows you to limit a spec run to individual examples or groups
  # you care about by tagging them with `:focus` metadata. When nothing
  # is tagged with `:focus`, all examples get run. RSpec also provides
  # aliases for `it`, `describe`, and `context` that include `:focus`
  # metadata: `fit`, `fdescribe` and `fcontext`, respectively.
  config.filter_run_when_matching :focus

  # Allows RSpec to persist some state between runs in order to support
  # the `--only-failures` and `--next-failure` CLI options. We recommend
  # you configure your source control system to ignore this file.
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Limits the available syntax to the non-monkey patched syntax that is
  # recommended. For more details, see:
  #   - http://rspec.info/blog/2012/06/rspecs-new-expectation-syntax/
  #   - http://www.teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
  #   - http://rspec.info/blog/2014/05/notable-changes-in-rspec-3/#zero-monkey-patching-mode
  config.disable_monkey_patching!

  # This setting enables warnings. It's recommended, but in some cases may
  # be too noisy due to issues in dependencies.
  config.warnings = true

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = "doc"
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed
=end
end
