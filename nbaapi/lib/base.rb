# encoding: utf-8
module NBAAPI

  class Base

    private
    
    def create_method(camel, block)
      self.class.send(:define_method, camel2simple(camel), block)
    end
    
    def camel2simple(camel)
      words = []
      buf = ''
      camel.each_char { |c|
        if c.upcase == c
          if c == 'D' && buf == 'i'
            words.push('id')
            buf == ''
          else
            words.push(buf) unless buf == ''
            buf = c.downcase
          end
        elsif c.downcase == c
          buf += c
        end
      }
      words.push(buf) unless buf == ''
      words.join('_')
    end
    
    def simple2camel(simple)
      simple.split('_').map { |word|
        if word == 'id'
          'ID'
        else
          word.capitalize
        end
      }.join('')
    end
    
  end

end