require 'stringio'
require 'test_helper'

module Optimist

  class ParserOptTest < ::MiniTest::Test

    private

    def parser
      @p ||= Parser.new
    end
  end
end
