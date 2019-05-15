require 'pry'

class Board
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] + # rows
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] + # columns
                  [[1, 5, 9], [3, 5, 7]] # diagonals
  attr_reader :squares

  def initialize
    @squares = {}
    reset
  end

  # rubocop:disable Metrics/AbcSize
  def draw
    puts "     |     |"
    puts "  #{squares[1]}  |  #{squares[2]}  |  #{squares[3]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{squares[4]}  |  #{squares[5]}  |  #{squares[6]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{squares[7]}  |  #{squares[8]}  |  #{squares[9]}"
    puts "     |     |"
  end
  # rubocop:enable Metrics/AbcSize

  def unmarked_keys
    squares.keys.select { |key| squares[key].unmarked? }
  end

  def full?
    unmarked_keys.empty?
  end

  def empty?
    unmarked_keys.size == 9
  end

  def match_winner?
    !!winning_marker
  end

  def winning_marker
    # return winning marker or nil
    WINNING_LINES.each do |line|
      row_of_squares = squares.values_at(*line)
      if three_identical_markers?(row_of_squares)
        return row_of_squares.first.marker
      end
    end
    nil
  end

  def defensive_play(marker)
    WINNING_LINES.each do |line|
      row_of_squares = squares.values_at(*line)
      if threat?(marker, row_of_squares)
        target = nil
        line.each do |square|
          target = square if squares[square].marker == Square::INITIAL_MARKER
        end
        return target
      end
    end
    nil
  end

  def offensive_play(marker)
    defensive_play(marker)
  end

  def threat?(marker, squares)
    markers = squares.map(&:marker)
    markers.uniq.sort == [marker, Square::INITIAL_MARKER].sort &&
      markers.count(Square::INITIAL_MARKER) == 1
  end

  def reset
    (1..9).each { |key| @squares[key] = Square.new }
  end

  def []=(square, marker)
    squares[square].marker = marker
  end

  def [](square)
    squares[square]
  end

  private

  def three_identical_markers?(squares)
    markers = squares.select(&:marked?).collect(&:marker)
    markers.size == 3 && markers.uniq.size == 1
  end
end

class Square
  INITIAL_MARKER = " "
  attr_accessor :marker

  def initialize(marker=INITIAL_MARKER)
    @marker = marker
  end

  def unmarked?
    marker == INITIAL_MARKER
  end

  def marked?
    marker != INITIAL_MARKER
  end

  def to_s
    marker
  end
end

class Player
  attr_reader :marker, :name
  attr_accessor :score

  def initialize(name, marker)
    @name = name
    @marker = marker
    @score = 0
  end
end

class Human < Player
  def initialize
    super(set_name, set_marker)
  end

  def set_name
    puts "What is your name?"
    gets.chomp
  end

  def set_marker
    puts "What character would you like to use as a marker?"
    marker = nil
    loop do
      marker = gets.chomp
      break if marker.size == 1
      puts "Please only type one character."
    end
    marker
  end
end

class Computer < Player
  NAMES = ['Chappie', 'R2D2', 'Hal', 'Bender']
 
  def initialize(human_marker)
    super(set_name, set_marker(human_marker))
  end

  def set_name
    NAMES.sample
  end

  def set_marker(human_marker)
    if human_marker == 'O'
      'X'
    else
      'O'
    end
  end
end


class TTTGame
  WINNING_SCORE = 5

  attr_reader :board, :human, :computer
  attr_accessor :current_marker

  def initialize
    @board = Board.new
    @human = Human.new
    @computer = Computer.new(human.marker)
    @current_marker = human.marker
  end

  def display_board
    puts "#{human.name}, you are a #{human.marker}. #{computer.name} is a #{computer.marker}."
    puts ""
    board.draw
    puts ""
  end

  def clear_screen_and_display_board
    clear_screen
    display_board
  end

  def display_welcome_message
    puts "Welcome to Tic Tac Toe!"
    puts ""
  end

  def display_goodbye_message
    puts "Thanks for playing!"
  end

  def current_player_moves
    if human_turn?
      human_moves
      @current_marker = computer.marker
    else
      computer_moves
      @current_marker = human.marker
    end
  end

  def human_turn?
    current_marker == human.marker
  end

  def human_moves
    display_score unless human.score == 0 && computer.score == 0
    puts "Choose a square: #{joinor(board.unmarked_keys)} "
    square = nil

    loop do
      square = gets.chomp.to_i
      break if board.unmarked_keys.include?(square)
      puts "Sorry, that's not a valid choice."
    end

    board[square] = human.marker
  end

  def joinor(arr)
    if arr.size == 1
      arr.first
    # elsif arr.size == 2
    #   "#{arr.first} and #{arr.last}"
    elsif arr.size > 0
      "#{arr[0...-1].join(', ')} or #{arr.last}"
    end
  end

  def computer_moves
    if winning_play?
      square = board.offensive_play(computer.marker)
    elsif immediate_threat?
      square = board.defensive_play(human.marker)
    elsif board[5].marker == Square::INITIAL_MARKER
      square = 5
    else
      square = board.unmarked_keys.sample
    end

    board[square] = computer.marker
  end

  def immediate_threat?
    !!board.defensive_play(human.marker)
  end

  def winning_play?
    !!board.offensive_play(computer.marker)
  end

  def display_score
    puts "Score: #{human.name} #{human.score} | #{computer.name} #{computer.score}"
  end

  def display_result
    clear_screen_and_display_board

    case board.winning_marker
    when human.marker
      puts "You won!"
      human.score += 1
    when computer.marker
      puts "Computer won!"
      computer.score += 1
    else
      puts "It's a tie."
    end
    display_score
  end

  def play_again?
    answer = nil
    loop do
      puts ""
      puts "Would you like to play again?"
      answer = gets.chomp.downcase
      break if %w(y n).include? answer
      puts "Sorry, must be y or n"
    end

    answer == 'y'
  end

  def clear_screen
    system 'clear'
  end

  def match_reset
    board.reset
    clear_screen
  end

  def game_reset
    match_reset
    score_reset
  end

  def score_reset
    human.score = 0
    computer.score = 0
  end

  def display_play_again_message
    puts "Let's play again!"
  end

  def game_winner?
    human.score >= WINNING_SCORE || computer.score >= WINNING_SCORE
  end

  def prompt_for_next_match
    puts "Press any key to play next match."
    gets
  end

  public

  def play
    clear_screen
    display_welcome_message

    loop do # game loop
      loop do # match loop
        display_board
        loop do
          current_player_moves
          break if board.match_winner? || board.full?
          clear_screen_and_display_board if human_turn?
        end

        display_result
        break if game_winner?
        prompt_for_next_match
        match_reset
      end
  
      break unless play_again?
      game_reset
      display_play_again_message
    end

    display_goodbye_message
  end
end

game = TTTGame.new
game.play
