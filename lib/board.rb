# Uses x-y coordinates, the conversion to algebraic notation is: a1 <-> [0,0]
# @white & @black:
#   -array of Piece objects
#   -used to easily manipulate the objects (as opposed to 32 instance vars)
#   -index to piece table:
#      index: 0 | 1 | 2  3 | 4  5 | 6  7 | 8  9 10 11 12 13 14 15
#      piece: K | Q | B  B | N  N | R  R | P  P  P  P  P  P  P  P
#   -promotion changes the object, but not the index
# @grid:
#   -each key is a square; value is the occupying Piece object (or nil if none)
#   -used to analyze interactions between pieces (e.g. capture, castling, check)
# captured pieces:
#   -captured piece is "moved" to [99,99], i.e. not on grid and empty @possible_moves
#   -attacker takes captor's old spot in @grid


require './lib/pieces.rb'

class Board
  attr_accessor :grid, :white, :black
  def initialize
    @white = []
    @white << King.new('w',[4,0])
    @white << Queen.new('w',[3,0])
    @white << Bishop.new('w',[2,0])
    @white << Bishop.new('w',[5,0])
    @white << Knight.new('w',[1,0])
    @white << Knight.new('w',[6,0])
    @white << Rook.new('w',[0,0])
    @white << Rook.new('w',[7,0])
    (0..7).each { |x| @white << Pawn.new('w',[x,1]) }

    @black = []
    @black << King.new('b',[4,7])
    @black << Queen.new('b',[3,7])
    @black << Bishop.new('b',[2,7])
    @black << Bishop.new('b',[5,7])
    @black << Knight.new('b',[1,7])
    @black << Knight.new('b',[6,7])
    @black << Rook.new('b',[0,7])
    @black << Rook.new('b',[7,7])
    (0..7).each { |x| @black << Pawn.new('b',[x,6]) }

    @grid = {}
    (0..7).each do |x|
      (0..7).each do |y|
        @grid.store([x,y],nil)
      end
    end

    @white.each { |piece| @grid[piece.xy] = piece }
    @black.each { |piece| @grid[piece.xy] = piece }
  end

  def draw
    puts ""
    puts  "    a   b   c   d   e   f   g   h"
    puts  "  +---+---+---+---+---+---+---+---+"
    (0..7).reverse_each do |y|
      print "#{y+1} |"
      (0..7).each do |x|
        piece = @grid[[x,y]]
        case piece
        when King
          piece.color == 'w' ? (print " K |") : (print "`K |")
        when Queen
          piece.color == 'w' ? (print " Q |") : (print "`Q |")
        when Bishop
          piece.color == 'w' ? (print " B |") : (print "`B |")
        when Knight
          piece.color == 'w' ? (print " N |") : (print "`N |")
        when Rook
          piece.color == 'w' ? (print " R |") : (print "`R |")
        when Pawn
          piece.color == 'w' ? (print " P |") : (print "`P |")
        else
          print "   |"
        end
      end
      print " #{y+1}"
      print "\n  +---+---+---+---+---+---+---+---+\n"
    end
    puts  "    a   b   c   d   e   f   g   h"
    puts ""
  end
end

# board = Board.new.draw
