class SlackSmartBot

  def remove_hash_keys(hash, key)
    newh = Hash.new
    hash.each do |k, v|
      unless k == key
        if v.is_a?(String)
          newh[k] = v
        else
          newh[k] = remove_hash_keys(v, key)
        end
      end
    end
    return newh
  end

end
