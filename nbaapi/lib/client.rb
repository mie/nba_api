module NBAAPI

  class Client

    BASE_URI = URI.parse('http://stats.nba.com/')

    Scraper = Net::HTTP.new(BASE_URI.host, BASE_URI.port)

    STATS_TYPES = [ 
            "Overall",
            "WinsLosses",
            "Month",
            "Location",
            "PrePostAllStar",
            "DaysRest"
          ]
      
    DAILY_SCORE_ROWS = [ 
          "GameHeader",
          "LineScore",
          "SeriesStandings",
          "LastMeeting",
          "EastConfStandingsByDay",
          "WestConfStandingsByDay"
        ]
    
    GAME_ROWS = [ 
          "GameSummary",
          "LineScore",
          "SeasonSeries",
          "LastMeeting",
          "PlayerStats",
          "TeamStats",
          "OtherStats",
          "Officials",
          "GameInfo",
          "InactivePlayers"
        ]

    PARAMS = {
          :MeasureType => "Base",
          :PerMode => "Totals",
          :PlusMinus => "N",
          :PaceAdjust => "N",
          :Rank => "N",
          :Season => "2013-14",
          :SeasonType => "Regular Season",
          :TeamID => '0',
          :Outcome => '',
          :Location => '',
          :Month => '0',
          :SeasonSegment => '',
          :DateFrom => '',
          :DateTo => '',
          :OpponentTeamID => '0',
          :VsConference => '',
          :VsDivision => '',
          :GameSegment => '',
          :Period => '0',
          :LastNGames => '0'
        }
    
    ALL_TEAMS_PARAMS = PARAMS.merge({
          :GameScope => '',
          :PlayerExperience => '',
          :PlayerPosition => '',
          :StarterBench => ''
        })


    class << self

      def set_cache(redis, namespace)
        @cache = redis
        @namespace = namespace
      end

      def query(path, params, options = {}, row=nil)
        rowset = request(path, params.merge(options))
        (rowset != {} && row) ? rowset[row] : rowset
      end

      # Game

      def find_game(game_code, row=DAILY_SCORE_ROWS[0], options = {})
        date = game_code.split('/')[0]
        daily_games("#{date[0..3]}-#{date[4..5]}-#{date[6..7]}")
      end

      def get_game(game_id, options = {})
        query(
          '/stats/boxscore',
          {
            :GameID => game_id,
            :StartPeriod => '0',
            :EndPeriod => '0',
            :StartRange => '0',
            :EndRange => '0',
            :RangeType => '0'
          },
          options
        )
      end

      def daily_games(options = {}, row=DAILY_SCORE_ROWS[0])
        rowset = query(
          '/stats/scoreboard/',
          {
            :gameDate => 'date',
            :DayOffset => '0',
            :LeagueID => '00'
          },
          options
        )

        games = row!=DAILY_SCORE_ROWS[0] ?
          rowset[row]
          :
          rowset[row].map do |info|
            {'Game_ID' => info['GAME_ID']}
          end unless rowset == {}
        games
      end

      # Teams

      def find_team(search_params, options)
        team = all_teams(options).select{ |team|
          search_params.any? { |k,v|
            team[k.to_s].to_s == v.to_s
          }
        }
        team == [] ? {} : team[0]
      end

      def all_teams(options = {})
        d = query(
          '/stats/leaguedashteamstats',
          ALL_TEAMS_PARAMS,
          options,
          "LeagueDashTeamStats"
        )
      end

      def team_games(options = {})
        query(
          '/stats/teamgamelog',
          {
            :TeamID => '',
            :Season => "2013-14",
            :SeasonType => "Regular Season"
          },
          options,
          'TeamGameLog'
        )
      end

      def team_players(options = {})
        query(
          '/stats/teamplayerdashboard',
          PARAMS,
          options,
          'PlayersSeasonTotals'
        )
      end

      def team_stats(options = {}, row = STATS_TYPES[-1])
        p options
        query(
          '/stats/teamdashboardbygeneralsplits',
          PARAMS,
          options,
          row += 'TeamDashboard'
        )
      end

      # Helpers

      def request(path, params)
        url = path + '?' + params.map{ |k,v| k.to_s+'='+v.to_s.gsub(/\s+/, '+') }.join('&')
        output = {}
        begin
          response = Scraper.request(Net::HTTP::Get.new(url))
          puts "from NBA"
          output = parse_json(response.body.to_s)
        rescue Exception=>e
          puts(e.class)
          puts(e)
        end
        output
      end

      def parse_json(jsondata)
        output = {}
        begin
          JSON.parse(jsondata)['resultSets'].each { |d|
            kw = d['name']
            output[kw] = d['rowSet'].map { |row|
              Hash[d['headers'].zip(row)]
            }
          }
        rescue Exception => e
          puts(e.class)
          puts(e)
        end
        output
      end

    end

  end

end