module NBA_API

  class Team < Base
  
    def initialize(options)
      @id = options['TEAM_ID']
    end

    def stats(type = 'Overall')
      Client.team_stats({'TeamID' => @id}, type)
    end

    def games
      Client.team_games({'TeamID' => @id}).map{|game| Game.new(game)}
    end

    def players
      Client.team_players({'TeamID' => @id}).map{|player| Player.new(player)}
    end

    class << self

      def find(options)
        data = Client.find_team(options)
        data.nil? || data == {} ? nil : Team.new(data)
      end

      def all
        Client.all_teams.map {|team| Team.new(team)}
      end
      
      def east_standings(date)
        Client.daily_scores({"GameDate" => date}, Client::DAILY_SCORE[4]).map { |team|
          Team.new(team)
        }
      end
      
      def west_standings(date)
        Client.daily_scores({"GameDate" => date}, Client::DAILY_SCORE[5]).map { |team|
          Team.new(team)
        }
      end

    end

  end

end