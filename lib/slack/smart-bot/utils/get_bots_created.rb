class SlackSmartBot
  def get_bots_created
    require 'yaml'
    bots_file = config.file_path.gsub(".rb", "_bots.yaml")

    if File.exist?(config.file_path.gsub(".rb", "_bots.rb")) #backwards compatible
      file_conf = IO.readlines(config.file_path.gsub(".rb", "_bots.rb")).join
      if file_conf.to_s() == ""
        @bots_created = {}
      else
        @bots_created = eval(file_conf)
      end
      File.open(bots_file, 'w') {|file| file.write(@bots_created.to_yaml) }
      File.delete(config.file_path.gsub(".rb", "_bots.rb"))
    end

    if File.exist?(bots_file)
      
      if !defined?(@datetime_bots_created) or @datetime_bots_created != File.mtime(bots_file)
        bots_created = @bots_created
        10.times do
          bots_created = YAML.load(File.read(bots_file))
          if bots_created.is_a?(Hash)
            break
          else
            sleep (0.1*(rand(2)+1))
          end
        end
        @bots_created = bots_created unless bots_created.is_a?(FalseClass)
        @datetime_bots_created = File.mtime(bots_file)
        @extended_from = {}
        @bots_created.each do |k, v|
          v[:extended] = [] unless v.key?(:extended)
          v[:extended].each do |ch|
            @extended_from[ch] = [] unless @extended_from.key?(ch)
            @extended_from[ch] << k
          end
          v[:rules_file] ||= ''
          v[:rules_file].gsub!(/^\./, '')
        end
      end
    end
  end
end
