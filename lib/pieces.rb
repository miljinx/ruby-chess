# @possible_moves:
#   -contains all the squares a piece can move to, *if there were no other pieces on the board*
#   -queen, bishop, and rook:
#     -sub arrays group moves by direction (i.e. paths)
#     -moves are ordered by distance traveled
#     -e.g. rook: [[one_square_right,two_squares_right,...],[one_square_left,...],...]
# #legal_move?:
#   -does not take into account castling or en-passant, separate methods will validate them

class Piece
  attr_reader :xy, :color, :history
  def initialize(color, xy)
    @color = color
    @xy = xy
    @history = [xy]
  end

  def move(xy, grid)
    @xy = xy
    @history << xy
    grid[xy] = self if (0..7) === xy[0] && (0..7) === xy[1]
    grid[@history[-2]] = nil
  end

  def undo_move(grid)
    grid[@xy] = nil if (0..7) === xy[0] && (0..7) === xy[1]
    @history.pop
    @xy = @history[-1]
    grid[@xy] = self
  end

  def legal_move?(xy, grid, enemy, ally)
    if grid[xy]
      return false if grid[xy].color == @color
    end
  end
end

class King < Piece
  attr_reader :possible_moves
  def initialize (color, xy)
    super(color, xy)
    @possible_moves = King.moveset(xy)
  end

  def move(xy, grid)
    super(xy, grid)
    @possible_moves = King.moveset(xy)
  end

  def undo_move(grid)
    super(grid)
    @possible_moves = King.moveset(xy)
  end

  def self.moveset(coord)
    moveset = []
    (-1..1).each do |dx|
      (-1..1).each do |dy|
        x = coord[0] + dx
        y = coord[1] + dy
        if ((0..7) === x) && ((0..7) === y) && !(dx == 0 && dy == 0)
          moveset << [x,y]
        end
      end
    end
    return moveset
  end

  def legal_move?(xy, grid, enemy, ally)
    return false if super(xy, grid, enemy, ally) == false
    
    if @possible_moves.include?(xy)
      # check if square can be attacked (excluding enemy king and pawns)
      enemy[1..7].each do |piece|
        # ally and enemy params reversed for enemy piece's point of view
        return false if piece.legal_move?(xy, grid, ally, enemy)
      end

      # check if square can be attacked by king
      return false if enemy[0].possible_moves.include?(xy)

      # check if square can be attacked by pawn
      x, y = xy[0], xy[1]
      [1,-1].each do |dx|
        if @color == 'w'
          piece = grid[[x+dx,y+1]]
          if piece.class == Pawn
            return false if piece.color == 'b'
          end
        else
          piece = grid[[x+dx,y-1]]
          if piece.class == Pawn
            return false if piece.color == 'w'
          end
        end
      end

      return true
    else
      return false
    end
  end

  def no_legal_moves?(grid, enemy, ally)
    @possible_moves.each do |xy|
      return false if legal_move?(xy, grid, enemy, ally)
    end
    return true
  end
end

class Queen < Piece
  attr_reader :possible_moves
  def initialize (color, xy)
    super(color, xy)
    @possible_moves = Queen.moveset(xy)
  end

  def move(xy, grid)
    super(xy, grid)
    @possible_moves = Queen.moveset(xy)
  end

  def undo_move(grid)
    super(grid)
    @possible_moves = Queen.moveset(xy)
  end

  def self.moveset(coord)
    moveset = []
    8.times { moveset << [] }

    (1..7).each do |d|
      # x+ y+
      x = coord[0] + d
      y = coord[1] + d
      moveset[0] << [x,y] if ((0..7) === x) && ((0..7) === y)

      # x- y-
      x = coord[0] - d
      y = coord[1] - d
      moveset[1] << [x,y] if ((0..7) === x) && ((0..7) === y)

      # x- y+
      x = coord[0] - d
      y = coord[1] + d
      moveset[2] << [x,y] if ((0..7) === x) && ((0..7) === y)

      # x+ y-
      x = coord[0] + d
      y = coord[1] - d
      moveset[3] << [x,y] if ((0..7) === x) && ((0..7) === y)

      # x+
      x = coord[0] + d
      y = coord[1]
      moveset[4] << [x,y] if ((0..7) === x) && ((0..7) === y)

      # x-
      x = coord[0] - d
      moveset[5] << [x,y] if ((0..7) === x) && ((0..7) === y)

      # y+
      x = coord[0]
      y = coord[1] + d
      moveset[6] << [x,y] if ((0..7) === x) && ((0..7) === y)

      # y-
      y = coord[1] - d
      moveset[7] << [x,y] if ((0..7) === x) && ((0..7) === y)
    end
    return moveset
  end

  def legal_move?(xy, grid, enemy, ally)
    return false if super(xy, grid, enemy, ally) == false

    @possible_moves.each do |path|
      if path.include?(xy)
        # Trace the path of the move
        # Illegal if path is obstructed
        path.each do |cell|
          return true if cell == xy
          return false if grid[cell]
        end
      end
    end
    return false
  end
end

class Bishop < Piece
  attr_reader :possible_moves
  def initialize (color, xy)
    super(color, xy)
    @possible_moves = Bishop.moveset(xy)
  end

  def move(xy, grid)
    super(xy, grid)
    @possible_moves = Bishop.moveset(xy)
  end

  def undo_move(grid)
    super(grid)
    @possible_moves = Bishop.moveset(xy)
  end

  def self.moveset(coord)
    moveset = []
    4.times {moveset << []}

    (1..7).each do |d|
      # x+ y+
      x = coord[0] + d
      y = coord[1] + d
      moveset[0] << [x,y] if ((0..7) === x) && ((0..7) === y)

      # x- y-
      x = coord[0] - d
      y = coord[1] - d
      moveset[1] << [x,y] if ((0..7) === x) && ((0..7) === y)

      # x- y+
      x = coord[0] - d
      y = coord[1] + d
      moveset[2] << [x,y] if ((0..7) === x) && ((0..7) === y)

      # x+ y-
      x = coord[0] + d
      y = coord[1] - d
      moveset[3] << [x,y] if ((0..7) === x) && ((0..7) === y)
    end
    return moveset
  end

  def legal_move?(xy, grid, enemy, ally)
    return false if super(xy, grid, enemy, ally) == false

    @possible_moves.each do |path|
      if path.include?(xy)
        path.each do |cell|
          return true if cell == xy
          return false if grid[cell]
        end
      end
    end
    return false   
  end
end

class Knight < Piece
  attr_reader :possible_moves
  def initialize (color, xy)
    super(color, xy)
    @possible_moves = Knight.moveset(xy)
  end

  def move(xy, grid)
    super(xy, grid)
    @possible_moves = Knight.moveset(xy)
  end

  def undo_move(grid)
    super(grid)
    @possible_moves = Knight.moveset(xy)
  end

  def self.moveset(coord)
    moveset = []
    (-2..2).each do |dx|
      (-2..2).each do |dy|
        x = coord[0] + dx
        y = coord[1] + dy
        if ((0..7) === x) && ((0..7) === y)
          if dx.abs != dy.abs && dx != 0 && dy != 0
            moveset << [x,y]
          end
        end
      end
    end
    return moveset
  end          

  def legal_move?(xy, grid, enemy, ally)
    return false if super(xy, grid, enemy, ally) == false

    @possible_moves.include?(xy) ? (return true) : (return false)    
  end
end

class Rook < Piece
  attr_reader :possible_moves
  def initialize (color, xy)
    super(color, xy)
    @possible_moves = Rook.moveset(xy)
  end

  def move(xy, grid)
    super(xy, grid)
    @possible_moves = Rook.moveset(xy)
  end

  def undo_move(grid)
    super(grid)
    @possible_moves = Rook.moveset(xy)
  end

  def self.moveset(coord)
    moveset = []
    4.times {moveset << []}

    (1..7).each do |d|
      # x+
      x = coord[0] + d
      y = coord[1]
      moveset[0] << [x,y] if ((0..7) === x) && ((0..7) === y)

      # x-
      x = coord[0] - d
      moveset[1] << [x,y] if ((0..7) === x) && ((0..7) === y)

      # y+
      x = coord[0]
      y = coord[1] + d
      moveset[2] << [x,y] if ((0..7) === x) && ((0..7) === y)

      # y-
      y = coord[1] - d
      moveset[3] << [x,y] if ((0..7) === x) && ((0..7) === y)
    end
    return moveset
  end

  def legal_move?(xy, grid, enemy, ally)
    return false if super(xy, grid, enemy, ally) == false

    @possible_moves.each do |path|
      if path.include?(xy)
        path.each do |cell|
          return true if cell == xy
          return false if grid[cell]
        end
      end
    end
    return false
  end
end

class Pawn < Piece
  attr_reader :possible_moves
  def initialize (color, xy)
    super(color, xy)
    @possible_moves = Pawn.moveset(xy, color, true)
  end

  def move(xy, grid)
    super(xy, grid)
    @possible_moves = Pawn.moveset(xy, @color)
  end

  def undo_move(grid)
    super(grid)
    @possible_moves = Pawn.moveset(xy, @color)
  end

  def self.moveset(coord, color, first_move = false)
    moveset = []
    x, y = coord[0], coord[1]
    if color == 'w'
      moveset << [x,  y+2] if first_move
      moveset << [x,  y+1] if (0..7) === (y+1) && (0..7) === (y+1)
      moveset << [x+1,y+1] if (0..7) === (x+1) && (0..7) === (y+1)
      moveset << [x-1,y+1] if (0..7) === (x-1) && (0..7) === (y-1)
    end
    if color == 'b'
      moveset << [x,  y-2] if first_move
      moveset << [x,  y-1] if (0..7) === (y-1) && (0..7) === (y-1)
      moveset << [x+1,y-1] if (0..7) === (x+1) && (0..7) === (y-1)
      moveset << [x-1,y-1] if (0..7) === (x-1) && (0..7) === (y-1)
    end
    return moveset
  end

  def legal_move?(xy, grid, enemy, ally)
    return false if super(xy, grid, enemy, ally) == false

    if @possible_moves.include?(xy)
      if @xy[0] == xy[0] # Forward movement
        grid[xy] ? (return false) : (return true)
      else # Capture movement
        grid[xy] ? (return true) : (return false)
      end
    else
      return false
    end
  end
end