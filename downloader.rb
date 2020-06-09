# frozen_string_literal: true

# Running this will download all the twitch clips from Scotland-born
# magic-the-gathering superstar Stephen "Crokeyz" Croke, and will
# organize them properly, in a folder structure that looks like this:
#
# downloads/<game>/<viewcount>-<author>-<twitch_slug>.mp4
# downloads/<game>/<viewcount>-<author>-<twitch_slug>.json
#
# Most people won't care about the json bits, but they include a little
# bit more information about the clip, such as when it was created,
# the actual title of the clip (which didn't make it to the file name
# because it is a little too unpredictable), etc.
#
# Also note that to run this you need a twitch developer account,
# because you'll need to update the CLIENT_ID constant below. Only thing
# you should need to change, though. Every other constant should be pretty
# self-explanatory. You also need youtube-dl somewhere in your path.
#
# Also, this code could be better optimized, but it tries to play nice
# with the limits of the twitch API (and tries not to blast your internet
# connection). Anyways, enjoy the clips.

# -------------------------------------------------------------------------
# You can configure a few things here:
# -------------------------------------------------------------------------

# Your twitch developer app client ID
CLIENT_ID = 'CHANGE-ME-PLEASE-MISTER-USER-SIR'

# The channel you want to grab clips from
CHANNEL = 'crokeyz'

# For some reason, the twitch API stops giving us results after 12 pages
MAX_PAGES = 12

# If false, this script will only grab clip information to individual files
DOWNLOAD = true

# Endpoint for the clips. Only change if you know what you're doing.
CLIP_URL = 'https://api.twitch.tv/kraken/clips/top'

# The window of time to search for clips. Valid values: day, week, month, all
PERIOD = 'all'

# If true, the clips returned are ordered by popularity; otherwise, by viewcount
TRENDING = 'false'

# Order based on what's trending right now

# -------------------------------------------------------------------------
# Don't touch the code below unless you know what you are doing
# -------------------------------------------------------------------------

require 'rubygems'
require 'faraday'
require 'json'
require 'pp'
require 'fileutils'

# Grab clip information from the Twitch API
def grab_clips(cursor: nil)
  Faraday.get(CLIP_URL) do |req|
    req.params['cursor'] = cursor if cursor
    req.params['channel'] = CHANNEL
    req.params['period'] = PERIOD
    req.params['trending'] = TRENDING
    req.params['limit'] = 100

    req.headers['Accept'] = 'application/vnd.twitchtv.v5+json'
    req.headers['Client-ID'] = CLIENT_ID
  end
end

# Given a Faraday response, process it
def handle_response(response, page)
  # Write the response json to a file
  File.write("downloads/results-page-#{page}.json", response.body)

  # Parse the json
  response = JSON.parse(response.body)

  # Parse each individual clip
  response['clips'].each do |clip|
    parse_clip(clip)
  end

  # Grab the cursor
  response['_cursor'].to_s
end

# Depending on whether we want to download or just print results, do the thing
def parse_clip(clip)
  download_clip(
    clip['url'],
    "downloads/#{slug(clip['game'].to_s.strip)}/#{clip['views']}-#{clip['curator']['display_name']}-#{clip['slug']}"
  ) if DOWNLOAD

  FileUtils.mkdir_p "downloads/#{slug(clip['game'].to_s.strip)}"
  File.write("downloads/#{slug(clip['game'].to_s.strip)}/#{clip['views']}-#{clip['curator']['display_name']}-#{clip['slug']}.json", clip.to_json)
end

# Downloads a given clip URL using youtube-dl
def download_clip(url, name)
  puts "Downloading #{url}"
  system "youtube-dl -q -o \"#{name}.%(ext)s\" #{url}"
  sleep(1)
end

# Handle the game name so that we can create folders with good names
def slug(name)
  name.downcase.gsub(/'/, '').gsub(/[^a-z0-9]+/, '-').chomp('')
end

# Do all the things
page = 1
cursor = nil

while page < MAX_PAGES
  puts "Grabbing page #{page} with cursor #{cursor}"
  response = grab_clips(cursor: cursor)
  cursor = handle_response(response, page)
  page = page + 1

  puts "Sleeping for 10 seconds"
  sleep(10)
end
