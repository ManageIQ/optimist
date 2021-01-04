#!/usr/bin/env ruby
require_relative "../lib/optimist"

result = Optimist::options do 
  opt :global_flag, 'Some global flag'
  subcmd :list, "Show the to-do list" do
    opt :recent, 'list only N-recent items', type: Integer, default: 5
    opt :all, 'list all the things', type: :boolean
  end
  subcmd "create", "Create a to-do item" do
    opt :name, 'item name', type: String
  end
end

p result
