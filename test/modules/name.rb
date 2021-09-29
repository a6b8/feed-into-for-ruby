module Name
  def crl_name( sym, cmd, channel, response, data, obj )
    messages = []

    case sym
      when :settings
        data = crl_name_settings()
      when :transform
        data = crl_name_transform( data, obj, cmd, channel )
    else
      messages.push( "name: #{sym} not found." )
    end
    
    return data, messages
  end
  

  private


  def crl_name_settings()
    {
      name: :blockchain,
      sym: :web,
      options: {},
      regexs: [ [ /https:\/\/raw.githubusercontent.com/ ] ],
      download: :general,
      mining: :rss_one,
      pre: [],
      transform: nil,
      post: [ :pre_titles ]
    }
  end

  
  def crl_name_transform( data, obj, cmd, channel )
    data[:items] = data[:items].map do | item |
        item = {
          title: '',
          time: { stamp: 1632702548 },
          url: 'https://....'
        }
    end
    return data
  end
end