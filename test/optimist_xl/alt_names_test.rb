require 'test_helper'

module OptimistXL

  class AlternateNamesTest < ::MiniTest::Test

    def setup
    end

    def test_altshort
       @p = Parser.new
       @p.opt :catarg, "desc", :short => ["c", "-C"]
       opts = @p.parse %w(-c)
       assert_equal true, opts[:catarg]
       opts = @p.parse %w(-C)
       assert_equal true, opts[:catarg]
       assert_raises(CommandlineError) { @p.parse %w(-c -C) }
       assert_raises(CommandlineError) { @p.parse %w(-cC) }
    end

    def test_altshort_with_multi
      @p = Parser.new
      @p.opt :flag, "desc", :short => ["-c", "C", :x], :multi => true
      @p.opt :num, "desc", :short => ["-n", "N"], :multi => true, type: Integer
      @p.parse %w(-c)
      @p.parse %w(-C -c -x)
      @p.parse %w(-c -C)
      @p.parse %w(-c -C -c -C)
      opts = @p.parse %w(-ccCx)
      assert_equal true, opts[:flag]
      @p.parse %w(-c)
      @p.parse %w(-N 1 -n 3)
      @p.parse %w(-n 2 -N 4)
      opts = @p.parse %w(-n 4 -N 3 -n 2 -N 1)
      assert_equal [4, 3, 2, 1], opts[:num]
    end

    def test_altlong
    end
    
    def test_altshort_help
      @p = Parser.new
      @p.opt :cat, 'cat', short: ['c','C','a','T']
      err = assert_raises(OptimistXL::HelpNeeded) do
        @p.parse(%w(--help))
      end
      sio = StringIO.new "w"
      err.parser.educate sio
      # expect mutliple short-opts to be in the help
      assert_match(/-c, -C, -a, -T, --cat/, sio.string)
    end

    def test_altlong_help
      @p = Parser.new
      @p.opt :cat, 'a cat', alt: :feline
      @p.opt :dog, 'a dog', alt: ['pooch', :canine]
      err = assert_raises(OptimistXL::HelpNeeded) do
        @p.parse(%w(--help))
      end
      sio = StringIO.new "w"
      err.parser.educate sio
      assert_match(//, sio.string)
    end
    
  end
end
