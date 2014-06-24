# encoding: utf-8

require 'net/http'
require 'time'
require 'json'

require_relative 'lib/base'
require_relative 'lib/client'
require_relative 'lib/game'
require_relative 'lib/player'
require_relative 'lib/team'

module NBAAPI

  TEAM_DATA = {
    'Boston Celtics' => {
      :name => 'BOS',
      :subreddit => 'http://www.reddit.com/r/bostonceltics',
      :broadcaster => 'CSN New England',
      :arena => 'TD Garden'},
    'Toronto Raptors' => {
      :name => 'TOR',
      :subreddit => 'http://www.reddit.com/r/torontoraptors',
      :broadcaster => 'TSN',
      :arena => 'Air Canada Centre'},
    'Philadelphia 76ers' => {
      :name => 'PHI',
      :subreddit => 'http://www.reddit.com/r/sixers',
      :broadcaster => 'CSN Philadelphia',
      :arena => 'Wells Fargo Center'},
    'Brooklyn Nets' => {
      :name => 'BKN',
      :subreddit => 'http://www.reddit.com/r/gonets',
      :broadcaster => 'Yes Network',
      :arena => 'Barclays Center'},
    'New York Knicks' => {
      :name => 'NYK',
      :subreddit => 'http://www.reddit.com/r/nyknicks',
      :broadcaster => 'MSG Network',
      :arena => 'Madison Square Garden'},
    'Indiana Pacers' => {
      :name => 'IND',
      :subreddit => 'http://www.reddit.com/r/pacers',
      :broadcaster => 'Fox Sports Indiana',
      :arena => 'Bankers Life Fieldhouse'},
    'Detroit Pistons' => {
      :name => 'DET',
      :subreddit => 'http://www.reddit.com/r/detroitpistons',
      :broadcaster => 'Fox Sports Detroit',
      :arena => 'The Palace of Auburn Hills'},
    'Chicago Bulls' => {
      :name => 'CHI',
      :subreddit => 'http://www.reddit.com/r/chicagobulls',
      :broadcaster => 'CSN Chicago',
      :arena => 'United Center'},
    'Cleveland Cavaliers' => {
      :name => 'CLE',
      :subreddit => 'http://www.reddit.com/r/clevelandcavs',
      :broadcaster => 'Fox Sports Ohio',
      :arena => 'Quicken Loans Arena'},
    'Milwaukee Bucks' => {
      :name => 'MIL',
      :subreddit => 'http://www.reddit.com/r/mkebucks',
      :broadcaster => 'Fox Sports Wisconsin',
      :arena => 'BMO Harris Bradley Center'},
    'Miami Heat' => {
      :name => 'MIA',
      :subreddit => 'http://www.reddit.com/r/heat',
      :broadcaster => 'Sun Sports',
      :arena => 'American Airlines Arena'},
    'Atlanta Hawks' => {
      :name => 'ATL',
      :subreddit => 'http://www.reddit.com/r/atlantahawks',
      :broadcaster => 'SportSouth',
      :arena => 'Philips Arena'},
    'Washington Wizards' => {
      :name => 'WAS',
      :subreddit => 'http://www.reddit.com/r/washingtonwizards',
      :broadcaster => 'CSN Mid-Atlantic',
      :arena => 'Verizon Center'},
    'Charlotte Bobcats' => {
      :name => 'CHA',
      :subreddit => 'http://www.reddit.com/r/charlottebobcats',
      :broadcaster => 'SportSouth',
      :arena => 'Time Warner Cable Arena'},
    'Orlando Magic' => {
      :name => 'ORL',
      :subreddit => 'http://www.reddit.com/r/orlandomagic',
      :broadcaster => 'Fox Sports Florida',
      :arena => 'Amway Center'},
    'Portland Trail Blazers' => {
      :name => 'POR',
      :subreddit => 'http://www.reddit.com/r/ripcity',
      :broadcaster => 'CSN Northwest',
      :arena => 'Moda Center'},
    'Oklahoma City Thunder' => {
      :name => 'OKC',
      :subreddit => 'http://www.reddit.com/r/thunder',
      :broadcaster => 'Fox Sports Oklahoma',
      :arena => 'Chesapeake Energy Arena'},
    'Denver Nuggets' => {
      :name => 'DEN',
      :subreddit => 'http://www.reddit.com/r/denvernuggets',
      :broadcaster => 'Altitude Sports and Entertainment',
      :arena => 'Pepsi Center'},
    'Minnesota Timberwolves' => {
      :name => 'MIN',
      :subreddit => 'http://www.reddit.com/r/timberwolves',
      :broadcaster => 'Fox Sports North',
      :arena => 'Target Center'},
    'Utah Jazz' => {
      :name => 'UTA',
      :subreddit => 'http://www.reddit.com/r/utahjazz',
      :broadcaster => 'Root Sports Utah',
      :arena => 'EnergySolutions Arena'},
    'Los Angeles Clippers' => {
      :name => 'LAC',
      :subreddit => 'http://www.reddit.com/r/laclippers',
      :broadcaster => 'Fox Sports West',
      :arena => 'Staples Center'},
    'Golden State Warriors' => {
      :name => 'GSW',
      :subreddit => 'http://www.reddit.com/r/warriors',
      :broadcaster => 'CSN Bay Area',
      :arena => 'Oracle Arena'},
    'Phoenix Suns' => {
      :name => 'PHX',
      :subreddit => 'http://www.reddit.com/r/suns',
      :broadcaster => 'Fox Sports Arizona',
      :arena => 'US Airways Center'},
    'Los Angeles Lakers' => {
      :name => 'LAL',
      :subreddit => 'http://www.reddit.com/r/lakers',
      :broadcaster => 'Time Warner Cable SportsNet',
      :arena => 'Staples Center'},
    'Sacramento Kings' => {
      :name => 'SAC',
      :subreddit => 'http://www.reddit.com/r/kings',
      :broadcaster => 'CSN California',
      :arena => 'Sleep Train Arena'},
    'San Antonio Spurs' => {
      :name => 'SAS',
      :subreddit => 'http://www.reddit.com/r/nbaspurs',
      :broadcaster => 'Fox Sports SouthWest',
      :arena => 'AT&T Center'},
    'Houston Rockets' => {
      :name => 'HOU',
      :subreddit => 'http://www.reddit.com/r/rockets',
      :broadcaster => 'CSN Houston',
      :arena => 'Toyota Center'},
    'Dallas Mavericks' => {
      :name => 'DAL',
      :subreddit => 'http://www.reddit.com/r/mavericks',
      :broadcaster => 'Fox Sports SouthWest',
      :arena => 'American Airlines Center'},
    'New Orleans Pelicans' => {
      :name => 'NOP',
      :subreddit => 'http://www.reddit.com/r/nolapelicans',
      :broadcaster => 'Fox Sports New Orleans',
      :arena => 'Smoothie King Center'},
    'New Orleans Hornets' => {
      :name => 'NOH',
      :subreddit => 'http://www.reddit.com/r/nolapelicans',
      :broadcaster => 'Fox Sports New Orleans',
      :arena => 'Smoothie King Center'},
    'Memphis Grizzlies' => {
      :name => 'MEM',
      :subreddit => 'http://www.reddit.com/r/memphisgrizzlies',
      :broadcaster => 'SportSouth',
      :arena => 'FedExForum'}
  }

end