require 'test_helper'

module OptimistXL

  class AlternateNamesTest < ::MiniTest::Test

    def setup
    end

    def test_altshort
       @p = Parser.new
       @p.opt :catarg, "desc", :short => ["c","C"]

       opts = @p.parse %w(-c)
       assert_equal true, opts[:catarg]
       opts = @p.parse %w(-C)
       assert_equal true, opts[:catarg]
       assert_raises(CommandlineError) { @p.parse %w(-c -C) }
       assert_raises(CommandlineError) { @p.parse %w(-cC) }
    end

    def test_altshort_with_multi
      @p = Parser.new
      @p.opt :arg, "desc", :short => ["-c", "-C"], :multi => true
      @p.parse %w(-c)
      @p.parse %w(-C -c)
      @p.parse %w(-c -C)
      @p.parse %w(-c -C -c -C)
      @p.parse %w(-ccC)
      assert_equal true, opts[:catarg]
    end

    def test_altlong
    end
    
    def test_altshort_help
      @p = Parser.new
      @p.opt :cat, 'cat', short: ['c','C','a','t']
      err = assert_raises(OptimistXL::HelpNeeded) do
        @p.parse(%w(--help))
      end
      sio = StringIO.new "w"
      err.parser.educate sio
      assert_match(//, sio.string)
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
