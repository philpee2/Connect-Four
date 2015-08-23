require './board'
require 'colorize'

# Continually ask the user for a value, until one is entered which returns
# true for the passed in validator block
def get_input(invalid_message, &validator)
  value = nil
  loop do
    value = gets.chomp
    if validator.call(value)
      return value
    else
      puts invalid_message
    end
  end
end

class Game
  def initialize
    width_and_height = get_width_and_height
    @width = width_and_height[0]
    @height = width_and_height[1]
    puts 'How many chips in a row to win?'
    @num_to_win = get_input('The value is invalid') { |val| val.to_i > 1 }.to_i
    @board = Board.new(@width, @height)
    @current_player = 'x'
    @num_turns = 0
    @board.draw
  end

  def run
    until game_over?
      play_turn
      switch_turns
    end
    if board_full?
      puts "It's a tie!"
    else
      puts "#{@winner} wins!"
    end
  end

  private

  def play_turn
    column = get_column
    placed = @board.place_chip(column, @current_player)
    @num_turns += 1
    # Check if the newly placed piece is a winning move
    @winner = @board.check_winner_at(placed[0], placed[1], @num_to_win)
    @board.draw
  end

  def get_column
    column = nil
    loop do
      puts "Player #{@current_player}, choose a column"
      column = get_input('The value is invalid') do |val|
        val.to_i.between?(1, @width)
      end.to_i
      if @board.column_full?(column)
        puts "That column is full"
      else
        break
      end
    end
    column
  end

  def get_width_and_height
    puts "Enter the width of the board"
    width = get_input('The value is invalid') { |val| val.to_i > 1 }.to_i
    puts "Enter the height of the board"
    height = get_input('The value is invalid') { |val| val.to_i > 1 }.to_i
    [width, height]
  end

  def game_over?
    !@winner.nil? || board_full?
  end

  def board_full?
    @num_turns == @width * @height
  end

  def switch_turns
    if @current_player == 'x'
      @current_player = 'o'
    else
      @current_player = 'x'
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  Game.new.run
end

