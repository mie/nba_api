# encoding: utf-8

# module ArrayMethods

class Array

  def wins
    self.select{|e| e.wl == 'W'}
  end

  def loses
    self.select{|e| e.wl == 'L'}
  end

  def vs(team) # vs('Chicago Bulls')
    self.select{|e| e.matchup.split(' vs. ')[1] == NBAAPI::TEAM_DATA[team][:name] if e.respond_to? :matchup}
  end

  def at(team) # at('Chicago Bulls')
    # self.select{|e| p e.matchup.split(' @ ')}
    self.select{ |e|
      teams = e.matchup.split(' @ ') if e.respond_to? :matchup
      teams[1] == NBAAPI::TEAM_DATA[team.team_name][:name] if teams && teams.size > 1}
  end

end

# end

module NBAAPI

  class Game < Base

    def initialize(rowset)
      # @rowset = rowset
      data = rowset[Client::GAME_ROWS[0]].nil? ? rowset : rowset[Client::GAME_ROWS[0]][0]
      key = data.each {|k,v|
        if k.upcase == 'GAME_ID'
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

    def get_info
      game = Client.get_game(@id)
      Client::GAME_ROWS.each { |r|
        mn = camel2simple(r)
        remove_method(mn) if self.public_methods.include? (mn)
        bl = Proc.new { game[r] }
        create_method(mn, bl)
      }
      self
    end

    class << self

      def on(date = 'TODAY')
        Client.daily_games({:gameDate => date}, Client::DAILY_SCORE_ROWS[0]).map { |game|
          Game.new(game).get_info
        }
      end

      def today
        time = Time.now
        t = time + time.gmt_offset - 5*60*60
        d = t.strftime("%m/%d/%Y")
        games = Client.daily_games({:gameDate => d}, Client::DAILY_SCORE_ROWS[0]).map { |game|
          Game.new(game).get_info
        }
      end

      def tomorrow
        time = Time.now + 60*60*24
        t = time + time.gmt_offset - 5*60*60
        d = t.strftime("%m/%d/%Y")
        Client.daily_games({:gameDate => d}, Client::DAILY_SCORE_ROWS[0]).map { |game|
          Game.new(game).get_info
        }
      end

    end

  end

end
