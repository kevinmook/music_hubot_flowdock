# Description:
#   Control a shared music server
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_MUSIC_API_KEY
#
# Commands:
#   hubot play <spotify_uri>      - Starts playing the given spotify uri (get by right clicking a song in spotify and clicking "Copy Spotify URI")
#   hubot pause                   - Pauses the music
#   hubot stop                    - Pauses the music
#   hubot unpause                 - Resumes the music
#   hubot resume                  - Resumes the music
#   hubot next                    - Skips to the next song
#   hubot skip                    - Skips to the next song
#   hubot previous                - Goes to the previous song
#   hubot back                    - Goes to the previous song
#   hubot shuffle                 - Shuffles the music
#   hubot don't shuffle           - Stops shuffling the music
#   hubot loop                    - Loops the music
#   hubot don't loop              - Stops looping the music
#   hubot repeat                  - Loops the music
#   hubot don't repeat            - Stops looping the music
#   hubot what's the volume?      - Gets the current volume
#   hubot set volume <0 to 100>   - Sets the volume to the given percentage
#   hubot what's playing?         - Lists what's currently being played
#
# Author:
#   Kevin Mook (@kevinmook)

module.exports = (robot) ->

  robot.respond /\s*play (.*)/i, (msg) ->
    tellSpotify msg, 'play', 'POST', {uri: msg.match[1]}, (response) ->
      track = response['track']
      artist = response['artist']
      msg.send "Now playing '#{track}' by '#{artist}.'"
  
  robot.respond /\s*(?:pause|stop)/i, (msg) ->
    tellSpotify msg, "pause", 'POST', {}, (response) ->
      msg.send "The music has been paused."
  
  robot.respond /\s*(?:unpause|resume|play)/i, (msg) ->
    tellSpotify msg, "resume", 'POST', {}, (response) ->
      msg.send "The music has been resumed."
  
  robot.respond /\s*(?:skip|next)/i, (msg) ->
    tellSpotify msg, "next", 'POST', {}, (response) ->
      msg.send "The current song has been skipped."
  
  robot.respond /\s*(?:previous|back)/i, (msg) ->
    tellSpotify msg, "previous", 'POST', {}, (response) ->
      msg.send "Going back to the previous song."
  
  robot.respond /\s*shuffle/i, (msg) ->
    tellSpotify msg, "shuffle", 'POST', {shuffle: true}, (response) ->
      msg.send "The playlist will now be shuffled."
  
  robot.respond /\s*don.?t shuffle/i, (msg) ->
    tellSpotify msg, "shuffle", 'POST', {shuffle: false}, (response) ->
      msg.send "The playlist will not be shuffled."
  
  robot.respond /\s*(?:loop|repeat)/i, (msg) ->
    tellSpotify msg, "repeat", 'POST', {repeat: true}, (response) ->
      msg.send "The playlist will now be looped."
  
  robot.respond /\s*don.?t (?:loop|repeat)/i, (msg) ->
    tellSpotify msg, "repeat", 'POST', {repeat: false}, (response) ->
      msg.send "The playlist will not be looped."
  
  robot.respond /\s*set (?:the )?volume (?:to )?([0-9]+)/i, (msg) ->
    tellSpotify msg, "volume", 'POST', {volume: msg.match[1]}, (response) ->
      volume = response['volume']
      msg.send "The volume has been set to #{volume}."
  
  robot.respond /\s*what.?s (?:the )?volume\??/i, (msg) ->
    tellSpotify msg, "status", 'GET', {}, (response) ->
      volume = response['volume']
      msg.send "The volume is at #{volume}."
  
  robot.respond /\s*what.?s playing\??/i, (msg) ->
    tellSpotify msg, "status", 'GET', {}, (response) ->
      track = response['track']
      artist = response['artist']
      uri = response['uri']
      url = uri.replace(/:/g, "/").replace("spotify/", "http://open.spotify.com/")
      msg.send "#{url}"

tellSpotify = (msg, command, method, params, callback) ->
  music_api_key = process.env.HUBOT_MUSIC_API_KEY
  if !music_api_key
    msg.send "Music API key is not set, unable to continue"
    return
  
  params_array = []
  params_array_str = ""
  
  for key, value of params
    clean_key = escape(key)
    clean_value = escape(value)
    params_array.push "#{clean_key}=#{clean_value}"
  
  if params_array.length > 0
    params_array_str = params_array.join("&")
  
  url = "https://music-remote.herokuapp.com/api/hubot/v1/#{music_api_key}/#{command}"
  remote_call = null
  switch method
    when 'GET'
      url = "#{url}?#{params_array_str}" if params_array_str.length > 0
      remote_call = msg.http(url).get()
    when 'POST'
      remote_call = msg.http(url).post(params_array_str)
  
  if remote_call
    remote_call (err, res, body) =>
      if err
        msg.send "Error communicating with the music client: #{err}"
        return
      content = JSON.parse(body)
      if content?
        if content['success']
          callback(content['status'])
        else if content['error']
          msg.send content['error']
        else
          msg.send "Error communicating with the music client"
      else
        msg.send "Invalid response"
  else
    msg.send "Invalid request"
