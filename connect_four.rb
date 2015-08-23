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
      column = get_input('The value is invalid') { |val| val.to_i > 0 }.to_i
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

class Board
  def initialize(width, height)
    @width = width
    @height = height
    @grid = construct_grid(width, height)

    @DIR_DELTAS = {
      n: [0, -1],
      s: [0, 1],
      e: [1, 0],
      w: [-1, 0],
      ne: [1, -1],
      nw: [-1, -1],
      se: [1, 1],
      sw: [-1, 1]
    }

    @DIR_OPPOSITES = {
      n: :s,
      s: :n,
      e: :w,
      w: :e,
      ne: :sw,
      sw: :ne,
      nw: :se,
      se: :nw
    }
  end

  def draw
    @grid.each do |row|
      puts display_row(row)
    end
    puts column_numbers_string
  end

  # returns nil if there is no winner at the given position, or the string
  # representing the winning chip if there is
  def check_winner_at(x, y, num_to_win)
    chip = get_chip_at(x, y)
    # Find the end points of all sequences of chips containing the chip at (x, y)
    # Then check if any of them are a winning sequence
    end_points = find_end_points(x, y, chip)
    if end_points.any? { |point| winning_end_point?(point, num_to_win) }
      chip
    else
      nil
    end
  end

  def place_chip(column, chip)
    # Assumes that the column is not full
    # Columns input by the user begin at 1, but indexing begins at 0, so
    # subtract 1
    column_index = column - 1
    (@height - 1).downto(0) do |y|
      if empty?(column_index, y)
        set_chip_at(column_index, y, chip)
        return [column_index, y]
      end
    end
  end

  def column_full?(column)
    column_index = column - 1
    (@height - 1).downto(0) do |y|
      return false if empty?(column_index, y)
    end
    true
  end

  private

  def find_end_points(x, y, chip)
    end_points = @DIR_DELTAS.keys.map { |dir| end_point_in_direction(x, y, chip, dir) }
    end_points.uniq { |point| point.take(2) }
  end

  def end_point_in_direction(x, y, chip, dir)
    # TODO: Short circuit this to stop searching once it has reached the number
    # of chips in a row needed to win.
    check_x = x
    check_y = y
    loop do
      delta = @DIR_DELTAS[dir]
      opposite_dir = @DIR_OPPOSITES[dir]
      check_x += delta[0]
      check_y += delta[1]
      in_bounds = in_bounds?(check_x, check_y)
      if !in_bounds || empty?(check_x, check_y) || chip != get_chip_at(check_x, check_y)
        return [check_x - delta[0], check_y - delta[1], opposite_dir]
      end
    end
  end

  def winning_end_point?(point, num_to_win)
    x = point[0]
    y = point[1]
    dir = point[2]
    chip = get_chip_at(x, y)
    delta = @DIR_DELTAS[dir]
    count = 1
    1.upto(num_to_win - 1) do |i|
      check_x = x + (i * delta[0])
      check_y = y + (i * delta[1])
      if in_bounds?(check_x, check_y) && get_chip_at(check_x, check_y) == chip
        count += 1
      end
    end
    count == num_to_win
  end

  def in_bounds?(x, y)
    x.between?(0, @width - 1) && y.between?(0, @height - 1)
  end

  def empty?(x, y)
    get_chip_at(x, y).nil?
  end

  def get_chip_at(x, y)
    @grid[y][x]
  end

  def set_chip_at(x, y, chip)
    if empty?(x, y)
      set_chip_at!(x, y, chip)
    end
  end

  # Does not check that the position is empty
  def set_chip_at!(x, y, chip)
    @grid[y][x] = chip
  end

  # Converts an array of either 'x', 'o', or nil into a displayable string
  def display_row(row)
    # Replace nils with space
    no_nils = row.map do |chip|
      if chip.nil?
        # Columns are two characters wide to handle double-digit column
        # numbers
        "  "
      else
        " " + chip
      end
    end
    no_nils.join('|')
  end

  # The string representing the display of the column numbers
  def column_numbers_string
    normalize_widths = (1..@width).to_a.map do |num|
      # If the column number is 1 digit, put a space in front of it
      if num > 9
        num.to_s
      else
        " " + num.to_s
      end
    end
    normalize_widths.join('|')
  end

  def construct_grid(width, height)
    rows = []
    height.times do
      rows << Array.new(width)
    end
    rows
  end
end

Game.new.run
