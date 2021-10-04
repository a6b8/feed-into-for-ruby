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