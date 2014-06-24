# encoding: utf-8
module NBAAPI

  class Player < Base
  
    def initialize(options)
      key = options.each {|k,v|
        if k.upcase == 'PLAYER_ID'
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
  
    class << self

      def all
        Client.all_players.map{|player| Player.new(player)}
      end

    end

  end

end