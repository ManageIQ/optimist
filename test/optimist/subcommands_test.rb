require 'stringio'
require 'test_helper'

module Optimist

module SubcommandTests

  def if_did_you_mean_enabled
    if (Module::const_defined?("DidYouMean") &&
        Module::const_defined?("DidYouMean::JaroWinkler") &&
        Module::const_defined?("DidYouMean::Levenshtein"))
      yield
    end
  end
  
  # fails when no args provided
  def test_subcommand_noargs
    assert_raises(Optimist::CommandlineError, /No subcommand provided/) do
      @p.parse([])
    end
  end

  # ok when global help provided
  def test_subcommand_global_help
    assert_raises(Optimist::HelpNeeded) do
      @p.parse(%w(-h))
    end
    sio = StringIO.new "w"
    @p.educate sio
    assert_match(/list\s+show the list/, sio.string)
    assert_match(/create\s*\n/, sio.string)
  end

  # fails when invalid param given
  def test_subcommand_invalid_opt
    assert_raises_errmatch(Optimist::CommandlineError, /unknown argument '--boom'/) do
      @p.parse(%w(--boom))
    end
  end
  
  # fails when invalid subcommand given
  def test_subcommand_invalid_subcmd
    assert_raises_errmatch(Optimist::CommandlineError, /unknown subcommand 'boom'/) do
      @p.parse(%w(boom))
    end
  end
  
  # ok when valid subcommand given
  def test_subcommand_ok_noopts
    @p.parse(%w(list))
    @p.parse(%w(create))
  end

  # ok when valid subcommand given with help param
  def test_subcommand_help_subcmd1
    err = assert_raises(Optimist::HelpNeeded) do
      @p.parse(%w(list --help))
    end

    sio = StringIO.new "w"
    err.parser.educate sio
    assert_match(/all.*list all the things/, sio.string)
    assert_match(/help.*Show this message/, sio.string)
  end
  
  def test_subcommand_help_subcmd2
    err = assert_raises(Optimist::HelpNeeded) do
      @p.parse(%w(create --help))
    end
    sio = StringIO.new "w"
    err.parser.educate sio
    assert_match(/partial.*create a partial thing/, sio.string)
    assert_match(/name.*creation name/, sio.string)
    assert_match(/help.*Show this message/, sio.string)
  end
  
  # fails when valid subcommand given with invalid param
  def test_subcommand_invalid_subopt
    assert_raises_errmatch(Optimist::CommandlineError, /unknown argument '--foo' for command 'list'/) do
      @p.parse(%w(list --foo))
    end
    assert_raises_errmatch(Optimist::CommandlineError, /unknown argument '--bar' for command 'create'/) do
      @p.parse(%w(create --bar))
    end
  end

  # ok when valid subcommand given with valid params
  def test_subcommand_ok
    @p.parse(%w(list --all))
    @p.parse(%w(create --partial --name duck))
  end

  
end

class SubcommandsWithGlobalOptTest < ::MiniTest::Test
  include SubcommandTests
  def setup
    @p = Parser.new
    @p.opt :some_global_stropt, 'Some global string option', type: :string, short: :none
    @p.opt :some_global_flag, 'Some global flag'
    @p.subcmd :list, "show the list" do
      opt :all, 'list all the things', type: :boolean
    end
    @p.subcmd "create" do
      opt :partial, 'create a partial thing', type: :boolean
      opt :name,    'creation name', type: :string
    end
  end

  def test_subcommand_ok_gopts
    @p.parse(%w(--some-global-flag list --all))
    @p.parse(%w(--some-global-stropt GHI create --partial --name duck))
    # handles minimal-length partial-long arguments
    @p.parse(%w(--some-global-s GHI create --par --na duck))
  end
  
  def test_subcommand_invalid_gopts
    assert_raises_errmatch(Optimist::CommandlineError, /unknown argument '--all'/) do
      @p.parse(%w(--all list --all))
    end
    # handles misspellings property on subcommands
    if_did_you_mean_enabled do
      err_regex = /unknown argument '--partul' for command 'create'.  Did you mean: \[--partial\]/
      assert_raises_errmatch(Optimist::CommandlineError, err_regex) do
        @p.parse(%w(--some-global-stropt GHI create --partul --name duck))
      end
    end
  end

end

class SubcommandsWithoutGlobalOptTest < ::MiniTest::Test
  include SubcommandTests
  def setup
    @p = Parser.new
    @p.subcmd :list, "show the list" do
      opt :all, 'list all the things', type: :boolean
    end
    @p.subcmd "create" do
      opt :partial, 'create a partial thing', type: :boolean
      opt :name,    'creation name', type: :string
    end
  end

  def test_subcommand_invalid_gopts
    assert_raises_errmatch(Optimist::CommandlineError, /unknown argument '--some-global-flag'/) do
      @p.parse(%w(--some-global-flag list --all))
    end
  end
end

end
