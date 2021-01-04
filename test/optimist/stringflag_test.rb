require 'stringio'
require 'test_helper'

module Optimist
  class StringFlagParserTest < ::MiniTest::Test
    def setup
      @p = Parser.new
    end

    # in this case, the stringflag should return false
    def test_stringflag_unset
      @p.opt :xyz, "desc", :type => :stringflag
      @p.opt :abc, "desc", :type => :flag
      opts = @p.parse %w()
      assert_equal false, opts[:xyz]
      assert_equal false, opts[:abc]
      opts = @p.parse %w(--abc)
      assert_equal false, opts[:xyz]
      assert_equal true, opts[:abc]
    end

    # in this case, the stringflag should return true
    def test_stringflag_as_flag
      @p.opt :xyz, "desc", :type => :stringflag
      @p.opt :abc, "desc", :type => :flag
      opts = @p.parse %w(--xyz )
      assert_equal true, opts[:xyz_given]
      assert_equal true, opts[:xyz]
      assert_equal false, opts[:abc]
      opts = @p.parse %w(--xyz --abc)
      assert_equal true, opts[:xyz_given]
      assert_equal true, opts[:xyz]
      assert_equal true, opts[:abc]
    end

    # in this case, the stringflag should return a string
    def test_stringflag_as_string
      @p.opt :xyz, "desc", :type => :stringflag
      @p.opt :abc, "desc", :type => :flag
      opts = @p.parse %w(--xyz abcd)
      assert_equal true, opts[:xyz_given]
      assert_equal "abcd", opts[:xyz]
      assert_equal false, opts[:abc]
      opts = @p.parse %w(--xyz abcd --abc)
      assert_equal true, opts[:xyz_given]
      assert_equal "abcd", opts[:xyz]
      assert_equal true, opts[:abc]
    end

    def test_stringflag_with_string_default
      @p.opt :log, "desc", :type => :stringflag, default: "output.log"
      opts = @p.parse []
      assert_nil opts[:log_given]
      assert_equal "output.log", opts[:log]

      opts = @p.parse %w(--no-log)
      assert_equal true, opts[:log_given]
      assert_equal false, opts[:log]

      opts = @p.parse %w(--log)
      assert_equal true, opts[:log_given]
      assert_equal "output.log", opts[:log]

      opts = @p.parse %w(--log other.log)
      assert_equal true, opts[:log_given]
      assert_equal "other.log", opts[:log]
    end

    # should be same as with no default, but making sure.
    def test_stringflag_with_false_default
      @p.opt :log, "desc", :type => :stringflag, default: false
      opts = @p.parse []
      assert_nil opts[:log_given]
      assert_equal false, opts[:log]

      opts = @p.parse %w(--no-log)
      assert_equal true, opts[:log_given]
      assert_equal false, opts[:log]

      opts = @p.parse %w(--log)
      assert_equal true, opts[:log_given]
      assert_equal true, opts[:log]

      opts = @p.parse %w(--log other.log)
      assert_equal true, opts[:log_given]
      assert_equal "other.log", opts[:log]
    end
    
    def test_stringflag_with_no_defaults
      @p.opt :log, "desc", :type => :stringflag
        
      opts = @p.parse []
      assert_nil opts[:log_given]
      assert_equal false, opts[:log]

      opts = @p.parse %w(--no-log)
      assert_equal true, opts[:log_given]
      assert_equal false, opts[:log]

      opts = @p.parse %w(--log)
      assert_equal true, opts[:log_given]
      assert_equal true, opts[:log]

      opts = @p.parse %w(--log other.log)
      assert_equal true, opts[:log_given]
      assert_equal "other.log", opts[:log]
      
    end
  end

  class MultiStringFlagParserTest < ::MiniTest::Test
    def setup
      @p = Parser.new
      @p.opt :xyz, "desc", :type => :stringflag, :multi => true
      @p.opt :ghi, "desc", :type => :stringflag, :multi => true, default: ["gg","hh"]
      @p.opt :abc, "desc", :type => :string, :multi => true
    end

    # in this case, the stringflag should return multiple strings
    def test_multi_stringflag_as_strings
      opts = @p.parse %w(--xyz dog --xyz cat)
      assert_equal true, opts[:xyz_given]
      assert_equal ["dog","cat"], opts[:xyz]
      assert_equal [], opts[:abc] # note, multi-args default to empty array
      assert_nil opts[:ghi_given]
      assert_equal ["gg","hh"], opts[:ghi]
    end

    def test_multi_stringflag_as_flags
      opts = @p.parse %w(--xyz --xyz --xyz)
      assert_equal true, opts[:xyz_given]
      assert_equal [true, true, true], opts[:xyz]
    end

    def test_multi_stringflag_as_mix1
      opts = @p.parse %w(--xyz --xyz dog --xyz cat)
      assert_equal true, opts[:xyz_given]
      assert_equal [true, "dog", "cat"], opts[:xyz]
    end

    def test_multi_stringflag_as_mix2
      opts = @p.parse %w(--xyz dog --xyz cat --xyz --abc letters)
      assert_equal true, opts[:xyz_given]
      assert_equal ["dog", "cat", true], opts[:xyz]
      assert_equal ["letters"], opts[:abc]
    end

    def test_multi_stringflag_override_array_default
      opts = @p.parse %w(--xyz --ghi yy --ghi zz)
      assert_equal true, opts[:xyz_given]
      assert_equal true, opts[:ghi_given]
      assert_equal ["yy","zz"], opts[:ghi]
    end

  end
    
end

