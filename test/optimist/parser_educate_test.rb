require 'stringio'
require 'test_helper'

module Optimist
  class ParserEduateTest < ::MiniTest::Test
    def setup
    end

    def test_no_arguments_to_stdout
      assert_stdout(/Options:/) do
        parser.educate
      end
    end

    def test_argument_to_stringio
      assert_educates(/Options:/)
    end

    def test_no_headers
      assert_educates(/^Options:/)
    end

    def test_usage
      parser.usage("usage string")
      assert_educates(/^Usage: \w* usage string\n\nOptions:/)
    end

    def test_usage_synopsis_version
    end

    # def test_banner
    # def test_text

      # width, legacy_width
      # wrap
      # wrap_lines

############
# convert these into multiple tests
# pulled out of optimist_test for now
  def test_help_has_default_banner
    @p = Parser.new
    sio = StringIO.new "w"
    @p.parse []
    @p.educate sio
    help = sio.string.split "\n"
    assert help[0] =~ /options/i
    assert_equal 2, help.length # options, then -h

    @p = Parser.new
    @p.version "my version"
    sio = StringIO.new "w"
    @p.parse []
    @p.educate sio
    help = sio.string.split "\n"
    assert help[0] =~ /my version/i
    assert_equal 4, help.length # version, options, -h, -v

    @p = Parser.new
    @p.banner "my own banner"
    sio = StringIO.new "w"
    @p.parse []
    @p.educate sio
    help = sio.string.split "\n"
    assert help[0] =~ /my own banner/i
    assert_equal 2, help.length # banner, -h

    @p = Parser.new
    @p.text "my own text banner"
    sio = StringIO.new "w"
    @p.parse []
    @p.educate sio
    help = sio.string.split "\n"
    assert help[0] =~ /my own text banner/i
    assert_equal 2, help.length # banner, -h
  end

  def test_help_has_optional_usage
    @p = Parser.new
    @p.usage "OPTIONS FILES"
    sio = StringIO.new "w"
    @p.parse []
    @p.educate sio
    help = sio.string.split "\n"
    assert help[0] =~ /OPTIONS FILES/i
    assert_equal 4, help.length # line break, options, then -h
  end

  def test_help_has_optional_synopsis
    @p = Parser.new
    @p.synopsis "About this program"
    sio = StringIO.new "w"
    @p.parse []
    @p.educate sio
    help = sio.string.split "\n"
    assert help[0] =~ /About this program/i
    assert_equal 4, help.length # line break, options, then -h
  end

  def test_help_has_specific_order_for_usage_and_synopsis
    @p = Parser.new
    @p.usage "OPTIONS FILES"
    @p.synopsis "About this program"
    sio = StringIO.new "w"
    @p.parse []
    @p.educate sio
    help = sio.string.split "\n"
    assert help[0] =~ /OPTIONS FILES/i
    assert help[1] =~ /About this program/i
    assert_equal 5, help.length # line break, options, then -h
  end

  def test_help_preserves_positions
    parser.opt :zzz, "zzz"
    parser.opt :aaa, "aaa"
    sio = StringIO.new "w"
    parser.educate sio

    help = sio.string.split "\n"
    assert help[1] =~ /zzz/
    assert help[2] =~ /aaa/
  end

  def test_help_includes_option_types
    parser.opt :arg1, 'arg', :type => :int
    parser.opt :arg2, 'arg', :type => :ints
    parser.opt :arg3, 'arg', :type => :string
    parser.opt :arg4, 'arg', :type => :strings
    parser.opt :arg5, 'arg', :type => :float
    parser.opt :arg6, 'arg', :type => :floats
    parser.opt :arg7, 'arg', :type => :io
    parser.opt :arg8, 'arg', :type => :ios
    parser.opt :arg9, 'arg', :type => :date
    parser.opt :arg10, 'arg', :type => :dates
    sio = StringIO.new "w"
    parser.educate sio

    help = sio.string.split "\n"
    assert help[1] =~ /<i>/
    assert help[2] =~ /<i\+>/
    assert help[3] =~ /<s>/
    assert help[4] =~ /<s\+>/
    assert help[5] =~ /<f>/
    assert help[6] =~ /<f\+>/
    assert help[7] =~ /<filename\/uri>/
    assert help[8] =~ /<filename\/uri\+>/
    assert help[9] =~ /<date>/
    assert help[10] =~ /<date\+>/
  end

  def test_help_has_grammatical_default_text
    parser.opt :arg1, 'description with period.', :default => 'hello'
    parser.opt :arg2, 'description without period', :default => 'world'
    sio = StringIO.new 'w'
    parser.educate sio

    help = sio.string.split "\n"
    assert help[1] =~ /Default/
    assert help[2] =~ /default/
  end
############

    private

    def parser
      @p ||= Parser.new
    end

    def assert_educates(output)
      str = StringIO.new
      parser.educate str
      assert_match output, str.string
    end
  end
end
