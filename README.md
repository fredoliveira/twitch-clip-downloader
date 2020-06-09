# Twitch clip downloader

This is a simple ruby script that will grab twitch clips from a specific channel by using the [Twitch API](https://dev.twitch.tv/). The code should be quite simple to understand for folks who know ruby, so feel free to read through `downloader.rb`.

## Installation and usage

### Installing gem dependencies

Ruby dependencies like Faraday can be installed via bundler by running:

```bash
bundle
```

### Installing youtube-dl

This code uses `youtube-dl` to do the actual downloading of the clips, after getting their information from the API, so make sure you have a recent version of that installed. Installation instructions for `youtube-dl` are [available here](https://ytdl-org.github.io/youtube-dl/download.html), but in short:

If you're on a mac and use homebrew:

```bash
brew install youtube-dl
```

On debian-based linux distributions:

```
apt-get install youtube-dl
```

### Available options

In `downloader.rb` you'll notice a few constants you can use to tweak your downlods. These are copied below, with helper comments:

```
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
```

### Running the script

After setting up `downloader.rb` with your twitch API client ID, and setting the options mentioned above, you can run the script as follows:

```bash
ruby downloader.rb
```

A few things to keep in mind:

- This is heavy on your connection, obviously, as you'll be downloading a bunch of clips
- A download of around 1000 clips takes about 20gb of disk space (for 30 second average twitch clips)
- The whole process should take about 15minutes to complete
