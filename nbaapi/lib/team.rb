# encoding: utf-8
module NBAAPI

  class Team < Base
  
    def initialize(options)
      key = options.each {|k,v|
        if k.upcase == 'TEAM_ID'
          @id = v.to_s
        else
          name = "@#{k.downcase}"
          instance_variable_set(name, v)
         
          self.class.send(:define_method, k.downcase) do
            instance_variable_get(name)
          end

        end
      }
    end

    def id
      @id
    end

    def stats(options = {}, row=Client::STATS_TYPES[0])
      input_data = {:Season => @season, :SeasonType => @seasontype}.merge(options)
      Client.team_stats({:TeamID => @id}.merge(input_data), row)
    end

    def games_brief(options = {})
      input_data = {:Season => @season, :SeasonType => @seasontype}.merge(options)
      Client.team_games({:TeamID => @id}.merge(input_data)).map{|game| Game.new(game)}
    end

    alias :games :games_brief

    def games_full(options = {})
      input_data = {:Season => @season, :SeasonType => @seasontype}.merge(options)
      Client.team_games({:TeamID => @id}.merge(input_data)).map{|game| Game.new(game).get_info}
    end

    def players(options = {})
      input_data = {:Season => @season, :SeasonType => @seasontype}.merge(options)
      Client.team_players({:TeamID => @id}.merge(input_data)).map{|player| Player.new(player)}
    end

    def with_opponent(team)
      team_id = team.class == String ? Team.find(team).id : team.id
      stats({:OpponentTeamID => team_id})
    end

    class << self

      def find(search_params, options={})
        opts = search_params.class == String ? {:TEAM_NAME => search_params} : search_params
        data = Client.find_team(opts, options)
        p data
        input_data = {:Season => '2013-14', :SeasonType => 'Playoffs'}.merge(options)
        data.nil? || data == {} ? nil : Team.new(data.merge(input_data))
      end

      def all
        Client.all_teams.map {|team| Team.new(team)}
      end
      
      def east_standings(date = nil)
        unless date
          time = Time.now
          t = time + time.gmt_offset - 5*60*60
          date = t.strftime("%m/%d/%Y")
        end
        teams = Client.all_teams
        Client.daily_games({:gameDate => date}, Client::DAILY_SCORE_ROWS[4]).map { |t|
          Team.new(teams.select{|team| team['TEAM_ID'] == t['TEAM_ID']}[0])
        }
      end
      
      def west_standings(date = nil)
        unless date
          time = Time.now
          t = time + time.gmt_offset - 5*60*60
          date = t.strftime("%m/%d/%Y")
        end
        teams = Client.all_teams
        Client.daily_games({:gameDate => date}, Client::DAILY_SCORE_ROWS[5]).map { |t|
          Team.new(teams.select{|team| team['TEAM_ID'] == t['TEAM_ID']}[0])
        }
      end

    end

  end

end