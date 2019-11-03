# OptimistXL

http://github.com/nanobowers/optimist_xl/

[![Gem Version](https://badge.fury.io/rb/optimist_xl.svg)](http://badge.fury.io/rb/optimist_xl)
[![Build Status](https://travis-ci.org/nanobowers/optimist_xl.svg)](https://travis-ci.org/nanobowers/optimist_xl)
[![Code Climate](https://codeclimate.com/github/nanobowers/optimist_xl/badges/gpa.svg)](https://codeclimate.com/github/nanobowers/optimist_xl)
[![Coverage Status](http://img.shields.io/coveralls/nanobowers/optimist_xl.svg)](https://coveralls.io/r/nanobowers/optimist_xl)

## Documentation

- Quickstart: See `OptimistXL.options` and then `OptimistXL::Parser#opt`.
- Examples: http://github.com/nanobowers/optimist_xl/.
- Wiki: http://github.com/nanobowers/optimist_xl/wiki

## Description

OptimistXL is a commandline option parser for Ruby that just gets out of your way.
One line of code per option is all you need to write. For that, you get a nice
automatically-generated help page, robust option parsing, and sensible defaults
for everything you don't specify.

## Features

- Dirt-simple usage.
- Single file. Throw it in lib/ if you don't want to make it a Rubygem dependency.
- Sensible defaults. No tweaking necessary, much tweaking possible.
- Support for long options, short options, subcommands, and automatic type validation and
  conversion.
- Automatic help message generation, wrapped to current screen width.

## Requirements

* A burning desire to write less code.

## Install

* gem install optimist_xl

## Synopsis

```ruby
require 'optimist_xl'
opts = OptimistXL::options do
  opt :monkey, "Use monkey mode"                    # flag --monkey, default false
  opt :name, "Monkey name", :type => :string        # string --name <s>, default nil
  opt :num_limbs, "Number of limbs", :default => 4  # integer --num-limbs <i>, default to 4
end

p opts # a hash: { :monkey=>false, :name=>nil, :num_limbs=>4, :help=>false }
```

## License

Copyright &copy; 2008-2014 [William Morgan](http://masanjin.net/).

Copyright &copy; 2014 Red Hat, Inc.

Copyright &copy; 2019 Ben Bowers

OptimistXL is released under the [MIT License](http://www.opensource.org/licenses/MIT).
