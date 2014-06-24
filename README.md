NBAAPI - обертка вокруг неофициально доступных API сайта stats.nba.com.

Примеры использования:

    team = NBAAPI::Team.find('Dallas Mavericks', {:Season => '2013-14', :SeasonType => 'Regular Season'})
    opp = NBAAPI::Team.find('Los Angeles Lakers', {:Season => '2013-14', :SeasonType => 'Regular Season'})
    team.games.loses
    team.games.wins
    team.games.wins.vs('Los Angeles Clippers')
    team.games.wins.at(opp)
    team.players
    team.stats

    games = NBAAPI::Game.today
    games = NBAAPI::Game.tomorrow
    NBAAPI::Game.on('04/01/2014').each do |game|
      puts game.game__summary
      puts game.line__score
      puts game.officials
      puts game.season__series
      puts game.last__meeting
      puts game.player__stats
      puts game.team__stats
      puts game.other__stats
      puts game.game__info
      puts game.inactive__players
    end

Примечание:

В приведенных примерах объекты массивов team.games и, например, NBAAPI::Game.today разнятся (таковы особенности выдачи внешнего API). В первом случае будут доступны только основные статистические параметры матча в виде методов-геттеров. Для получения подробных данных нужно выполнить

    team.games_full

или

    team.games.map {|g| g.get_info}

В этом случае объекты обзаведутся методами game__summary, line__score, officials, который уже есть в наличии в случае NBAAPI::Game.today

