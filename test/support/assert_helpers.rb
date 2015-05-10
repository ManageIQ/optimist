module AssertHelpers
  def assert_parses_correctly(parser, commandline, expected_opts,
                              expected_leftovers)
    opts = parser.parse commandline
    assert_equal expected_opts, opts
    assert_equal expected_leftovers, parser.leftovers
  end

  def assert_stderr(msg = nil)
    old_stderr, $stderr = $stderr, StringIO.new('')
    yield
    assert_match msg, $stderr.string if msg
  ensure
    $stderr = old_stderr
  end

  def assert_stdout(msg = nil)
    old_stdout, $stdout = $stdout, StringIO.new('')
    yield
    assert_match msg, $stdout.string if msg
  ensure
    $stdout = old_stdout
  end
end

