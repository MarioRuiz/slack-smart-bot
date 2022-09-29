class SlackSmartBot

  def update_admins_channels()

    require 'yaml'
    admins_file = "#{config.path}/rules/#{@channel_id}/admins_channels.yaml"

    if File.exist?(admins_file.gsub(".yaml", ".rb")) #backwards compatible
      file_conf = IO.readlines(admins_file.gsub(".yaml", ".rb")).join
      if file_conf.to_s() == ""
        @admins_channels = {}
      else
        @admins_channels = eval(file_conf)
      end
      File.open(admins_file, 'w') {|file| file.write(@admins_channels.to_yaml) }
      File.delete(admins_file.gsub(".yaml", ".rb"))
    end

    File.open(admins_file, 'w') {|file|
      file.flock(File::LOCK_EX)
      file.write(@admins_channels.to_yaml) 
      file.flock(File::LOCK_UN)
    }
  end
end
