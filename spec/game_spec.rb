require 'game.rb'

describe Game do
  before(:all) do
    @game = Game.new
    @grid = @game.grid
    @white = @game.white
    @black = @game.black

    @white.each {|piece| piece.move([99,99], @grid)}
    @black.each {|piece| piece.move([99,99], @grid)}
  end

  after(:each) do
    @white.each {|piece| piece.move([99,99], @grid)}
    @black.each {|piece| piece.move([99,99], @grid)}
  end

  context '#to_xy' do 
    it 'converts algebraic notation to x-y coordinates' do
      expect(@game.to_xy('a1')).to eql([0,0])
    end
  end

  context '#to_an' do
    it 'converts x-y coordinates to algebraic notation' do
      expect(@game.to_an([0,0])).to eql('a1')
    end
  end

  context '#under_attack?' do
    before(:each) do
      @white[0] = King.new('w',[0,0])
      @grid[@white[0].xy] = @white[0]
    end

    it 'detects when a pawn can attack' do
      @black[8] = Pawn.new('b',[1,1])
      @grid[@black[8].xy] = @black[8]

      expect(@game.under_attack?('w', @white[0].xy)).to be true
    end

    it 'detects when a queen can attack' do
      @black[1] = Queen.new('b',[0,7])
      @grid[@black[1].xy] = @black[1]

      expect(@game.under_attack?('w',@white[0].xy)).to be true
    end

    it 'detects when a king can attack' do
      @black[0] = King.new('b',[1,0])
      @grid[@black[0].xy] = @black[0]

      expect(@game.under_attack?('w',@white[0].xy)).to be true
    end

    it 'detects when a knight can attack' do
      @black[4] = Knight.new('b',[2,1])
      @grid[@black[4].xy] = @black[4]

      expect(@game.under_attack?('w',@white[0].xy)).to be true
    end
  end

  context '#stalemate?' do
    it 'detects a stalemate' do
      turn = 'w'
      @white[0] = King.new('w',[0,0])
      @black[0] = King.new('b',[0,2])
      @black[6] = Rook.new('b',[1,7])
      @grid[@white[0].xy] = @white[0]
      @grid[@black[0].xy] = @black[0]
      @grid[@black[6].xy] = @black[6]

      expect(@game.stalemate?(turn)).to be true
    end
  end

  context '#castle?' do
    before(:each) do
      @white[0] = King.new('w',[4,0])
      @white[6] = Rook.new('w',[0,0])
      @white[7] = Rook.new('w',[7,0])
      @black[0] = King.new('b',[4,7])
      [0,6,7].each {|p| @grid[@white[p].xy] = @white[p] }
      @grid[@black[0].xy] = @black[0]
    end

    it 'can castle' do
      expect(@game.castle?(@white[0].xy, [2,0])).to be true
      expect(@game.castle?(@white[0].xy, [6,0])).to be true
    end

    it 'cannot castle when in check' do
      @black[8] = Pawn.new('b',[5,1])
      @grid[@black[8].xy] = @black[8]

      expect(@game.castle?(@white[0].xy, [2,0])).to be false
    end

    it "cannot castle when king's path is blocked" do
      @white[1] = Queen.new('w',[3,0])
      @grid[@white[1].xy] = @white[1]

      expect(@game.castle?(@white[0].xy, [2,0])). to be false
    end

    it "cannot castle when king's path is under attack" do
      @black[8] = Pawn.new('b',[4,1])
      @grid[@black[8].xy] = @black[8]

      expect(@game.castle?(@white[0].xy, [2,0])).to be false
    end

    it 'cannot castle if it results in getting checked' do
      @black[8] = Pawn.new('b',[1,1])
      @grid[@black[8].xy] = @black[8]

      expect(@game.castle?(@white[0].xy, [2,0])).to be false
    end
  end

  context '#enpassant?' do
    before(:each) do
      @black[8] = Pawn.new('b',[0,6])
      @white[8] = Pawn.new('w',[1,1])
      @grid[@black[8].xy] = @black[8]
      @grid[@white[8].xy] = @white[8]
    end

    it 'can take en-passant' do
      @black[8].move([0,4], @grid)
      @white[8].move([1,4], @grid)

      expect(@game.enpassant?(@white[8].xy,[0,5])).to be true
    end
  end

  context '#promote' do
    it 'can promote' do
      xy = [0,7]
      promotion = 'Q'
      @white[8] = Pawn.new('w',xy)
      @grid[xy] = @white[8]      
      @game.promote(xy, promotion)

      expect(@white[8].class).to equal(Queen)
      expect(@grid[xy].class).to equal(Queen)
    end
  end

  context '#checkmate?' do
    before(:each) do
      @white[0] = King.new('w',[0,0])
      @black[0] = King.new('b',[7,7])
      @grid[@white[0].xy] = @white[0]
      @grid[@black[0].xy] = @black[0]
    end

    it 'detects checkmate' do
      @black[1] = Queen.new('b',[0,2])
      @black[6] = Rook.new('b', [2,0])
      [1,6].each {|p| @grid[@black[p].xy] = @black[p]}

      expect(@game.checkmate?('w')).to be true
    end

    it 'detects no checkmate when checking piece can be captured' do
      @white[8] = Pawn.new('w', [0,1])
      @white[9] = Pawn.new('w', [1,1])
      [8,9].each {|p| @grid[@white[p].xy] = @white[p] }
      @black[1] = Queen.new('b', [1,0])
      @grid[@black[1].xy] = @black[1]

      expect(@game.checkmate?('w')).to be false
    end

    it 'detects no checkmate when checking piece can be blocked' do
      @black[1] = Queen.new('b',[7,0])
      @grid[@black[1].xy] = @black[1]
      @white[6] = Rook.new('w', [6,1])
      @white[8] = Pawn.new('w', [0,1])
      @white[9] = Pawn.new('w', [1,1])
      [6,8,9].each {|p| @grid[@white[p].xy] = @white[p] }
    
      expect(@game.checkmate?('w')).to be false
    end
  end
end