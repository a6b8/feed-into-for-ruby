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

puts 'CHANNEL'

feed = FeedInto::Single.new( options: { channels: [ channel ] } )
feeds = FeedInto::Group.new( single: { channels: [ channel ] } )

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

results = []

results.push( !feed.analyse( item: tests[:single][:string_error] )[:success] )
puts "- single-error:\t\t\t#{results.last}"

results.push( feed.analyse( item: tests[:single][:string] )[:success] )
puts "- single:\t\t\t#{results.last}"

results.push( feed.analyse( item: tests[:single][:cmd_incomplete] )[:result][:items][ 0 ][:title].class.to_s.eql? 'String' ) 
puts "- single incomplete:\t\t#{results.last}"

results.push( feed.analyse( item: tests[:single][:cmd_complete] )[:result][:items][ 0 ][:title].class.to_s.eql? 'String' )
puts "- single cmd complete:\t\t#{results.last}"

results.push( !feed.analyse( item: tests[:single][:cmd_error] )[:success] )
puts "- single cmd error:\t\t#{results.last}"

results.push( feeds
    .analyse( items: tests[:group][:string], silent: true )
    .to_h()[:unknown][ 0 ][:result][:items][ 0 ][:title].class.eql? String )
puts "- group string:\t\t\t#{results.last}"

results.push( feeds
    .analyse( items: tests[:group][:string], silent: true )
    .merge
    .to_h()[:unknown].length == 40 )
puts "- group string error:\t\t#{results.last}"

results.push( feeds
    .analyse( items: tests[:group][:cmds_incomplete], silent: true )
    .merge
    .to_h().keys.length == 2 )
puts "- group cmds incomplete:\t#{results.last}"

results.push( feeds
    .analyse( items: tests[:group][:cmds_complete], silent: true )
    .merge
    .to_h()[:crypto].length  == 40 )
puts "- group cmds complete:\t\t#{results.last}"

results.push( feeds
    .analyse( items: tests[:group][:cmds_error], silent: true )
    .merge
    .to_h()[:crypto].length == 0 )
puts "- group cmds error:\t\t#{results.last}"


puts
puts 'MODULE'

path_mod = Dir.pwd + '/test/modules/'
feed_mod = FeedInto::Single.new( modules: path_mod )
feeds_mod = FeedInto::Group.new( modules: path_mod ) 

results.push( !feed_mod.analyse( item: tests[:single][:string_error] )[:success] )
puts "- single-error:\t\t\t#{results.last}"

results.push( feed_mod.analyse( item: tests[:single][:string] )[:success] )
puts "- single:\t\t\t#{results.last}"

results.push( feed_mod.analyse( item: tests[:single][:cmd_incomplete] )[:result][:items][ 0 ][:title].class.to_s.eql? 'String' )
puts "- single incomplete:\t\t#{results.last}"

results.push( feed_mod.analyse( item: tests[:single][:cmd_complete] )[:result][:items][ 0 ][:title].class.to_s.eql? 'String' )
puts "- single cmd complete:\t\t#{results.last}"

results.push( !feed_mod.analyse( item: tests[:single][:cmd_error] )[:success] )
puts "- single cmd error:\t\t#{results.last}"

results.push( feeds_mod
    .analyse( items: tests[:group][:string], silent: true )
    .to_h()[:unknown][ 0 ][:result][:items][ 0 ][:title].class.eql? String )
puts "- group string:\t\t\t#{results.last}"

results.push( feeds_mod
    .analyse( items: tests[:group][:string], silent: true )
    .merge
    .to_h()[:unknown].length == 40 )
puts "- group string error:\t\t#{results.last}"

results.push( feeds_mod
    .analyse( items: tests[:group][:cmds_incomplete], silent: true )
    .merge
    .to_h().keys.length == 2 )# [:unknown].length == 40
puts "- group cmds incomplete:\t#{results.last}"

results.push( feeds_mod
    .analyse( items: tests[:group][:cmds_complete], silent: true )
    .merge
    .to_h()[:crypto].length  == 40 )
puts "- group cmds complete:\t\t#{results.last}"

results.push( feeds_mod
    .analyse( items: tests[:group][:cmds_error], silent: true )
    .merge
    .to_h()[:crypto].length == 0 )
puts "- group cmds error:\t\t#{results.last}"


if results.length == 20 and results.all?
    puts 'All tests passed.'
    exit 0
else
    puts 'Not all tests passed.'
    exit 1
end