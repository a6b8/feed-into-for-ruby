require './lib/feed_into'
require 'active_support/core_ext/hash/indifferent_access'


channel = {
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

puts 'CHANNEL:'

feed = FeedInto::Single.new( 
    options: { channels: [ channel ] } 
)

tests = {
    single: {
        string_error: 'test',
        string: 'https://raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/examples/nft.xml',
        cmd_incomplete: {
            name: 'test',
            url: 'https://raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/examples/nft.xml'
        },
        cmd_complete: {
            name: 'test',
            url: 'https://raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/examples/nft.xml',
            category: :crypto      
        },
        cmd_error: {
            name: 'test',
            url: '//raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/examples/nft.xml',
            category: :crypto  
        }
    },
    group: {
        string: [
            'https://raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/examples/nft.xml',
            'https://raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/examples/crypto.xml'
        ],
        string_error: [
            'https://raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/examples/nft.xml',
            '//raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/examples/crypto.xml'
        ],
        cmds_incomplete: [
            {
                name: 'test',
                url: 'https://raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/examples/nft.xml'
            },
            {
                url: 'https://raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/examples/crypto.xml',
                category: :crypto
            }
        ],
        cmds_complete: [
            {
                name: 'nft',
                url: 'https://raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/examples/nft.xml',
                category: :crypto      
            },
            {
                name: 'crypto',
                url: 'https://raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/examples/crypto.xml',
                category: :crypto      
            }
        ],
        cmds_error: [
            {
                name: 'nft',
                url: 'ht://raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/examples/nft.xml',
                category: :crypto      
            },
            {
                name: 'crypto',
                url: '://raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/examples/crypto.xml',
                category: :crypto      
            }
        ]
    }
}


res = feed.analyse( item: tests[:single][:string_error] )
puts "- single-error:\t\t\t#{!res[:success]}"

puts feed