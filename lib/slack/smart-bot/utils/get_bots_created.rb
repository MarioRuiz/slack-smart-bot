class SlackSmartBot
  def get_bots_created
    if File.exist?(config.file_path.gsub(".rb", "_bots.rb"))
      if !defined?(@datetime_bots_created) or @datetime_bots_created != File.mtime(config.file_path.gsub(".rb", "_bots.rb"))
        file_conf = IO.readlines(config.file_path.gsub(".rb", "_bots.rb")).join
        if file_conf.to_s() == ""
          @bots_created = {}
        else
          @bots_created = eval(file_conf)
        end
        @datetime_bots_created = File.mtime(config.file_path.gsub(".rb", "_bots.rb"))
        @extended_from = {}
        @bots_created.each do |k, v|
          v[:extended] = [] unless v.key?(:extended)
          v[:extended].each do |ch|
            @extended_from[ch] = [] unless @extended_from.key?(ch)
            @extended_from[ch] << k
          end
          v[:rules_file].gsub!(/^\./, '')
        end
      end
    end
  end
end
