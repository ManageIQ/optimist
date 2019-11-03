require 'stringio'
require 'test_helper'

module OptimistXL

  class ParserOptTest < ::MiniTest::Test

    private

    def parser
      @p ||= Parser.new
    end
  end
end
