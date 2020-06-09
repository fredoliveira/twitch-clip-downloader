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

require 'rubygems'
require 'faraday'
require 'json'
require 'pp'
require 'fileutils'

CLIENT_ID = 'CHANGE-ME-HERE-MISTER-USER-SIR'
CLIP_URL = 'https://api.twitch.tv/kraken/clips/top'
CHANNEL = 'crokeyz'
MAX_PAGES = 12
DOWNLOAD = true

GAMES = {
  "Gwent: The Witcher Card Game" => "gwent",
  "Magic: The Gathering" => "mtg",
  "The Witcher 3: Wild Hunt" => "witcher3",
  "Artifact" => "artifact",
  "World of Warcraft" => "wow",
  "Slay the Spire" => "slaythespire",
  "The Witness" => "witness",
  "Two Point Hospital" => "twopointhospital",
  "Cuphead" => "cuphead"
}

# Grab clip information from the Twitch API
def grab_clips(cursor: nil)
  Faraday.get(CLIP_URL) do |req|
    req.params['cursor'] = cursor if cursor
    req.params['channel'] = CHANNEL
    req.params['period'] = 'all'
    req.params['trending'] = 'false'
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
    "downloads/#{GAMES["#{clip['game'].to_s.strip}"]}/#{clip['views']}-#{clip['curator']['display_name']}-#{clip['slug']}"
  ) if DOWNLOAD

  FileUtils.mkdir_p "downloads/#{GAMES["#{clip['game'].to_s.strip}"]}"
  File.write("downloads/#{GAMES["#{clip['game'].to_s.strip}"]}/#{clip['views']}-#{clip['curator']['display_name']}-#{clip['slug']}.json", clip.to_json)
end

# Downloads a given clip URL using youtube-dl
def download_clip(url, name)
  puts "Downloading #{url}"
  system "youtube-dl -q -o \"#{name}.%(ext)s\" #{url}"
  sleep(1)
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
