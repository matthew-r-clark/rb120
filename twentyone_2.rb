# second attempt after reorganizing design
# started by creating one class at a time and testing
# each method. waited until the end to create the
# TwentyOneGame class.

# ==== Known Bugs: ====
# -
# =====================

module Hand
  def hand_value
    total = 0
    hand.each do |card|
      total += card.value
    end

    total = adjust_for_aces(total)

    total
  end

  def adjust_for_aces(total)
    if (total > 21) && !hand.select { |card| card.type == 'Ace' }.empty?
      num_aces = hand.select { |card| card.type == 'Ace' }.size
      num_aces.times do
        total -= 10
        break unless total > 21
      end
    end

    total
  end

  def busted?
    hand_value > 21
  end

  def show_hand
    puts "=== #{name}'s hand: ==="
    puts hand
    output = "Total: #{hand_value}"
    output += ", Busted!" if busted?
    puts output
    puts ""
  end

  def reset_hand
    @hand = []
  end
end

class Card
  attr_reader :type, :suit, :value

  def initialize(type, suit, value)
    @type = type
    @suit = suit
    @value = value
  end

  private

  def to_s
    "#{type} of #{suit}"
  end
end

class Deck
  TYPES = %w(2 3 4 5 6 7 8 9 10 Jack Queen King Ace)
  SUITS = %w(Diamonds Clubs Hearts Spades)
  VALUES = { 'Jack' => 10, 'Queen' => 10, 'King' => 10, 'Ace' => 11 }
  attr_reader :first_use, :cards

  def initialize
    @first_use = true
    @cards = []
    reset_and_shuffle
  end

  def deal_card
    reset_and_shuffle if empty?
    cards.pop
  end

  private

  def reset_and_shuffle
    reset
    shuffle_cards
    @first_use = false
  end

  def reset
    SUITS.each do |suit|
      TYPES.each do |type|
        @cards << Card.new(type, suit, card_value(type))
      end
    end
  end

  def shuffle_cards
    if !first_use
      puts "Shuffling cards..."
      sleep 2
      system 'clear'
    end
    cards.shuffle!
  end

  def card_value(type)
    VALUES.keys.include?(type) ? VALUES[type] : type.to_i
  end

  def empty?
    cards.empty?
  end

  # def remove(num) # for testing
  #   cards.pop(num)
  # end
end

class Participant
  include Hand

  attr_reader :name, :hand
  def initialize
    @name = set_name
    @hand = []
  end
end

class Dealer < Participant
  NAMES = %w(R2D2 Hal Chappie Sonny C3P0)

  def show_hand_blind
    puts "=== #{name}'s hand: ==="
    puts hand.first
    (hand.size - 1).times do
      puts "[facedown card]"
    end
    puts ""
  end

  def hit?
    hand_value < 17
  end

  private

  def set_name
    @name = NAMES.sample
  end
end

class Player < Participant
  attr_reader :cash, :wager

  def initialize
    super
    @cash = set_cash
    @starting_cash = @cash
    @wager = 0
  end

  def place_bet(amount)
    @wager = amount
  end

  def resolve_win
    @cash += wager
    @wager = 0
  end

  def resolve_loss
    @cash -= wager
    @wager = 0
  end

  def broke?
    cash == 0
  end

  def winnings_vs_starting_cash
    if cash > @starting_cash
      :profit
    elsif cash == @starting_cash
      :break_even
    elsif cash > 0
      :partial_loss
    else
      :total_loss
    end
  end

  private

  def set_cash
    puts "#{name}, how much cash do you have?"
    answer = nil
    loop do
      answer = gets.chomp.to_i
      break if answer > 0
      puts "I know you have money. Really, how much do you have?"
    end
    answer
  end

  def set_name
    puts "What is your name?"
    @name = gets.chomp.capitalize
  end
end

class TwentyOneGame
  attr_reader :player, :dealer, :deck

  def initialize
    @player = Player.new
    @dealer = Dealer.new
    @deck = Deck.new
  end

  def clear_screen
    system 'clear'
  end

  def pause_game_for(seconds)
    sleep seconds
  end

  def display_welcome
    puts "Welcome to Twenty-One, #{player.name}!"
    puts "#{dealer.name} will be your dealer."
    puts ""
    print "Press enter to start..."
    gets
  end

  def deal_cards
    reset_hands
    clear_screen
    puts "Dealing cards..."
    pause_game_for(2)
    2.times do
      dealer.hand << deck.deal_card
      player.hand << deck.deal_card
    end
  end

  def reset_hands
    dealer.reset_hand
    player.reset_hand
  end

  def display_hands
    clear_screen
    dealer.show_hand_blind
    player.show_hand
  end

  def prompt_player_for_bet
    # assignments: 4, method_calls: 11, conditions: 3
    puts ["#{player.name}, you have $#{player.cash}.",
          "How much would you like to bet?"]
    answer = nil
    loop do
      answer = gets.chomp.to_i
      break if answer > 0
      output = "Please enter an amount greater than 0." if answer <= 0
      output = "Please enter an amount you can afford." if answer > player.cash
      puts output
    end
    player.place_bet(answer)
  end

  def player_turn
    loop do
      puts "#{player.name}, would you like to hit or stay?"

      answer = nil
      loop do
        answer = gets.chomp.downcase[0]
        break if %w(h s).include?(answer)
        puts "Please enter 'hit' or 'stay'"
      end

      if answer == 'h'
        puts "#{player.name} decided to hit!"
        player.hand << deck.deal_card
        display_hands
      else
        puts "#{player.name} decided to stay!"
      end

      break if answer == 's'

      puts "#{player.name} busted!" if player.busted?
      break if player.busted?
    end
  end

  def dealer_turn
    loop do
      puts "#{dealer.name} is thinking..."
      pause_game_for(2)
      if dealer.hit?
        dealer.hand << deck.deal_card
        display_hands
        puts "#{dealer.name} decided to hit!"
      else
        puts "#{dealer.name} decided to stay!"
        break
      end
    end
  end

  def display_winner
    if dealer_won?
      puts "#{dealer.name} wins!"
    else
      puts "#{player.name} wins!"
    end
  end

  def display_full_hands
    puts "Determining winner..." unless player.busted?
    pause_game_for(3)
    clear_screen
    dealer.show_hand
    player.show_hand
  end

  def resolve_bet
    if player_won?
      player.resolve_win
    else
      player.resolve_loss
    end
  end

  def dealer_won?
    player.busted? ||
      (player.hand_value <= dealer.hand_value && !dealer.busted?)
  end

  def player_won?
    !dealer_won?
  end

  def display_goodbye
    clear_screen unless player.broke?
    case player.winnings_vs_starting_cash
    when :profit
      puts "Great job! You are leaving with $#{player.cash}."
    when :break_even
      puts "You broke even! You still have $#{player.cash}."
    when :partial_loss
      puts "You are leaving with $#{player.cash}."
    when :total_loss
      puts "You ran out of cash."
    end
    puts ""
    puts "Thank you for playing, #{player.name}!"
  end

  def quit_playing?
    puts "#{player.name}, would you like to continue playing?"
    answer = nil
    loop do
      answer = gets.chomp.downcase[0]
      break if %w(y n).include?(answer)
      puts "Please type 'y' or 'n'."
    end
    answer == 'n'
  end

  def start
    # deck.remove(50) # for testing
    clear_screen
    display_welcome
    loop do
      deal_cards
      display_hands
      prompt_player_for_bet
      player_turn
      dealer_turn unless player.busted?
      display_full_hands
      display_winner
      resolve_bet
      break if player.broke? || quit_playing?
    end
    display_goodbye
  end
end

system 'clear'
TwentyOneGame.new.start
