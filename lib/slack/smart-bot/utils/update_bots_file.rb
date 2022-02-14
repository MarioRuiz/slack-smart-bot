class SlackSmartBot
  def update_bots_file
    bots_file = config.file_path.gsub(".rb", "_bots.yaml")

    if File.exist?(config.file_path.gsub(".rb", "_bots.rb")) #backwards compatible
      file_conf = IO.readlines(config.file_path.gsub(".rb", "_bots.rb")).join
      if file_conf.to_s() == ""
        @bots_created = {}
      else
        @bots_created = eval(file_conf)
      end      
      File.open(bots_file, 'w') {|file| 
        file.flock(File::LOCK_EX)
        file.write(@bots_created.to_yaml) 
        file.flock(File::LOCK_UN)
      }
      File.delete(config.file_path.gsub(".rb", "_bots.rb"))
    else
      #not possible to use @bots_created.deep_copy since one of the fields contains a thread
      bots_created = {}
      @bots_created.each do |k,v|
        bots_created[k] = v.dup
        bots_created[k][:thread] = ''
      end
      File.open(bots_file, 'w') {|file|
        file.flock(File::LOCK_EX)
        file.write(bots_created.to_yaml) 
        file.flock(File::LOCK_UN)
      }
    end
  end
end
