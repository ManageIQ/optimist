require 'stringio'
require 'test_helper'

module Trollop

  class ParserOptTest < ::MiniTest::Test

    private

    def parser
      @p ||= Parser.new
    end
  end
end
