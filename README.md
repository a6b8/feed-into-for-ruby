<a href="#table-of-contents">
<img src="https://raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/headlines/Headline.svg" height="45px" name="headline" alt="# Feed Into for Ruby">
</a>

Merge multiple different data streams to a custom structure based on categories. Also easy to expand by a custom module system. 
<br>
<br>
<br>
<a href="#table-of-contents">
<img src="https://raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/headlines/examples.svg" height="38px" name="examples" alt="Examples">
</a>

**Merge multiple Streams**
```ruby
require 'feed_into'

channels_settings = {
    name: :blockchain,
    sym: :web,
    options: {},
    regexs: [ [ /https:\/\/your*website.com/ ] ],
    download: :general,
    mining: :rss_one,
    pre: [],
    transform: nil,
    post: [ :pre_titles ]
}

feeds = FeedInto::Group.new( 
    single: { channels: [ channels_settings ] } 
)

urls = [
    'https://your*website.com/1.xml',
    'https://your*website.com/2.xml'
]

feeds
    .analyse( items: urls )
    .merge
    .to_rss( key: :unknown )
```
<br>

**Create .rss Categories from multiple Streams**
```ruby
require 'feed_into'

channels_settings = {
    name: :blockchain,
    sym: :web,
    options: {},
    regexs: [ [ /https:\/\/your*website.com/ ] ],
    download: :general,
    mining: :rss_one,
    pre: [],
    transform: nil,
    post: [ :pre_titles ]
}

feeds = FeedInto::Group.new( 
    single: { channels: [ channels_settings ] } 
)

item = [
    {
        name: 'Channel 1',
        url: 'https://your*website.com/1.xml',
        category: :nft
    },
    {
        name: 'Channel 2',
        url: 'https://your*website.com/2.xml',
        category: :crypto
    }
]

feeds
    .analyse( items: urls )
    .merge
    .to_rss_all
```
<br>
<br>
<a href="#headline">
<img src="https://raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/headlines/table-of-contents.svg" height="38px" name="table-of-contents" alt="Table of Contents">
</a>
<br>

1. [Examples](#examples)<br>
2. [Quickstart](#quickstart)<br>
3. [Setup](#setup)<br>
4. [Input Types](#input-types)<br>
   - [Single](#FeedIntosingle)<br>
     [String URL](#a-1-string-url)<br>
     [Hash Structure](#a2-hash-structure-cmd)<br>
   - Group<br>
     [Array of Strings](#b1-array-of-string)<br>
     [Array of Hashs](#b2-array-of-hash-cmds)<br>
5. [Methods](#methods)<br>
   - [Single](#FeedIntosingle-1)<br>
     [.analyse()](#analyse-item-)<br>
   - [Group](#FeedIntogroup)<br>
     [.analyse()](#analyse-items--silent-false-)<br>
     [.merge](#merge)<br>
     [.to_h()](#to_h-type-)<br>
     [.to_rss()](#to_rss-key-silent-)<br>
     [.to_rss_all](#to_rss_all-silent-)<br>
     [.status](#status)<br>
6. [Structure](#structure)<br>
7. [Options](#options)<br>
   - [Single](#FeedIntosingle-2)<br>
   - [Group](#FeedIntogroup-1)<br>
8. [Channels](#channels)<br>
   - [Settings Structure](#settings-structure)
   - [Standard Components](#standard-components)<br>
   - [Custom Components](#custom-components)<br>
9. [Contributing](#contributing)
10. [Limitations](#limitations)
11. [Credits](#credits)<br>
12. [License](#license)<br>
13. [Code of Conduct](#code-of-conduct)<br>
14. [Support my Work](#support-my-work)<br>

<br>
<br>
<a href="#table-of-contents">
<img src="https://raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/headlines/quickstart.svg" height="38px" name="quickstart" alt="Quickstart">
</a>

```ruby
require 'feed_into'

channels = [
    {
        name: :blockchain,
        sym: :web,
        options: {},
        regexs: [ [ /https:\/\/your*website.com/ ] ],
        download: :general,
        mining: :rss_one,
        pre: [],
        transform: nil,
        post: [ :pre_titles ]
    }
]

feed = FeedInto::Group.new( 
    single: { channels: channels } 
)

urls = [ 'https://your*website.com/1.xml' ]
feed
    .analyse( items: urls )
    .status
```
<br>
<br>
<a href="#table-of-contents">
<img src="https://raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/headlines/setup.svg" height="38px" name="setup" alt="Setup">
</a>

Add this line to your application's Gemfile:

```ruby
gem 'feed_into'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install feed_into


On Rubygems: 
- Gem: https://rubygems.org/gems/feed_into
- Profile: https://rubygems.org/profiles/a6b8

<br>
<br>
<a href="#table-of-contents">
<img src="https://raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/headlines/input-types.svg" height="38px" name="input-types" alt="Input Types">
</a>

A valid url string is required. If you use ```::Group``` you need to wrap your strings in an array. Consider to use a ```Hash Structure``` for best results.

## FeedInto::Single

2 types of inputs are allowed ```String``` and ```Hash```. 
- ```String``` must be a valid url.
- ```Hash``` needs minimum an ```url:``` key with a valid url string. ```name:``` and ```category``` are optional.

<br name="input-a-1">

### A. 1. ```String URL```

**Input**
```ruby
cmd = 'https://your*website.com/1.xml'
feed.analyse( item: cmd )
```
Url must be from type ```String``` and  a ```valid url```.

**Internal Transformation to:**
```ruby
{
    name: 'Unknown',
    url: 'https://your*website.com/1.xml',
    category: :unknown
}
```

| **Name** | **Default** | **Description** |
|------:|:------|:------|
| **name:** | 'Unknown' | Set Name of Feed. If empty or not delivered the Name will set to 'Unknown' |
| **category:** | :unknown | Set Category of Feed. If empty or not delivered the Category will set to :unknown |

The keys ```name:``` and ```category``` are required internally. If not set by the user both will be added with the default values: "Unknown" and :unknown. See [A.2.](#input-a-2) for more Informations

<br name="input-a-2">

### A.2. ```Hash Structure``` (cmd)

**Struct**
```ruby
{
    name: String,
    url: String,
    category: Symbol
}
```

**Example**
```ruby
cmd = {
    name: 'Channel 1',
    url: 'https://your*website.com/1.xml',
    category: :nft
}

feed.analyse( item: cmd )
```

**Validation**
| **Name** | **Type / Regex** | **Required** | **Default** | **Description** |
|------:|:------|:------|:------|:------|
| **name:** | ```String``` | No | "Unknown" | Set Name of Feed. If empty or not delivered the Name will set to 'Channel 1' |
| **url** | ```String``` and ```valid url``` | Yes |  | Set url of Feed. |
| **category** | ```Symbol``` | No |  :unknown | Set Category of Feed. If empty or not delivered the Category will set to 'Channel 1' |
<br>
## FeedInto::Group

2 types of Arrays are allowed: ```Array of String``` or ```Array of Hash```.
- ```Array of String``` must be a valid urls strings.
- ```Array of Hash``` needs minimum an ```url:``` key with a valid url string per Hash.

<br name="input-b-1">

### B.1. ```Array of String```

**Example**
```ruby
cmds = [
    'https://your*website.com/1.xml',
    'https://your*website.com/2.xml'
]

feeds.analyse( items: cmds )
```
Validation Info see [A.1.](#input-a-1)

<br name="input-b-2">

### B.2. ```Array of Hash``` (cmds)

**Example**
```ruby
cmds = [
    {
        name: 'Channel 1',
        url: 'https://your*website.com/1.xml',
        category: :nft
    },
    {
        name: 'Channel 2',
        url: 'https://your*website.com/2.xml',
        category: :crypto
    }
]

feeds.analyse( items: cmds )
```
Validation Info see [A.2.](#input-a-2)

<br>

<a href="#table-of-contents">
<img src="https://raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/headlines/methods.svg" height="38px" name="methods" alt="Methods">
</a>

The methods are split in 2 classes "Single" and "Group". Single process only one url and inherit from Single and have all methods for bulk/group processing. For more details see [Structure](#structure).

## FeedInto::Single
### .new( modules: , options: )
Create a new Single Object to interact with.
```ruby
require 'feed_into'

feed = FeedInto::Single.new( 
    modules: './a/b/c/', 
    options: {}
)
```


**Input**
| **Name** | **Type** | **Required** | **Default** | **Example** | **Description** |
|------:|:------|:------|:------|:------|:------| 
| **module folder** | ```String``` | No | ```nil``` | ```modules: './a/b/c/'``` | Set Module Folder path. |
| **options** | ```Hash``` | No | ```{}``` | see [#options](#options) | Set options |

<br>

### .analyse( item: )
Start process of downloading, mining, modification and transforming based on your module setups.
```ruby
require 'feed_into'

feed = FeedInto::Single.new( 
    modules: './a/b/c/', 
    options: {}
)

cmd = {
    name: 'Channel 1',
    url: 'https://your*website.com/1.xml',
    category: :crypto
}

feed.analyse( item: cmd )

# feed.analyse( item: 'https://your*website.com/1.xml' )
```


**Input**
| **Name** | **Type** | **Required** | **Example** | **Description** |
|------:|:------|:------|:------|:------| 
| **item** | ```String``` or ```Hash Structure``` (see [Input A.2.](#input-a-2)) | Yes | item: 'https://your*website.com/1.xml' | Insert Url by String or Hash Structure |
<br>

## FeedInto::Group
### .new( modules:, group:, single: )
Create a new Group Object to interact with.
```ruby
require 'feed_into'

feed = FeedInto::Group.new( 
    modules: './a/b/c/', 
    group: {},
    single: {}
)
```


**Input**
| **Name** | **Type** | **Required** | **Default** | **Example** | **Description** |
|------:|:------|:------|:------|:------|:------| 
| **module folder** | ```String``` | No | ```nil``` | ```modules: './a/b/c/'``` | Set Module Folder path. |
| **group** | ```Hash``` | No | ```{}``` | see [Options](#options) | Set group options |
| **single** | ```Hash``` | No | ```{}``` | see [Options](#options) | Set group options |

**Return**<br>
Hash    
<br>

### .analyse( items: [], silent: false )
Start process of bulk execution.
```ruby
require 'feed_into'

feed = FeedInto::Group.new( 
    modules: './a/b/c/', 
    group: {},
    single: {}
)

cmds = [
    {
        name: 'Channel 1',
        url: 'https://your*website.com/1.xml',
        category: :nft
    },
    {
        name: 'Channel 2',
        url: 'https://your*website.com/2.xml',
        category: :crypto
    }
]

feed.analyse( items: cmds )
```


**Input**
| **Name** | **Type** | **Required** | **Default** | **Example** | **Description** |
|------:|:------|:------|:------|:------|:------| 
| **items** | ```Array of String``` or ```Array of Hash``` | Yes | | See [Input B.1.](#input-b-1) and [B.2.](#input-b-1) for examples and more details. | Set Inputs URLs |
| **silent** | ```boolean``` | No | ```false``` | silent: false | Print status messages |

**Return**<br>
Self

> To return result use ```.to_h```

<br>

### .merge
Re-arrange items by category and simplify data for rss output.

```ruby
require 'feed_into'

feed = FeedInto::Group.new( 
    modules: './a/b/c/', 
    group: {},
    single: {}
)

cmds = [
    {
        name: 'Channel 1',
        url: 'https://your*website.com/1.xml',
        category: :nft
    },
    {
        name: 'Channel 2',
        url: 'https://your*website.com/2.xml',
        category: :crypto
    }
]

feed
    .analyse( items: cmds )
    .merge
```

**Return**<br>
Self

> To return result use ```.to_h```

<br>

### .to_h( type: )
Output data to string.
```ruby
require 'feed_into'

feed = FeedInto::Group.new( 
    modules: './a/b/c/', 
    group: {},
    single: {}
)

cmds = [
    {
        name: 'Channel 1',
        url: 'https://your*website.com/1.xml',
        category: :nft
    },
    {
        name: 'Channel 2',
        url: 'https://your*website.com/2.xml',
        category: :crypto
    }
]

feed
    .analyse( items: cmds )
    .merge
    .to_h( type: :analyse ) 
```


**Input**
| **Name** | **Type** | **Required** | **Default** | **Example** | **Description** |
|------:|:------|:------|:------|:------|:------| 
| **type** | ```Symbol``` | No | ```nil``` | ```:analyse``` or ```:merge``` | Define explizit which hash should be returned. If not set .to_h will return ```:merge``` if not nil otherwise ```:analyse``` |

**Return**<br>
Hash    
<br>

### .to_rss( key:, silent: )
Output a ```.merge()``` category to a valid rss feed.

```ruby
require 'feed_into'

feed = FeedInto::Group.new( 
    modules: './a/b/c/', 
    group: {},
    single: {}
)

cmds = [
    {
        name: 'Channel 1',
        url: 'https://your*website.com/1.xml',
        category: :nft
    },
    {
        name: 'Channel 2',
        url: 'https://your*website.com/2.xml',
        category: :crypto
    }
]

feed
    .analyse( items: cmds )
    .merge
    .to_rss( key: :analyse ) 
```


**Input**
| **Name** | **Type** | **Required** | **Default** | **Example** | **Description** |
|------:|:------|:------|:------|:------|:------| 
| **key** | ```Symbol``` | Yes | ```nil``` | :nft | Only a single category will be transformed to rss. Define category here. |
| **silent** | ```Boolean``` | No | ```false``` | | Print status messages |

**Return**<br>
Hash    
<br>

### .to_rss_all( silent: )
Output ```.merge()``` categories to a valid rss feeds.
```ruby
require 'feed_into'

feed = FeedInto::Group.new( 
    modules: './a/b/c/', 
    group: {},
    single: {}
)

cmds = [
    {
        name: 'Channel 1',
        url: 'https://your*website.com/1.xml',
        category: :nft
    },
    {
        name: 'Channel 2',
        url: 'https://your*website.com/2.xml',
        category: :crypto
    }
]

feed
    .analyse( items: cmds )
    .merge
    .to_rss_all 
```


**Input**
| **Name** | **Type** | **Required** | **Default** | **Example** | **Description** |
|------:|:------|:------|:------|:------|:------| 
| **silent** | ```Boolean``` | No | ```false``` | | Print status messages |

**Return**<br>
Hash    
<br>


### .status
Outputs useful informations about the ```.analyse()``` pipeline.
```ruby
require 'feed_into'

feed = FeedInto::Group.new( 
    modules: './a/b/c/', 
    group: {},
    single: {}
)

cmds = [
    {
        name: 'Channel 1',
        url: 'https://your*website.com/1.xml',
        category: :nft
    },
    {
        name: 'Channel 2',
        url: 'https://your*website.com/2.xml',
        category: :crypto
    }
]

feed
    .analyse( items: cmds )
    .status
```


**Input**
| **Name** | **Type** | **Required** | **Default** | **Example** | **Description** |
|------:|:------|:------|:------|:------|:------| 
| **silent** | ```Boolean``` | No | ```false``` | | Print status messages |

**Return**<br>
Hash    

<br>
<a href="#table-of-contents">
<img src="https://raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/headlines/structure.svg" height="38px" name="structure" alt="Structure">
</a>

Class Overview

```
FeedInto::Single
FeedInto::Group

--> CLASS: Group
    ---------------------------------------
    |  - new( modules:, sgl:{}, grp:{} )  |
    |  - analyse( items:, silent: false ) |
    |  - merge                            |
    |  - to_h( type: nil )                |
    |  - to_rss( key: Symbol )            |
    |  - to_rss_all( silent: false )      |
    |                                     |
------> CLASS: Single                     |
    |   --------------------------------  |
    |   |  - new( modules:, opts:{} ) <---- MODULE FOLDER
    |   |  - analyse( item: )          |  |
    |   |                              |  |
    |   |   FUNCTIONS: General         |  |
    |   |   -------------------------  |  |
    |   |   |  - crl_general        |  |  |
    |   |   |   :download           |  |  |
    |   |   |   :pre_titles         |  |  |
    |   |   |   :mining_rss_one     |  |  |
    |   |   |   :mining_rss_two     |  |  |
    |   |   |   :format_url_s3      |  |  |
    |   |   |   :format_html_remove |  |  |
    |   |   -------------------------  |  |
    |   --------------------------------  |  
    ---------------------------------------
```

Custom Modules
```

    MODULE FOLDER "./a/b/c/"
    -----------------------------------------------
    |                                             |
    |   MODULE: #{Module_Name}                    |
    |    FILE:  #{module_name}.rb                 |
    |   -------------------------------------     |
    |   |  Required:                        |     |
    |   |  - crl_#{module_name}             |---  |
    |   |  - crl_#{module_name}_settings    |  |  | 
    |   |                                   |  |  | 
    |   |  Custom:                          |  |  |
    |   |  - crl_#{module_name}_custom_name |  |  |
    |   -------------------------------------  |  |
    |      |                                   |  |
    |      -------------------------------------  |
    |                                             |
    -----------------------------------------------
```
See [Channels](#channels) for more details.

</a>
<br>
<a href="#table-of-contents">
<img src="https://raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/headlines/options.svg" height="38px" name="options" alt="Options">
</a>

Options are split in 2 section: Single and Group. 

- In ```::Single``` use ```.new( ... options: )``` to set options.
- In ```::Group``` use ```.new( ... single:, group: )``` to set options.

**Example**
```ruby
options = {
    single: {
        format__title__symbol__vide: "🐨",
        format__title__symbol__custom: "👽"
    },
    group: {
        sleep__scores__user__value: 5,
        sleep__scores__server__value: 10
    }
}

# Single
feed = FeedInto::Single.new( 
    modules: './a/b/c/',
    options: options[:single]
)

# Group
feeds = FeedInto::Group.new( 
    modules: './a/b/c/',
    single: options[:single],
    group: options[:group]
)
```

## FeedInto::Single

| Nr | Name | Key | Default | Type | Description |
| :-- | :-- | :-- | :-- | :-- | :-- |
| 1. | Title Symbol Video |:format__title__symbol__video | `"👾"` | String | Set Symbol for Video, used in :pre_title |
| 2. | Title Symbol Custom |:format__title__symbol__custom | `"⚙️ "` | String | Set Symbol for Custom, used in :pre_title |
| 3. | Title Symbol Web |:format__title__symbol__web | `"🤖"` | String | Set Symbol for Web, used in :pre_title |
| 4. | Title Separator |:format__title__separator | `"\|"` | String | Change separator, used in :pre_title |
| 5. | Title More |:format__title__more | `"..."` | String | Used in :pre_title |
| 6. | Title Length |:format__title__length | `100` | Integer | Set a maximum length, used in :pre_title |
| 7. | Title Str |:format__title__str | `"{{sym}} {{cmd_name__upcase}} ({{channel_name__upcase}}) {{separator}} {{title_item__titleize}}"` | String | Set Title Structure, used in :pre_title |
| 8. | Download Agent |:format__download__agent | `""` | String | Set a Agent for Header Request. Use {version} to generate a random version. |

## FeedInto::Group

| Nr | Name | Key | Default | Type | Description |
| :-- | :-- | :-- | :-- | :-- | :-- |
| 1. | Range | :sleep__range | `15` | Integer | Set how many items are relevant to calculate score for sleeping time. |
| 2. | Varieties |:sleep__varieties | `[{:variety=>1, :sleep=>2}, {:variety=>2, :sleep=>1}, {:variety=>3, :sleep=>0.5}, {:variety=>4, :sleep=>0.25}, {:variety=>5, :sleep=>0.15}, {:variety=>6, :sleep=>0.1}]` | Array | Set diffrent sleep times by diffrent variety levels |
| 3. | Scores Ok Value |:sleep__scores__ok__value | `0` | Integer | Sleeping Time for :ok download. |
| 4. | Scores User Value |:sleep__scores__user__value | `1` | Integer | Sleeping Time for :user download errors. |
| 5. | Scores Server Value |:sleep__scores__server__value | `3` | Integer | Sleeping Time for :server download errors. |
| 6. | Scores Other Value |:sleep__scores__other__value | `0` | Integer | Sleeping Time for :other download errors. |
| 7. | Stages |:sleep__stages | `[{:name=>"Default", :range=>[0, 2], :skip=>false, :sleep=>0}, {:name=>"Low", :range=>[3, 5], :skip=>false, :sleep=>2}, {:name=>"High", :range=>[6, 8], :skip=>false, :sleep=>5}, {:name=>"Stop", :range=>[9, 999], :skip=>true}]` | Array | Set Sleep range for diffrent scores. |

<br>

<a href="#table-of-contents">
<img src="https://raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/headlines/channels.svg" height="38px" name="channels" alt="Channels">
</a>

To recognize an url, a "channel" must be created. A channel requires a ```Hash``` which defines the pipeline for the given regex urls. You don´t need to write your own module if you use the standard components. To extend the functionalities you can write your own module and initialize by refer to your module folder.


## Settings Structure

Every Channel need a Settings Structure to get recognized.
```ruby
{
    name: Symbol,
    sym: Symbol,
    options: Hash,
    regexs: Nested Array,
    download: Symbol,
    mining: Symbol,
    pre: Array of Symbols,
    transform: Symbol,
    post: Array of Symbols
}
```


| **Name** | **Type** | **Required** | **Example** | **Description** |
|------:|:------|:------|:------|:------|
| **name** | ```Symbol``` | Yes | ```:module_name``` | Set your unique channel name as symbol class |
| **sym** | ```Symbol``` | Yes |  ```:web``` | Assign a category sym to your channel. See [Options](#options) for more details. |
| **options** | ```Hash``` | Yes |  ```{ length: 23 }``` | Set specific channel variable here |
| **regexs** | ```Nested Array``` | Yes | ```[ [ /https:\/\/module_name/ ] ]```| To assign a given url to your channel use an Array (with multiple regexs) and wrap them in an Array. All Regexs from only **one** array must be true. |
| **download** | ```Symbol``` | Yes | ```:general``` | Select which 'download' method you prefer. |
| **mining** | ```Symbol``` | Yes | ```:rss_one``` | Select which 'mining' method you prefer. |
| **pre** | ```Array``` | Yes |  ```[]``` | Select which 'pre' methods you prefer. |
| **transform** | ```Symbol``` | ```nil``` |  | Select which 'transform' methods you prefer. |
| **post** | ```Array``` | Yes |  ```[ :pre_titles ]``` | Select which 'post' methods you prefer. |


## Standard Components
Inject a struct with **only** standard components in this way. You can find more informations about the available components in [Structure](#structure)

```ruby
require 'feed_into'

channels_settings = {
    name: :blockchain,
    sym: :web,
    options: {},
    regexs: [ [ /https:\/\/your*website.com/ ] ],
    download: :general,
    mining: :rss_one,
    pre: [],
    transform: nil,
    post: [ :pre_titles ]
}

feeds = FeedInto::Group.new( 
    single: { channels: [ channels_settings ] } 
)

feeds.analyse( items: [ 'https://your*website.com/1.xml' ] )

# feed = FeedInto::Single.new( 
#     options: { channels: struct } 
# )
# feed.analyse( item: 'https://your*website.com/1.xml' )
```


<a href="#table-of-contents">

## Custom Components
</a>

For custom functionalities you need to define a Module. Use the following boilerplate for a quickstart. Please note:
- Every function name starts with the prefix 'crl_'
- The channel will be automatically initialized by search for 'crl_module_name_settings'.
- Every pipeline contains five stages ```download```, ```mining```, ```pre```, ```transform```, ```post```. 
- The interaction with your Module is only over the function ```crl_module_name```. Delegate the traffic by a case statement.
- For later tasks you should give back a least ```:title```, ```:url``` and ```[:time][:stamp]```. 

**Step 1:** Create Module

./path/module_name.rb
```ruby
module ModuleName
  def crl_module_name( sym, cmd, channel, response, data, obj )
    messages = []

    case sym
      when :settings
        data = crl_module_name_settings()
      when :transform
        data = crl_module_name_transform( data, obj, cmd, channel )
    else
      messages.push( "module_name: #{sym} not found." )
    end
    
    return data, messages
  end
  

  private


  def crl_module_name_settings()
    {
      name: :module_name,
      sym: :video,
      options: {},
      regexs: [ [ /www.module_name.com/, /www.module_name.com/ ] ],
      download: :general,
      mining: :rss_two,
      pre: [],
      transform: :self,
      post: [ :pre_titles ]
    }
  end

  
  def crl_module_name_transform( data, obj, cmd, channel )
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
```


**Step 2:** Initialize Module
```ruby
require 'feed_into'

feeds = FeedInto::Group.new( 
    modules: './path/'
)

feeds
    .analyse( items: [ 'module_name.com/rss' ] )
    .merge
    .rss_to_all
```
<br>

<a href="#table-of-contents">
<img src="https://raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/headlines/contributing.svg" height="38px" name="contributing" alt="Contributing">
</a>

Bug reports and pull requests are welcome on GitHub at https:https://raw.githubusercontent.com/feed-into-for-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https:https://raw.githubusercontent.com/feed-into-for-ruby/blob/master/CODE_OF_CONDUCT.md).

<br>

<a href="#table-of-contents">
<img src="https://raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/headlines/limitations.svg" height="38px" name="limitations" alt="Limitations">
</a>

- Proof of Concept, not battle-tested.
<br>
<br>

<a href="#table-of-contents">
<img src="https://raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/headlines/credits.svg" height="38px" name="credits" alt="Credits">
</a>

This gem use following gems:

- [nokogiri](https://nokogiri.org)
- [net/http](https://github.com/ruby/net-http)
- [time](https://ruby-doc.org/core-2.6.3/Time.html)
- [tzinfo](https://github.com/tzinfo/tzinfo)
- [cgi](https://ruby-doc.org/stdlib-2.5.3/libdoc/cgi/rdoc/CGI.html)
- json
- [rss](https://github.com/ruby/rsshttps://github.com/ruby/rss)

<br>

<a href="#table-of-contents">
<img src="https://raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/headlines/license.svg" height="38px" name="license" alt="License">
</a>

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
<br>
<br>

<a href="#table-of-contents">
<img src="https://raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/headlines/code-of-conduct.svg" height="38px" name="code-of-conduct" alt="Code of Conduct">
</a>
    
Everyone interacting in the feed-into-for-ruby project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https:https://raw.githubusercontent.com/feed-into-for-ruby/blob/master/CODE_OF_CONDUCT.md).
<br>
<br>

<a href="#table-of-contents">
<img href="#table-of-contents" src="https://raw.githubusercontent.com/a6b8/a6b8/main/docs/feed-into-for-ruby/readme/headlines/support-my-work.svg" height="38px" name="support-my-work" alt="Support my Work">
</a>
    
Donate by [https://www.paypal.com](https://www.paypal.com/donate?hosted_button_id=XKYLQ9FBGC4RG)