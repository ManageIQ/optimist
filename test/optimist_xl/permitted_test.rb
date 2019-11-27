require 'stringio'
require 'test_helper'

module OptimistXL

class PermittedTest < ::MiniTest::Test
  def setup
    @p = Parser.new
  end

  def parser
    @p ||= Parser.new
  end

  def test_permitted_invalid_value
    assert_raises(ArgumentError) {
      @p.opt 'bad1', 'desc', :permitted => 1
    }
    assert_raises(ArgumentError) {
      @p.opt 'bad2', 'desc', :permitted => "A"
    }
    assert_raises(ArgumentError) {
      @p.opt 'bad3', 'desc', :permitted => :abcd
    }
  end

  def test_permitted_with_string_array
    @p.opt 'fiz', 'desc', :type => 'string', :permitted => ['foo', 'bar']
    @p.parse(%w(--fiz foo))
    assert_raises(CommandlineError) { @p.parse(%w(--fiz buz)) }
  end
  
  def test_permitted_with_symbol_array
    @p.opt 'fiz', 'desc', :type => 'string', :permitted => %i[dog cat]
    @p.parse(%w(--fiz dog)) 
    @p.parse(%w(--fiz cat)) 
    assert_raises(CommandlineError) { @p.parse(%w(--fiz rat)) }
  end

  def test_permitted_with_numeric_range
    @p.opt 'fiz', 'desc', :type => Integer, :permitted => 1..3
    opts = @p.parse(%w(--fiz 1))
    assert_equal opts['fiz'], 1
    opts = @p.parse(%w(--fiz 3))
    assert_equal opts['fiz'], 3
    assert_raises(CommandlineError) {
      @p.parse(%w(--fiz 4))
    }
  end

  def test_permitted_with_regexp
    @p.opt 'zipcode', 'desc', :type => String, :permitted => /^[0-9]{5}$/
    @p.parse(%w(--zipcode 39762))
    assert_raises(CommandlineError) {
      @p.parse(%w(--zipcode A9A9AA))
    }
  end
  
end
end
