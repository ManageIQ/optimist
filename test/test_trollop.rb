## test/test_trollop.rb -- unit tests for trollop
## Author::    William Morgan (mailto: wmorgan-trollop@masanjin.net)
## Copyright:: Copyright 2007 William Morgan
## License::   GNU GPL version 2

require 'test/unit'
require 'stringio'
require 'trollop'

module Trollop
module Test

class Trollop < ::Test::Unit::TestCase
  def setup
    @p = Parser.new
  end

  def test_unknown_arguments
    assert_raise(CommandlineError) { @p.parse(%w(--arg)) }
    @p.opt "arg", "desc"
    assert_nothing_raised { @p.parse(%w(--arg)) }
    assert_raise(CommandlineError) { @p.parse(%w(--arg2)) }
  end

  def test_syntax_check
    @p.opt "arg", "desc"

    assert_nothing_raised { @p.parse(%w(--arg)) }
    assert_nothing_raised { @p.parse(%w(arg)) }
    assert_raise(CommandlineError) { @p.parse(%w(---arg)) }
    assert_raise(CommandlineError) { @p.parse(%w(-arg)) }
  end

  def test_required_flags_are_required
    @p.opt "arg", "desc", :required => true
    @p.opt "arg2", "desc", :required => false
    @p.opt "arg3", "desc", :required => false

    assert_nothing_raised { @p.parse(%w(--arg)) }
    assert_nothing_raised { @p.parse(%w(--arg --arg2)) }
    assert_raise(CommandlineError) { @p.parse(%w(--arg2)) }
    assert_raise(CommandlineError) { @p.parse(%w(--arg2 --arg3)) }
  end
  
  ## flags that take an argument error unless given one
  def test_argflags_demand_args
    @p.opt "goodarg", "desc", :type => String
    @p.opt "goodarg2", "desc", :type => String

    assert_nothing_raised { @p.parse(%w(--goodarg goat)) }
    assert_raise(CommandlineError) { @p.parse(%w(--goodarg --goodarg2 goat)) }
    assert_raise(CommandlineError) { @p.parse(%w(--goodarg)) }
  end

  ## flags that don't take arguments ignore them
  def test_arglessflags_refuse_args
    @p.opt "goodarg", "desc"
    @p.opt "goodarg2", "desc"
    assert_nothing_raised { @p.parse(%w(--goodarg)) }
    assert_nothing_raised { @p.parse(%w(--goodarg --goodarg2)) }
    opts = @p.parse %w(--goodarg a)
    assert_equal true, opts["goodarg"]
    assert_equal ["a"], @p.leftovers
  end

  ## flags that require args of a specific type refuse args of other
  ## types
  def test_typed_args_refuse_args_of_other_types
    assert_nothing_raised { @p.opt "goodarg", "desc", :type => :int }
    assert_raise(ArgumentError) { @p.opt "badarg", "desc", :type => :asdf }

    assert_nothing_raised { @p.parse(%w(--goodarg 3)) }
    assert_raise(CommandlineError) { @p.parse(%w(--goodarg 4.2)) }
    assert_raise(CommandlineError) { @p.parse(%w(--goodarg hello)) }
  end

  ## type is correctly derived from :default
  def test_type_correctly_derived_from_default
    assert_nothing_raised { @p.opt "goodarg", "desc", :default => 0 }
    assert_raise(ArgumentError) { @p.opt "badarg", "desc", :default => [] }

    assert_nothing_raised { @p.parse(%w(--goodarg 3)) }
    assert_raise(CommandlineError) { @p.parse(%w(--goodarg 4.2)) }
    assert_raise(CommandlineError) { @p.parse(%w(--goodarg hello)) }
  end    

  ## :type and :default must match if both are specified
  def test_type_and_default_must_match
    assert_nothing_raised { @p.opt "goodarg", "desc", :type => :int, :default => 4 }
    assert_nothing_raised { @p.opt "goodarg2", "desc", :type => :string, :default => "yo" }
    assert_raise(ArgumentError) { @p.opt "badarg", "desc", :type => :int, :default => "hello" }
    assert_raise(ArgumentError) { @p.opt "badarg2", "desc", :type => :String, :default => 4 }
  end

  def test_long_detects_bad_names
    assert_nothing_raised { @p.opt "goodarg", "desc", :long => "none" }
    assert_nothing_raised { @p.opt "goodarg2", "desc", :long => "--two" }
    assert_raise(ArgumentError) { @p.opt "badarg", "desc", :long => "" }
    assert_raise(ArgumentError) { @p.opt "badarg2", "desc", :long => "--" }
    assert_raise(ArgumentError) { @p.opt "badarg3", "desc", :long => "-one" }
    assert_raise(ArgumentError) { @p.opt "badarg4", "desc", :long => "---toomany" }
  end

  def test_short_detects_bad_names
    assert_nothing_raised { @p.opt "goodarg", "desc", :short => "a" }
    assert_nothing_raised { @p.opt "goodarg2", "desc", :short => "-b" }
    assert_raise(ArgumentError) { @p.opt "badarg", "desc", :short => "" }
    assert_raise(ArgumentError) { @p.opt "badarg2", "desc", :short => "-ab" }
    assert_raise(ArgumentError) { @p.opt "badarg3", "desc", :short => "--t" }
  end

  def test_short_names_determined_automatically
    @p.opt "arg"
    @p.opt "arg2"
    @p.opt "arg3"
    assert_raise(ArgumentError) { @p.opt "gra" }
    opts = @p.parse %w(-a -g)
    assert_equal true, opts["arg"]
    assert_equal false, opts["arg2"]
    assert_equal true, opts["arg3"]
  end

  def test_short_can_be_nothing
    assert_nothing_raised do
      @p.opt "arg", "desc", :short => :none
      @p.parse []
    end

    sio = StringIO.new "w"
    @p.educate sio
    assert sio.string =~ /--arg:\s+desc/

    assert_raise(CommandlineError) { @p.parse %w(-a) }
  end

  ## two args can't have the same name
  def test_conflicting_names_are_detected
    assert_nothing_raised { @p.opt "goodarg", "desc" }
    assert_raise(ArgumentError) { @p.opt "goodarg", "desc" }
  end

  ## two args can't have the same :long
  def test_conflicting_longs_detected
    assert_nothing_raised { @p.opt "goodarg", "desc", :long => "--goodarg" }
    assert_raise(ArgumentError) { @p.opt "badarg", "desc", :long => "--goodarg" }
  end  

  ## two args can't have the same :short
  def test_conflicting_shorts_detected
    assert_nothing_raised { @p.opt "goodarg", "desc", :short => "-g" }
    assert_raise(ArgumentError) { @p.opt "badarg", "desc", :short => "-g" }
  end  

  def test_flag_defaults
    @p.opt "defaultfalse", "desc"
    @p.opt "defaulttrue", "desc", :default => true
    opts = @p.parse []
    assert_equal false, opts["defaultfalse"]
    assert_equal true, opts["defaulttrue"]

    opts = @p.parse %w(--defaultfalse --defaulttrue)
    assert_equal true, opts["defaultfalse"]
    assert_equal false, opts["defaulttrue"]
  end

  def test_special_flags_work
    @p.version "asdf fdas"
    assert_raise(VersionNeeded) { @p.parse(%w(-v)) }
    assert_raise(HelpNeeded) { @p.parse(%w(-h)) }
  end

  def test_short_options_combine
    @p.opt :arg1, "desc", :short => "a"
    @p.opt :arg2, "desc", :short => "b"
    @p.opt :arg3, "desc", :short => "c", :type => :int

    opts = nil
    assert_nothing_raised { opts = @p.parse %w(-a -b) }
    assert_equal true, opts[:arg1]
    assert_equal true, opts[:arg2]
    assert_equal nil, opts[:arg3]

    assert_nothing_raised { opts = @p.parse %w(-ab) }
    assert_equal true, opts[:arg1]
    assert_equal true, opts[:arg2]
    assert_equal nil, opts[:arg3]

    assert_nothing_raised { opts = @p.parse %w(-ac 4 -b) }
    assert_equal true, opts[:arg1]
    assert_equal true, opts[:arg2]
    assert_equal 4, opts[:arg3]

    assert_raises(CommandlineError) { @p.parse %w(-cab 4) }
    assert_raises(CommandlineError) { @p.parse %w(-cba 4) }
  end

  def test_version_only_appears_if_set
    @p.opt "arg", "desc"
    assert_raise(CommandlineError) { @p.parse %w(-v) }
    @p.version "trollop 1.2.3.4"
    assert_raise(VersionNeeded) { @p.parse %w(-v) }
  end

  def test_doubledash_ends_option_processing
    @p.opt :arg1, "desc", :short => "a", :default => 0
    @p.opt :arg2, "desc", :short => "b", :default => 0
    opts = nil
    assert_nothing_raised { opts = @p.parse %w(-- -a 3 -b 2) }
    assert_equal opts[:arg1], 0
    assert_equal opts[:arg2], 0
    assert_equal %w(-a 3 -b 2), @p.leftovers
    assert_nothing_raised { opts = @p.parse %w(-a 3 -- -b 2) }
    assert_equal opts[:arg1], 3
    assert_equal opts[:arg2], 0
    assert_equal %w(-b 2), @p.leftovers
    assert_nothing_raised { opts = @p.parse %w(-a 3 -b 2 --) }
    assert_equal opts[:arg1], 3
    assert_equal opts[:arg2], 2
    assert_equal %w(), @p.leftovers
  end

  def test_wrap
    assert_equal [""], @p.wrap("")
    assert_equal ["a"], @p.wrap("a")
    assert_equal ["one two", "three"], @p.wrap("one two three", :width => 8)
    assert_equal ["one two three"], @p.wrap("one two three", :width => 80)
    assert_equal ["one", "two", "three"], @p.wrap("one two three", :width => 3)
    assert_equal ["onetwothree"], @p.wrap("onetwothree", :width => 3)
    assert_equal [
      "Test is an awesome program that does something very, very important.",
      "",
      "Usage:",
      "  test [options] <filenames>+",
      "where [options] are:"], @p.wrap(<<EOM, :width => 100)
Test is an awesome program that does something very, very important.

Usage:
  test [options] <filenames>+
where [options] are:
EOM
  end

  def test_floating_point_formatting
    @p.opt :arg, "desc", :type => :float, :short => "f"
    opts = nil
    assert_nothing_raised { opts = @p.parse %w(-f 1) }
    assert_equal 1.0, opts[:arg]
    assert_nothing_raised { opts = @p.parse %w(-f 1.0) }
    assert_equal 1.0, opts[:arg]
    assert_nothing_raised { opts = @p.parse %w(-f 0.1) }
    assert_equal 0.1, opts[:arg]
    assert_nothing_raised { opts = @p.parse %w(-f .1) }
    assert_equal 0.1, opts[:arg]
    assert_nothing_raised { opts = @p.parse %w(-f .99999999999999999999) }
    assert_equal 1.0, opts[:arg]
    assert_nothing_raised { opts = @p.parse %w(-f -1) }
    assert_equal(-1.0, opts[:arg])
    assert_nothing_raised { opts = @p.parse %w(-f -1.0) }
    assert_equal(-1.0, opts[:arg])
    assert_nothing_raised { opts = @p.parse %w(-f -0.1) }
    assert_equal(-0.1, opts[:arg])
    assert_nothing_raised { opts = @p.parse %w(-f -.1) }
    assert_equal(-0.1, opts[:arg])
    assert_raises(CommandlineError) { @p.parse %w(-f a) }
    assert_raises(CommandlineError) { @p.parse %w(-f 1a) }
    assert_raises(CommandlineError) { @p.parse %w(-f 1.a) }
    assert_raises(CommandlineError) { @p.parse %w(-f a.1) }
    assert_raises(CommandlineError) { @p.parse %w(-f 1.0.0) }
    assert_raises(CommandlineError) { @p.parse %w(-f .) }
    assert_raises(CommandlineError) { @p.parse %w(-f -.) }
  end

  def test_short_options_cant_be_numeric
    assert_raises(ArgumentError) { @p.opt :arg, "desc", :short => "-1" }
    @p.opt :a1b, "desc"
    @p.opt :a2b, "desc"
    assert_not_equal "2", @p.specs[:a2b][:short]
  end

  def test_short_options_can_be_weird
    assert_nothing_raised { @p.opt :arg1, "desc", :short => "#" }
    assert_nothing_raised { @p.opt :arg2, "desc", :short => "." }
    assert_raises(ArgumentError) { @p.opt :arg3, "desc", :short => "-" }
  end

  def test_options_cant_be_set_multiple_times
    @p.opt :arg, "desc", :short => "-x"
    assert_nothing_raised { @p.parse %w(-x) }
    assert_raises(CommandlineError) { @p.parse %w(-x -x) }
    assert_raises(CommandlineError) { @p.parse %w(-xx) }
  end

  def test_long_options_also_take_equals
    @p.opt :arg, "desc", :long => "arg", :type => String, :default => "hello"
    opts = nil
    assert_nothing_raised { opts = @p.parse %w() }
    assert_equal "hello", opts[:arg]
    assert_nothing_raised { opts = @p.parse %w(--arg goat) }
    assert_equal "goat", opts[:arg]
    assert_nothing_raised { opts = @p.parse %w(--arg=goat) }
    assert_equal "goat", opts[:arg]
    assert_raises(CommandlineError) { opts = @p.parse %w(--arg= goat) }
  end

  def test_auto_generated_long_names_convert_underscores_to_hyphens
    @p.opt :hello_there
    assert_equal "hello-there", @p.specs[:hello_there][:long]
  end

  def test_arguments_passed_through_block
    @goat = 3
    boat = 4
    Parser.new(@goat) do |goat|
      boat = goat
    end
    assert_equal @goat, boat
  end

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
  end

  def test_help_preserves_positions
    @p.opt :zzz, "zzz"
    @p.opt :aaa, "aaa"
    sio = StringIO.new "w"
    @p.educate sio

    help = sio.string.split "\n"
    assert help[1] =~ /zzz/
    assert help[2] =~ /aaa/
  end

  def test_version_and_help_short_args_can_be_overridden
    @p.opt :verbose, "desc", :short => "-v"
    @p.opt :hello, "desc", :short => "-h"
    @p.version "version"

    assert_nothing_raised { @p.parse(%w(-v)) }
    assert_raises(VersionNeeded) { @p.parse(%w(--version)) }
    assert_nothing_raised { @p.parse(%w(-h)) }
    assert_raises(HelpNeeded) { @p.parse(%w(--help)) }
  end

  def test_version_and_help_long_args_cann_be_overridden
    @p.opt :asdf, "desc", :long => "help"
    @p.opt :asdf2, "desc2", :long => "version"
    assert_nothing_raised { @p.parse %w() }
    assert_nothing_raised { @p.parse %w(--help) }
    assert_nothing_raised { @p.parse %w(--version) }
    assert_nothing_raised { @p.parse %w(-h) }
    assert_nothing_raised { @p.parse %w(-v) }
  end

end

end
end
