module NBA_API

  class Player < Base
  
  def initialize(options)
    @id = options['PLAYER_ID'].to_s
  end
  
    class << self

      def all
        Client.all_players.map{|player| Player.new(player)}
      end

    end

  end

end