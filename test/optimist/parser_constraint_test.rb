require 'test_helper'

module Optimist

class ParserConstraintTest < ::Minitest::Test
  def setup
    @p = Parser.new
  end

  def parser
    @p ||= Parser.new
  end

  def test_conflicts
    @p.opt :one
    assert_raises(ArgumentError) { @p.conflicts :one, :two }
    @p.opt :two
    @p.conflicts :one, :two
    @p.parse %w(--one)
    @p.parse %w(--two)
    assert_raises(CommandlineError) { @p.parse %w(--one --two) }

    @p.opt :hello
    @p.opt :yellow
    @p.opt :mellow
    @p.opt :jello
    @p.conflicts :hello, :yellow, :mellow, :jello
    assert_raises(CommandlineError) { @p.parse %w(--hello --yellow --mellow --jello) }
    assert_raises(CommandlineError) { @p.parse %w(--hello --mellow --jello) }
    assert_raises(CommandlineError) { @p.parse %w(--hello --jello) }

    @p.parse %w(--hello)
    @p.parse %w(--jello)
    @p.parse %w(--yellow)
    @p.parse %w(--mellow)

    @p.parse %w(--mellow --one)
    @p.parse %w(--mellow --two)

    assert_raises(CommandlineError) { @p.parse %w(--mellow --two --jello) }
    assert_raises(CommandlineError) { @p.parse %w(--one --mellow --two --jello) }
  end

  def test_conflict_error_messages
    @p.opt :one
    @p.opt "two"
    @p.conflicts :one, "two"
    err_regex = %r/only one of --one, --two can be given/
    assert_raises_errmatch(CommandlineError, err_regex) { @p.parse %w(--one --two) }
  end

  def test_either
    @p.opt :one
    assert_raises(ArgumentError) { @p.either :one, :two }
    @p.opt :two
    @p.either :one, :two
    @p.parse %w(--one)
    @p.parse %w(--two)
    assert_raises(CommandlineError) { @p.parse %w(--one --two) }
    assert_raises(CommandlineError) { @p.parse %w() }

    @p.opt :hello
    @p.opt :yellow
    @p.opt :mellow
    @p.opt :jello
    @p.either :hello, :yellow, :mellow, :jello
    assert_raises(CommandlineError) { @p.parse %w(--hello --yellow --mellow --jello) }
    assert_raises(CommandlineError) { @p.parse %w(--hello --mellow --jello) }
    assert_raises(CommandlineError) { @p.parse %w(--hello --jello) }

    @p.parse %w(--hello --one)
    @p.parse %w(--jello --two)
    @p.parse %w(--mellow --one)
    @p.parse %w(--mellow --two)

    assert_raises(CommandlineError) { @p.parse %w(--mellow --two --jello) }
    assert_raises(CommandlineError) { @p.parse %w(--one --mellow --two --jello) }
  end

  def test_either_error_messages
    @p.opt :one
    @p.opt :two
    @p.opt :three
    @p.either :one, :two, :three
    err_regex = %r/one and only one of --one, --two, --three is required/
    assert_raises_errmatch(CommandlineError, err_regex) { @p.parse %w(--one --two) }
    assert_raises_errmatch(CommandlineError, err_regex) { @p.parse %w(--three --two --one) }
  end

  def test_depends
    @p.opt :one
    assert_raises(ArgumentError) { @p.depends :one, :two }
    @p.opt :two
    @p.depends :one, :two
    @p.parse %w(--one --two)
    assert_raises(CommandlineError) { @p.parse %w(--one) }
    assert_raises(CommandlineError) { @p.parse %w(--two) }

    @p.opt :hello
    @p.opt :yellow
    @p.opt :mellow
    @p.opt :jello
    @p.depends :hello, :yellow, :mellow, :jello
    @p.parse %w(--hello --yellow --mellow --jello)
    assert_raises(CommandlineError) { @p.parse %w(--hello --mellow --jello) }
    assert_raises(CommandlineError) { @p.parse %w(--hello --jello) }

    assert_raises(CommandlineError) { @p.parse %w(--hello) }
    assert_raises(CommandlineError) { @p.parse %w(--mellow) }

    @p.parse %w(--hello --yellow --mellow --jello --one --two)
    @p.parse %w(--hello --yellow --mellow --jello --one --two a b c)

    assert_raises(CommandlineError) { @p.parse %w(--mellow --two --jello --one) }
  end

  def test_depends_error_messages
    @p.opt :one
    @p.opt "two"
    @p.depends :one, "two"

    @p.parse %w(--one --two)
    err_regex = %r/--one, --two have a dependency and must be given together/
    assert_raises_errmatch(CommandlineError, err_regex) { @p.parse %w(--one) }
    assert_raises_errmatch(CommandlineError, err_regex) { @p.parse %w(--two) }
  end
end
end