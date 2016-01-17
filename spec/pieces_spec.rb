require 'pieces.rb'
require 'board.rb'

describe Piece do
  before(:all) do
    board = Board.new
    @grid = board.grid
    @white = board.white
    @black = board.black

    @white.each {|piece| piece.move([99,99], @grid)}
    @black.each {|piece| piece.move([99,99], @grid)}
  end

  after(:each) do
    @white.each {|piece| piece.move([99,99], @grid)}
    @black.each {|piece| piece.move([99,99], @grid)}
  end

  context '#legal_move?' do
    before(:all) do
      @white[0] = King.new('w',[0,0])
      @white[1] = Queen.new('w',[0,1])
      @white[0..1].each {|p| @grid[p.xy] = p}
    end

    it 'cannot move to a square occupied by an ally piece' do
      expect(@white[0].legal_move?(@white[1].xy, @grid, @black, @white)).to be false
    end
  end

  describe King do
    context '#legal_move?' do
      before(:each) do
        @king = King.new('w',[3,3])
        @white[0] = @king
        @grid[@king.xy] = @king
      end

      it 'can move on an empty board' do
        @king.possible_moves.each do |xy|
          expect(@king.legal_move?(xy, @grid, @black, @white)).to be true
        end
      end

      it 'cannot move to a square under attack' do
        @black[1] = Queen.new( 'b',[2,1]) # attacks [2,3],[4,3]
        @black[4] = Knight.new('b',[6,5]) # attacks [4,4]
        @black[8] = Pawn.new(  'b',[1,5]) # attacks [2,4]
        [1,4,8].each {|i| @grid[@black[i].xy] = @black[i]}

        [[2,3],[4,3],[4,4],[2,4]].each do |xy|
          expect(@king.legal_move?(xy, @grid, @black, @white)).to be false
        end
      end
    end

    context '#no_legal_moves?' do
      before(:each) do
        @king = King.new('w',[0,0])
        @white[0] = @king
        @grid[@king.xy] = @king
      end

      it 'knows when it cannot move' do
        @black[6] = Rook.new('b',[1,7])        
        @white[8] = Pawn.new('w',[0,1])
        @grid[@black[6].xy] = @black[6]
        @grid[@white[8].xy] = @white[8]

        expect(@king.no_legal_moves?(@grid, @black, @white)).to be true
      end
    end
  end

  describe Queen do
    context '#legal_move?' do
      before(:each) do
        @queen = Queen.new('w',[4,4])
        @white[1] = @queen
        @grid[@queen.xy] = @queen
      end

      it 'can move on an empty board' do
        @queen.possible_moves.each do |path|
          path.each do |xy|
            expect(@queen.legal_move?(xy, @grid, @black, @white)).to be true
          end
        end
      end

      it 'is obstructed by other pieces' do
        @black[8]  = Pawn.new('b',[5,4]) # right
        @black[9]  = Pawn.new('b',[3,4]) # left
        @black[10] = Pawn.new('b',[4,5]) # top
        @black[11] = Pawn.new('b',[4,3]) # bottom
        @black[12] = Pawn.new('b',[5,5]) # top-right
        @black[13] = Pawn.new('b',[5,3]) # bottom-right
        @black[14] = Pawn.new('b',[3,5]) # top-left
        @black[15] = Pawn.new('b',[3,3]) # bottom-left
        @black[8..15].each {|p| @grid[p.xy] = p}

        [[7,4],[0,4],[4,7],[4,0],[7,7],[7,0],[0,7],[0,0]].each do |xy|
          expect(@queen.legal_move?(xy, @grid, @black, @white)).to be false
        end
      end
    end
  end

  describe Bishop do
    context '#legal_move?' do
      before(:each) do
        @bishop = Bishop.new('w',[4,4])
        @white[3] = @bishop
        @grid[@bishop.xy] = @bishop
      end

      it 'can move on an empty board' do
        @bishop.possible_moves.each do |path|
          path.each do |xy|
            expect(@bishop.legal_move?(xy, @grid, @black, @white)).to be true
          end
        end
      end

      it 'is obstructed by other pieces' do
        @black[8]  = Pawn.new('b',[5,5]) # top-right
        @black[9]  = Pawn.new('b',[5,3]) # bottom-right
        @black[10] = Pawn.new('b',[3,5]) # top-left
        @black[11] = Pawn.new('b',[3,3]) # bottom-left0
        @black[8..11].each {|p| @grid[p.xy] = p}

        [[7,7],[7,0],[0,7],[0,0]].each do |xy|
          expect(@bishop.legal_move?(xy, @grid, @black, @white)).to be false
        end
      end
    end
  end

  describe Knight do
    context '#legal_move?' do
      before(:each) do
        @knight = Knight.new('w',[4,4])
        @white[4] = @knight
        @grid[@knight.xy] = @knight
      end

      it 'can move on an empty board' do
        @knight.possible_moves.each do |xy|
          expect(@knight.legal_move?(xy, @grid, @black, @white)).to be true
        end
      end
    end
  end

  describe Rook do
    context '#legal_move?' do
      before(:each) do
        @rook = Rook.new('w',[4,4])
        @white[6] = @rook
        @grid[@rook.xy] = @rook
      end

      it 'can move on an empty board' do
        @rook.possible_moves.each do |path|
          path.each do |xy|
            expect(@rook.legal_move?(xy, @grid, @black, @white)).to be true
          end
        end
      end

      it 'is obstructed by other pieces' do
        @black[8]  = Pawn.new('b',[5,4]) # right
        @black[9]  = Pawn.new('b',[3,4]) # left
        @black[10] = Pawn.new('b',[4,5]) # top
        @black[11] = Pawn.new('b',[4,3]) # bottom
        @black[8..11].each {|p| @grid[p.xy] = p}

        [[7,4],[0,4],[4,7],[4,0]].each do |xy|
          expect(@rook.legal_move?(xy, @grid, @black, @white)).to be false
        end
      end
    end
  end

  describe Pawn do
    context '#legal_move?' do
      before(:each) do
        @pawn = Pawn.new('w',[1,1])
        @white[8] = @pawn
        @grid[@pawn.xy] = @pawn
      end

      it 'can move on an empty board' do
        # capture movements require enemy pieces
        @pawn.possible_moves[0,1].each do |xy|
          expect(@pawn.legal_move?(xy, @grid, @black, @white)).to be true
        end
      end

      it 'can move diagonally for captures only' do
        @black[8] = Pawn.new('b',[2,2])
        @grid[@black[8].xy] = @black[8]

        expect(@pawn.legal_move?([2,2], @grid, @black, @white)).to be true
        expect(@pawn.legal_move?([0,2], @grid, @black, @white)).to be false
      end
    end
  end
end