module NBA_API

  class Game < Base
  
  def initialize(options)
    key = options.each {|k,v| @id = v.to_s if k.upcase == 'GAME_ID'}
    Client::GAME_PARAMS.select { |param| param != "LastMeeting" }.each { |name|
      bl = Proc.new { Client.find_game({'GameID' => @id}, name) }
      create_method(name, bl)
    }
  end
  
  def last_meeting
    lastg_id = Client.find_game({'GameID' => @id}, "LastMeeting")['LAST_GAME_ID']
    lastg = Client.find_game({'GameID' => lastg_id})
    Game.new(lastg)
  end
  
  def home_team
    home_id = Client.find_game({'GameID' => @id}, Client::GAME_PARAMS[2])['HOME_TEAM_ID']
    homet = Client.find_team({'TEAM_ID' => home_id})
    Team.new(homet)
  end

  def visitor_team
    vis_id = Client.find_game({'GameID' => @id}, Client::GAME_PARAMS[2])['VISITOR_TEAM_ID']
    vist = Client.find_team({'TEAM_ID' => vis_id})
    Team.new(vist)
  end
  
  def play_by_play
    Client.play_by_play({'GameID' => @id})
  end
  
    class << self

      def on(date = 'TODAY')
        Client.daily_scores({"GameDate" => date}, Client::DAILY_SCORE[0]).map { |game|
          Game.new(game)
        }
      end

    end

  end

end