class Player
  attr_accessor :name, :score, :move, :history

  def initialize
    set_name
    @score = 0
    @history = []
  end

  def to_s
    @name
  end
end

class Human < Player
  def set_name
    n = nil
    loop do
      puts "What's your name?"
      n = gets.chomp
      break unless n.empty?
      puts "Sorry, must enter a value."
    end
    self.name = n
  end

  def choose
    choice = nil
    loop do
      puts "\n#{name}, please choose #{Move::VALUES.join(', ')}:"
      choice = gets.chomp
      break if Move::VALUES.include? choice
      puts "Sorry, invalid choice."
    end

    self.move = Move::create_move(choice)
  end
end

class Computer < Player
  def set_name
    self.name = self.class.to_s
  end

  def choose
    self.move = Move::create_move(Move::VALUES.sample)
  end

  def intelligent_choose(n)
    if history.empty?
      potential_move = Move::create_move(Move::VALUES.sample)
    else
      # find human's most frequent move choice
      human_bias = find_human_bias(n)
      # choose a move that beats human's most frequent choice
      loop do
        potential_move = Move::create_move(Move::VALUES.sample)
        break if potential_move.wins_against?(human_bias)
      end
    end

    self.move = potential_move
  end

  def find_human_bias(n) # just in last `n` moves
    human_moves = []
    size = history.size >= n ? n : history.size
    history[-size..-1].each do |match|
      human_moves << match[:human]
    end
    human_moves.group_by(&:class)
    human_moves.group_by(&:class).max_by {|key, val| val.size}[1][0]
  end
end

class R2D2 < Computer
  def choose
    intelligent_choose(5)
  end
end

class Hal < Computer
  def choose
    intelligent_choose(7)
  end
end

class Chappie < Computer
  def choose
    intelligent_choose(1)
  end
end

class Furby < Computer
  def choose
    self.move = Rock.new
  end
end

class Bot < Computer; end

class Move
  VALUES = %w(rock paper scissors lizard spock)

  def self.create_move(string)
    case string
    when 'rock' then Rock.new
    when 'paper' then Paper.new
    when 'scissors' then Scissors.new
    when 'lizard' then Lizard.new
    when 'spock' then Spock.new
    end
  end

  def to_s
    self.class.to_s.downcase
  end

  def scissors?
    self.class == Scissors
  end

  def rock?
    self.class == Rock
  end

  def paper?
    self.class == Paper
  end

  def lizard?
    self.class == Lizard
  end

  def spock?
    self.class == Spock
  end

  def >(other_move)
    wins_against?(other_move)
  end

  def <(other_move)
    loses_against?(other_move)
  end
end

class Rock < Move
  def wins_against?(move)
    move.class == Scissors || move.class == Lizard
  end

  def loses_against?(move)
    move.class == Paper || move.class == Spock
  end
end

class Paper < Move
  def wins_against?(move)
    move.class == Rock || move.class == Spock
  end

  def loses_against?(move)
    move.class == Scissors || move.class == Lizard
  end
end

class Scissors < Move
  def wins_against?(move)
    move.class == Paper || move.class == Lizard
  end

  def loses_against?(move)
    move.class == Rock || move.class == Spock
  end
end

class Lizard < Move
  def wins_against?(move)
    move.class == Paper || move.class == Spock
  end

  def loses_against?(move)
    move.class == Rock || move.class == Scissors
  end
end

class Spock < Move
  def wins_against?(move)
    move.class == Rock || move.class == Scissors
  end

  def loses_against?(move)
    move.class == Lizard || move.class == Paper
  end
end

class RPSGame
  attr_accessor :human, :computer, :game_count
  WINNING_SCORE = 5

  def initialize
    @human = Human.new
    @computer = choose_computer_player
    @game_count = 1
  end

  def choose_computer_player
    selection = [1, 2, 3, 4, 5].sample
    case selection
    when 1 then R2D2.new
    when 2 then Hal.new
    when 3 then Chappie.new
    when 4 then Furby.new
    when 5 then Bot.new
    end
  end

  def reset_scores
    [human, computer].each {|player| player.score = 0}
    @game_count += 1
  end

  def display_welcome_message
    puts "Welcome to #{Move::VALUES.map(&:capitalize).join(', ')}!"
  end

  def display_goodbye_message
    puts "Thanks for playing #{Move::VALUES.map(&:capitalize).join(', ')}. Goodbye!"
  end

  def display_moves
    puts "#{human.name} chose: #{human.move}"
    puts "#{computer.name} chose: #{computer.move}"
  end

  def match_winner
    if human.move > computer.move
      human
    elsif human.move < computer.move
      computer
    else
      false
    end
  end

  def update_score
    match_winner.score += 1 if match_winner
  end

  def record_moves
    computer.history << {game: game_count, human: human.move, computer: computer.move, win: computer == match_winner}
  end

  def display_moves_history
    puts human.history
    puts computer.history
  end

  def display_match_winner
    if match_winner
      puts "#{match_winner.name} won!"
    else
      puts "It's a tie!"
    end
  end

  def game_winner?
    human.score >= WINNING_SCORE ||
      computer.score >= WINNING_SCORE
  end

  def display_game_winner
    winner = human if human.score >= WINNING_SCORE
    winner = computer if computer.score >= WINNING_SCORE
    puts "\n#{winner.name} wins the game!"
    display_score
  end

  def display_score
    puts "#{human.name}: #{human.score} | #{computer.name}: #{computer.score}"
  end

  def play_again?
    answer = nil

    loop do
      puts "Would you like to play again? (y/n)"
      answer = gets.chomp
      break if ['y', 'n'].include? answer.downcase
      puts "Sorry, must be 'y' or 'n'."
    end

    return true if answer == 'y'
    false
  end

  def play
    display_welcome_message
    loop do
      #display_moves_history
      loop do
        human.choose
        computer.choose
        system('clear')
        record_moves
        display_moves
        display_match_winner
        update_score
        display_score
        break if game_winner?
      end
      display_game_winner
      break unless play_again?
      reset_scores
    end
    display_goodbye_message
  end
end

RPSGame.new.play