require './lib/board.rb'
require 'yaml'

class Game
  # getter/setters for testing purposes
  attr_accessor :board, :white, :black, :grid, :record
  def initialize
    @board = Board.new
    @white = @board.white
    @black = @board.black
    @grid = @board.grid
  end

  def begin
    print "\n\n"
    puts '    **********************'
    puts '    * Command Line Chess *'
    puts '    **********************'
    puts ''
    puts '    Tips:'
    puts '      - To move a piece, enter its location and destination, e.g. "a2 a4".'
    puts '      - Black pieces on the board are indicated by backticks.'
    puts '      - Move the King piece when castling.'
    puts '      - Can type the following options instead of moving: '
    puts '        - "resign"'
    puts '        - "restart"'
    puts '        - "save"'
    puts '        - "exit"'
    puts ''

    loop do
      print 'Would you like to start a (N)ew game or (L)oad an old one?: '
      mode = gets.chomp.upcase
      case mode
      when 'N'
        play('w')
        break
      when 'L'
        if File.exist?('save.txt')
          load
        else
          puts 'No save file found. Starting a new game.'
          play('w')
        end
        break
      else
        puts 'Invalid option, try again.'
      end
    end
  end

  def play(color, load_can_enpassant = ['w', false])
    @board.draw
    turn = color
    can_enpassant = load_can_enpassant
    loop do
      if stalemate?(turn)
        puts "Stalemate. The game is a draw."
        return nil
      end

      piece, target, special = prompt(turn, can_enpassant[1]);

      case special
      when 'castle'
        piece.move(target, @grid)
        if turn == 'w'
          if target == [2,0]
            @white[6].move([3,0], @grid)
          else
            @white[7].move([5,0], @grid)
          end
        else
          if target == [2,7]
            @black[6].move([3,7], @grid)
          else
            @black[7].move([5,7], @grid)
          end
        end
        turn == 'w' ? (puts 'White castles.') : (puts 'Black castles.')

      when 'enpassant'
        piece.move(target, @grid)
        x, y = target
        if turn == 'w'
          captor = @grid[[x,y-1]]
          captor.move([99,99], @grid)
        else
          captor = @grid[[x,y+1]]
          captor.move([99,99], @grid)
        end
        turn == 'w' ? (puts 'White captures.') : (puts 'Black captures.')

      when 'doublestep'
        piece.move(target, @grid)
        can_enpassant = [turn, true]

      when 'promotion'
        piece.move(target, @grid)
        promote_prompt(target)

      when 'resign'
        turn == 'w' ? (puts 'White resigns. Black wins.') : (puts 'Black resigns. White wins.')
        return nil

      when 'restart'
        puts 'Restarting the game.'
        initialize
        play('w')
        return nil

      when 'save'
        File.open('save.txt','w') do |save|
          save.puts turn
          save.puts "#{can_enpassant[0]} #{can_enpassant[1]}"
          save.puts YAML::dump(@board)
        end
        next

      when 'exit'
        return nil

      else        
        # move to occupied square, i.e. a capture
        if (captor = @grid[target])
          if captor.color == 'b'
            captor.move([99,99], @grid)
            piece.move(target, @grid)
          else
            @white[@white.index(captor)] = nil
            piece.move(target, @grid)
          end
          turn == 'w' ? (puts 'White captures.') : (puts 'Black captures.')
        # move to unoccupied square
        else
          piece.move(target, @grid)
        end
      end

      (can_enpassant[1] = false) if turn != can_enpassant[0]

      if turn == 'w'
        if check?('b')
          if checkmate?('b')
            puts "Black has been mated. White wins."
            @board.draw
            return nil
          end
          puts "Black is in check."
        end
      else
        if check?('w')
          if checkmate?('w')
            puts "White has been mated. Black wins."
            @board.draw
            return nil
          end
          puts "White is in check."
        end
      end

      turn = (turn == 'w' ? 'b' : 'w')

      @board.draw
    end
  end

  def load
    save = File.open('save.txt','r')

    turn = save.gets.chomp
    load_can_enpassant = save.gets.chomp.split
    load_can_enpassant[1] == 'true' ? (load_can_enpassant[1] = true) : (load_can_enpassant[1] = false)
    @board = YAML::load(save.read)
    @white = @board.white
    @black = @board.black
    @grid = @board.grid

    play(turn, load_can_enpassant)

    save.close
  end

  def to_xy(string)
    x, y = string.split(//)
    x = x.bytes[0] - 97
    y = y.to_i - 1
    if (0..7) === x && (0..7) === y
      return [x,y]
    else
      return nil
    end
  end

  def to_an(xy)
    alpha, num = xy
    alpha = (alpha + 97).chr
    num = "#{num + 1}"
    return (alpha + num)
  end

  def prompt(turn, can_enpassant)
    loop do
      print "White's move: " if turn == 'w'
      print "Black's move: " if turn == 'b'
      move = gets.chomp.downcase

      if move =~ /[a-h]\d\s[a-h]\d/
        a = to_xy(move.split[0])
        b = to_xy(move.split[1])
        piece = @grid[a];

        unless piece && piece.color == turn
          puts 'Illegal move, try again.'
          next
        end
        # white's turn
        if turn == 'w'
          return [piece, b, 'castle'] if castle?(a, b)
          if can_enpassant
            return [piece, b, 'enpassant'] if enpassant?(a, b)
          end

          if piece.legal_move?(b, @grid, @black, @white)
            if checks_self?(a, b)
              puts 'Illegal move, try again'
              next
            end
            if Pawn === piece
              return [piece, b, 'doublestep'] if piece.history.length == 1 && b[1] == (a[1] + 2)
              return [piece, b, 'promotion'] if b[1] == 7
              return [piece, b, nil]
            else
              return [piece, b, nil]
            end
          else
            puts 'Illegal move, try again.'
          end
        # black's turn
        else
          return [piece, b, 'castle'] if castle?(a, b)
          if can_enpassant
            return [piece, b, 'enpassant'] if enpassant?(a, b)
          end
          if piece.legal_move?(b, @grid, @white, @black)
            if checks_self?(a, b)
              puts 'Illegal move, try again'
              next
            end
            if Pawn === piece
              return [piece, b, 'doublestep'] if piece.history.length == 1 && b[1] == (a[1] - 2)
              return [piece, b, 'promotion'] if b[1] == 0
              return [piece, b, nil]
            else
              return [piece, b, nil]
            end
          else
            puts 'Illegal move, try again.'
          end
        end
      elsif move == 'resign'
        return [nil, nil, 'resign']
      elsif move == 'restart'
        return [nil, nil, 'restart']        
      elsif move == 'save'
        return [nil, nil, 'save']
      elsif move == 'exit'
        return [nil, nil, 'exit']
      else
        puts 'Illegal move, try again.'
        next
      end
    end
  end

  # checks a square that may or may not be empty
  # color arg is the one under attack
  def under_attack?(color, xy)
    x, y = xy
    if color == 'w'
      @black.each do |piece|
        return true if piece.legal_move?(xy, @grid, @white, @black)
      end
      # pawn attacks
      pawn = @grid[[x+1,y+1]]
      return true if Pawn === pawn && pawn.color == 'b'
      pawn = @grid[[x-1,y+1]]
      return true if Pawn === pawn && pawn.color == 'b'
    else
      @white.each do |piece|
        return true if piece.legal_move?(xy, @grid, @black, @white)
      end
      pawn = @grid[[x+1,y-1]]
      return true if Pawn === pawn && pawn.color == 'w'
      pawn = @grid[[x-1,y-1]]
      return true if Pawn === pawn && pawn.color == 'w'
    end
    return false
  end

  def stalemate?(turn)
    if turn == 'w'
      @white[1..-1].each {|p| return false if p.xy != [99,99]}
      if @white[0].no_legal_moves?(@grid, @black, @white)
        return true
      else
        return false
      end
    else
      @black[1..-1].each {|p| return false if p.xy != [99,99]}
      if @black[0].no_legal_moves?(@grid, @white, @black)
        return true
      else
        return false
      end
    end
  end

  def castle?(a, b)
    piece = @grid[a]

    return false unless King === piece
    return false if piece.history.length > 1

    # if white is castling
    if piece.color == 'w'
      return false if check?('w')
      if b == [2,0]
        return false if @white[6].history.length > 1
        # check king's path
        [[2,0],[3,0]].each do |xy|
          return false if under_attack?('w',xy)
        end
        # no pieces between rook and king?
        (1..3).each {|x| return false if @grid[[x,0]]}
      elsif b == [6,0]
        return false if @white[7].history.length > 1
        [[5,0],[6,0]].each do |xy|
          return false if under_attack?('w', xy)
        end
        (5..6).each {|x| return false if @grid[[x,0]]}
      else
        return false
      end

    # if black is castling
    else
      return false if check?('b')
      if b == [2,7]
        return false if @white[6].history.length > 1
        [[2,7],[3,7]].each do |xy|
          return false if under_attack?('b', xy)
        end
        (1..3).each {|x| return false if @grid[[x,7]]}
      elsif b == [6,7]
        return false if @black[7].history.length > 1
        [[5,7],[6,7]].each do |xy|
          return false if under_attack?('b', xy)
        end
        (5..6).each {|x| return false if @grid[[x,7]]}
      else
        return false
      end
    end
    return true
  end

  def enpassant?(a, b)
    piece = @grid[a]
    ax, ay = a
    bx, by = b
    return false unless Pawn === piece && @grid[b] == nil
    # if attacking pawn is white
    if piece.color == 'w'
      return false unless ay == 4
      return false unless b == [ax+1,5] || b == [ax-1,5]
      captor = @grid[[bx,by-1]]
      return false unless Pawn === captor && captor.color == 'b'

    # if attacking pawn is black
    else
      return false unless a[1] == 3
      return false unless b == [a[0]+1,2] || b == [a[0]-1,2]
      captor = @grid[[bx,by+1]]
      return false unless Pawn === captor && captor.color == 'w'
    end
    return true
  end

  def promote_prompt(xy)
    color = @grid[xy].color
    color == 'w' ? (puts "White pawn promotes.") : (puts "Black pawn promotes.")
    loop do
      print "Choose (Q)ueen, (B)ishop, K(N)ight, or (R)ook: "
      promotion = gets.chomp.upcase
      if promotion.length == 1 && promotion =~ /[QBNR]/
        promote(xy, promotion)
        break
      else
        puts "Invalid option, try again."
      end
    end
  end

  def promote(xy, promotion)
    piece = @grid[xy]
    case promotion
    when 'Q'
      promoted = Queen.new(piece.color, xy)
    when 'B'
      promoted = Bishop.new(piece.color, xy)
    when 'N'
      promoted = Knight.new(piece.color, xy)
    when 'R'
      promoted = Rook.new(piece.color, xy)
    else
      nil
    end

    if piece.color == 'w'
      @white[@white.index(piece)] = promoted
    else
      @black[@black.index(piece)] = promoted
    end
    @grid[xy] = promoted
  end

  def check?(color)
    if color == 'w'
      under_attack?('w', @white[0].xy) ? (return true) : (return false)
    else
      under_attack?('b', @black[0].xy) ? (return true) : (return false)
    end
  end

  # does the move end with own king in check?
  # execute move to see if it puts own king in check, then un-execute
  def checks_self?(a, b)
    # white's move
    piece = @grid[a]
    if piece.color == 'w'
      # move was a capturing move
      if (captor = @grid[b])
        captor.move([99,99], @grid)
        piece.move(b, @grid)
        if check?('w')
          piece.undo_move(@grid)
          captor.undo_move(@grid)
          return true
        end
        piece.undo_move(@grid)
        captor.undo_move(@grid)
      # move did not capture
      else
        piece.move(b, @grid)
        if check?('w')
          piece.undo_move(@grid)
          return true
        end
        piece.undo_move(@grid)
      end
    # black's move
    else
      if (captor = @grid[b])
        captor.move([99,99], @grid)
        piece.move(b, @grid)
        if check?('b')
          piece.undo_move(@grid)
          captor.undo_move(@grid)
          return true
        end
        piece.undo_move(@grid)
        captor.undo_move(@grid)
      else
        piece.move(b, @grid)
        if check?('b')
          piece.undo_move(@grid)
          return true
        end
        piece.undo_move(@grid)
      end
    end
    return false
  end

  def checkmate?(color)
    if color == 'w'
      king = @white[0]
      if king.no_legal_moves?(@grid, @black, @white)
        @black.each do |attacker|          
          if attacker.legal_move?(king.xy, @grid, @white, @black)
            #check if attacker can be captured
            @white.each do |defender|
              return false if (defender.legal_move?(attacker.xy, @grid, @black, @white))
            end
            # check if attacker can be blocked by ally piece
            if Queen === attacker || Bishop === attacker || Rook === attacker
              attacker.possible_moves.each do |path|
                if path.include?(king.xy)
                  path[0..path.index(king.xy)].each do |xy|
                    @white.each {|defender| return false if defender.legal_move?(xy, @grid, @black, @white)}
                  end
                end
              end
            end
          end
        end
      else
        return false
      end
    else
      king = @black[0]
      if king.no_legal_moves?(@grid, @white, @black)
        @white.each do |attacker|
          if attacker.legal_move?(king.xy, @grid, @black, @white)
            @black.each do |defender|
              return false if (defender && defender.legal_move?(attacker.xy, @grid, @white, @black))
            end
            if Queen === attacker || Bishop === attacker || Rook === attacker
              attacker.possible_moves.each do |path|
                if path.include?(king.xy)
                  path[0..path.index(king.xy)].each do |xy|
                    @black.each {|defender| return false if defender.legal_move?(xy, @grid, @white, @black)}
                  end
                end
              end
            end
          end
        end
      else
        return false
      end
    end
    return true
  end
end