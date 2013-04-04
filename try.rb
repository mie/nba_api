require 'nbaapi'

team = NBAAPI::Team.find("TEAM_NAME" => "Utah Jazz")
games = team.games
pbp = games[0].play_by_play
p games[0].team_stats
players = team.players
#NBAAPI::Client.dump_cache
#NBAAPI::Client.load_cache