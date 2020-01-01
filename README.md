# OptimistXL

http://github.com/nanobowers/optimist_xl

[![Build Status](https://travis-ci.org/nanobowers/optimist_xl.svg)](https://travis-ci.org/nanobowers/optimist_xl)

## Documentation

- Wiki: http://github.com/nanobowers/optimist_xl/wiki
- Examples: http://github.com/nanobowers/optimist_xl/tree/master/examples
- Code quickstart: See `OptimistXL.options` and then `OptimistXL::Parser#opt`.

## Description

OptimistXL is a commandline option parser for Ruby that just gets out of your way.
One line of code per option is all you need to write. For that, you get a nice
automatically-generated help page, robust option parsing, and sensible defaults
for everything you don't specify.

## Features

- Dirt-simple usage.
- Sensible defaults. No tweaking necessary, much tweaking possible.
- Support for long options, short options, subcommands, and automatic type validation and
  conversion.
- Automatic help message generation, wrapped to current screen width.

## Extended features

### Parser Settings
- Automatic suggestions whens incorrect options are given
    - disable with `suggestions: false`
- Inexact matching of long arguments
    - disable with `exact_match: true`
- Available prevention of short-arguments by default
    - enable with `explicit_short_opts: true`

### Option Settings

Permitted options allow specifying valid choices for an option using lists, ranges or regexp's 
- `permitted:` to specify a allow lists, ranges or regexp filtering of options.
- `permitted_response:` can be added to provide more explicit output when incorrect choices are given.
- see [example](examples/permitted.rb)
- concept and code via @akhoury6

### Subcommands
"Native" subcommand support
- see [example](examples/subcommands.rb)
- ideas borrowed from https://github.com/jwliechty/trollop-subcommands

## Requirements

* Ruby 2.2+
* A burning desire to write less code.

## Install

* `gem install optimist_xl`

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
