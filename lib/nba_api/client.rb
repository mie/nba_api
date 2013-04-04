module NBA_API

  class Cache

    def initialize(max_age = 12*60*60)
      @dir = File.dirname(File.expand_path(__FILE__))
      @cache = {}
      @max_age = max_age
      load
    end

    # key = [type, id = nil]
    
    def read(k)
      out = k && @cache[k] && (Time.now - @cache[k][0] < @max_age) ? @cache[k][1] : nil
      puts '! --> from cache' if out
      out
    end

    def store(k, v)
      @cache[k] = [Time.now, v]
    end

    def keys
      @cache.keys
    end
    
    def read_by_keyword(kw)
      key = keys.select { |key| key[0] == kw }.map { |key| read(key) }
    end
    
    def dump
      fname = File.join("cache-#{Time.now.to_i}.save")
      File.open( fname, 'w' ){ |f|  
        Marshal.dump( @cache, f ) 
      }
    end
    
    def load
      caches = Dir.glob("cache-*.save").sort {|a,b| File.mtime(b) <=> File.mtime(a)}
      File.open(caches[0]) { |f|
        @cache = Marshal.load(f)
      } if caches != []
    end

  end

  class Client

    BASE_URI = URI.parse('http://stats.nba.com/')

    Scraper = ::Net::HTTP.new(BASE_URI.host, BASE_URI.port)

    @cache = Cache.new

    STATS_TYPES = [ 
          "Overall"
        ]
    
    DAILY_SCORE = [ 
          "GameHeader",
          "LineScore",
          "SeriesStandings",
          "LastMeeting",
          "EastConfStandingsByDay",
          "WestConfStandingsByDay"
        ]
    
    GAME_PARAMS = [ 
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
          'MeasureType' => "Base",
          'PerMode' => "Totals",
          'PlusMinus' => "N",
          'PaceAdjust' => "N",
          'Rank' => "N",
          'Season' => "2012-13",
          'SeasonType' => "Regular Season",
          'TeamID' => '0',
          'Outcome' => '',
          'Location' => '',
          'Month' => '0',
          'SeasonSegment' => '',
          'DateFrom' => '',
          'DateTo' => '',
          'OpponentTeamID' => '0',
          'VsConference' => '',
          'VsDivision' => '',
          'GameSegment' => '',
          'Period' => '0',
          'LastNGames' => '0'
        }
    
    ALL_TEAMS_PARAMS = PARAMS.merge({
          'GameScope' => '',
          'PlayerExperience' => '',
          'PlayerPosition' => '',
          'StarterBench' => ''
        })
    
    class << self
    
      def play_by_play(options)
        kw = "PlayByPlay"
        game_id = options['GameID']
        cached = get_from_cache([game_id, kw])
        return cached if cached
        path = '/stats/playbyplay'
        params = {
          'GameID' => game_id,
          'StartPeriod' => '0',
          'EndPeriod' => '0',
          'StartRange' => '0',
          'EndRange' => '0',
          'RangeType' => '0'
        }.merge(options)
        rowset = request(path, params)
        save_to_cache([game_id, kw], rowset[kw])
        rowset[kw]
      end

      def find_team(options)
        team = all_teams.select{ |team|
          options.any? { |k,v|
            team[k.to_s].to_s == v.to_s
          }
        }
        team == [] ? {} : team[0]
      end

      def find_game(options, kw = GAME_PARAMS[5])
        game_id = options['GameID']
        cached = get_from_cache([game_id, kw])
        return cached if cached
        path = '/stats/boxscore'
        params = {
          'GameID' => game_id,
          'StartPeriod' => '0',
          'EndPeriod' => '0',
          'StartRange' => '0',
          'EndRange' => '0',
          'RangeType' => '0'
        }.merge(options)
        rowset = request(path, params)
        GAME_PARAMS.each { |keyword|
          save_to_cache([game_id, keyword], rowset[keyword][0])
        }
        rowset[kw][0]
      end
      
      def team_games(options)
        kw = 'TeamGameLog'
        team_id = options['TeamID']
        cached = get_from_cache([team_id, kw])
        return cached if cached
        path = '/stats/teamgamelog'
        params = {
          "TeamID" => team_id,
          "Season" => "2012-13",
          "SeasonType" => "Regular Season"
        }.merge(options)

        rowset = request(path, params)
        save_to_cache([team_id, kw], rowset[kw])
        rowset[kw]
      end
      
      def team_players(options)
        kw = 'TeamOverall'
        team_id = options['TeamID']
        cached = get_from_cache([team_id, kw])
        return cached if cached
        path = '/stats/teamplayerdashboard'
        params = PARAMS.merge(options)

        rowset = request(path, params)
        save_to_cache([team_id, kw], rowset[kw])
        rowset[kw]
      end

      def team_stats(options, kw = STATS_TYPES[0])
        kw += 'TeamDashboard'
        team_id = options['TeamID']
        cached = get_from_cache([team_id, kw])
        return cached if cached
        path = '/stats/teamdashboardbygeneralsplits'
        params = PARAMS.merge(options)

        rowset = request(path, params)
        save_to_cache([team_id, kw], rowset[kw])
        rowset[kw]
      end

      def daily_scores(options = {}, kw = DAILY_SCORE[0])
        game_date = options['GameDate']
        c_scores = get_from_cache_by_keyword(game_date)
        cached = c_scores[0].map { |score|
          find_game('GameID' => score['GAME_ID'])
        } if game_date && c_scores != []
        return cached unless cached.nil? || cached == []
        path = '/stats/scoreboard/'
        params = {
          'GameDate' => 'TODAY',
          'DayOffset' => '0',
          'LeagueID' => '00',
          'Date' => Time.now.to_s
          }.merge (options)

        rowset = request(path, params)
        output = []
        if rowset
          output = rowset[kw].map { |gs|
            game = find_game({'GameID' => gs['GAME_ID']})
            game
          }
          DAILY_SCORE.each{ |ds|
            scores = save_to_cache([options['GameDate'], ds], rowset[ds])
          }
        end
        output
      end

      def all_teams(options = {})
        kw = 'LeagueDashTeamStats'
        cached = get_from_cache_by_keyword(kw)
        return cached[0] unless cached.nil? || cached == []
        path = '/stats/leaguedashteamstats'
        params = ALL_TEAMS_PARAMS.merge(options)
        
        rowset = request(path, params)
        save_to_cache([kw], rowset[kw])
        rowset[kw]
      end

      def all_players(options = {})
        kw = 'LeagueDashPlayerStats'
        cached = get_from_cache_by_keyword(kw)
        return cached[0] unless cached.nil? || cached == []
        path = '/stats/leaguedashplayerstats'
        params = PARAMS.merge(options)

        rowset = request(path, params)
        players = save_to_cache([kw], rowset[kw])
        rowset[kw]
      end
      
      def dump_cache
        @cache.dump
      end
      
      def load_cache
        @cache.load
      end

      private

      def get_from_cache_by_keyword(keyword)
        @cache.read_by_keyword(keyword)
      end

      def get_from_cache(key)
        @cache.read(key)
      end

      def request(path, params)
        url = path + '?' + params.map{ |k,v| k+'='+v.to_s.gsub(/\s+/, '+') }.join('&')
        begin
          response = Scraper.request(Net::HTTP::Get.new(url))
          puts "from NBA <-- !"
          output = parse_json(response.body.to_s)
        rescue Exception => e
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

      def save_to_cache(key, data)
        @cache.store(key, data)
      end
    
    end

  end

end