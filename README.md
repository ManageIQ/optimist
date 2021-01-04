# Optimist

http://manageiq.github.io/optimist/

[![Gem Version](https://badge.fury.io/rb/optimist.svg)](http://badge.fury.io/rb/optimist)
[![Build Status](https://travis-ci.org/ManageIQ/optimist.svg)](https://travis-ci.org/ManageIQ/optimist)
[![Code Climate](https://codeclimate.com/github/ManageIQ/optimist/badges/gpa.svg)](https://codeclimate.com/github/ManageIQ/optimist)
[![Coverage Status](http://img.shields.io/coveralls/ManageIQ/optimist.svg)](https://coveralls.io/r/ManageIQ/optimist)

## Documentation

- Wiki: http://github.com/ManageIQ/optimist/wiki
- Examples: http://github.com/ManageIQ/optimist/tree/master/examples
- Code quickstart: See `Optimist.options` and then `Optimist::Parser#opt`.

## Description

Optimist is a commandline option parser for Ruby that just gets out of your way.
One line of code per option is all you need to write. For that, you get a nice
automatically-generated help page, robust option parsing, and sensible defaults
for everything you don't specify.

This code is a feature-fork of Optimist: https://github.com/ManageIQ/optimist

See the **Extended Features** section below for the differences/enhancements

## Features

- Simple usage.
- Sensible defaults. No tweaking necessary, much tweaking possible.
- Support for long options, short options, subcommands, and automatic type validation and
  conversion.
- Automatic help message generation, wrapped to current screen width.

## Extended features unavailable in the original Optimist gem

### Parser Settings
- Automatic suggestions whens incorrect options are given
    - disable with `suggestions: false`
    - see example below
- Inexact matching of long arguments
    - disable with `exact_match: true`
    - see example below
- Available prevention of short-arguments by default
    - enable with `explicit_short_opts: true`

### Option Settings

#### Permitted

Permitted options allow specifying valid choices for an option using lists, ranges or regexp's 
- `permitted:` to specify a allow lists, ranges or regexp filtering of options.
- `permitted_response:` can be added to provide more explicit output when incorrect choices are given.
- see [example](examples/permitted.rb)
- concept and code via @akhoury6

#### Alternate named options

Short options can now take be provided as an Array of list of alternate short-option characters.
- `opt :cat, 'desc', short: ['c', 't']`
- Previously `short:` only accepted a single character.

Long options can be given alternate names using `alt:`
- `opt :length, 'desc', alt: ['size']`
- Note that `long: 'othername'` still exists to _override_ the named option and can be used in addition to the alt names.

See [example](examples/alt_names.rb)

### Stringflag option-type

It is useful to allow an option that can be set as a string, used with a default string or unset, especialy in the case of specifying a log-file.  AFAICT this was not possible with the original Optimist.

Example: 

For this option definition:

```ruby
opt :log, "Specify optional logfile", :type => :stringflag, :default => "progname.log"
```

The programmer should use the value of `log_given` in conjunction with the value of `log`
to determine whether to enable logging what what the filename should be.

```sh
$ ./examples/optional_string_arg_type.rb -h
Options:
  -l, --log=<s?>, --no-log    specify optional log-file path (Default: progname.log)
  -h, --help                  Show this message

# Note that when no options are given, :log_given is not set, but the default passes through.
$ ./examples/optional_string_arg_type.rb
{:log=>"progname.log", :help=>false}

$ ./examples/optional_string_arg_type.rb -l
{:log=>"progname.log", :help=>false, :log_given=>true}

# In this case no-log can be used to force a false value into :log
$ ./examples/optional_string_arg_type.rb --no-log
{:log=>false, :help=>false, :log_given=>true}

# Overriding the default case
$ ./examples/optional_string_arg_type.rb --log othername.log
{:log=>"othername.log", :help=>false, :log_given=>true}
```

### Subcommands
"Native" subcommand support - similar to sub-commands in Git.
- See [example](examples/subcommands.rb)
- Ideas borrowed from https://github.com/jwliechty/trollop-subcommands

### Automatic suggestions

Suggestions are formed using the DidYouMean gem, which is part of Ruby 2.3+.  It uses the JaroWinkler and Levenshtein distance to determine when unknown options are within a certain 'distance' of a known option keyword.

```sh
$ ./examples/didyoumean.rb -h
Options:
  -c, --cone       Ice cream cone
  -z, --zippy      It zips
  -a, --zapzy      It zapz
  -b, --big-bug    Madagascar cockroach
  -h, --help       Show this message

# Suggestions for a simple misspelling

$ ./examples/didyoumean.rb --bone
Error: unknown argument '--bone'.  Did you mean: [--cone] ?.
Try --help for help.

# Letter transposition
$ ./examples/didyoumean.rb --ocne
Error: unknown argument '--ocne'.  Did you mean: [--cone] ?.
Try --help for help.

# Accidental plural

$ ./examples/didyoumean.rb --cones
Error: unknown argument '--cones'.  Did you mean: [--cone] ?.
Try --help for help.

# Two close matches, provide two suggestions.

$ ./examples/didyoumean.rb --zipzy
Error: unknown argument '--zipzy'.  Did you mean: [--zippy, --zapzy] ?.
Try --help for help.

# Posix-style options with '-' instead of '_' are a common mistake

$ ./examples/didyoumean.rb --big_bug
Error: unknown argument '--big_bug'.  Did you mean: [--big-bug] ?.
Try --help for help.

# Eventually the input option is too far away from 
# anything we know about so just say we dont understand

$ ./examples/didyoumean.rb --bugblatter-beast
Error: unknown argument '--bugblatter-beast'.
Try --help for help.
```

### Inexact Matching

Similar to Perl's Getopt::Long, partially specified long-options can be used as long as they would unambiguously match a single option.

```sh
$ ./examples/partialmatch.rb -h
Options:
  -a, --apple          An apple
  -p, --apple-sauce    Cooked apple puree
  -t, --atom           Smallest unit of ordinary matter
  -n, --anvil          Heavy metal
  -e, --anteater       Eats ants
  -h, --help           Show this message

# Exact match for 'apple'
$ ./examples/partialmatch.rb --apple
{:apple=>true, :apple_sauce=>false, :atom=>false, :anvil=>false, :anteater=>false, :help=>false, :apple_given=>true}

# Cannot inexact match with 'app', as it partially matches more than one known option
$ ./examples/partialmatch.rb --app
Error: ambiguous option '--app' matched keys (apple,apple-sauce).
Try --help for help.

# Inexact match for 'apple-sauce'
$ ./examples/partialmatch.rb --apple-s
{:apple=>false, :apple_sauce=>true, :atom=>false, :anvil=>false, :anteater=>false, :help=>false, :apple_sauce_given=>true}

# Shortest match for 'anvil'
$ ./examples/partialmatch.rb --anv
{:apple=>false, :apple_sauce=>false, :atom=>false, :anvil=>true, :anteater=>false, :help=>false, :anvil_given=>true}

# Cannot inexact match with 'an', as it partially matches more than one known option
$ ./examples/partialmatch.rb --an
Error: ambiguous option '--an' matched keys (anvil,anteater).
Try --help for help.

# Shortest match for 'atom'
$ ./examples/partialmatch.rb --at
{:apple=>false, :apple_sauce=>false, :atom=>true, :anvil=>false, :anteater=>false, :help=>false, :atom_given=>true}
```

## Requirements

* A burning desire to write less code.
* Ruby 2.3+
    
## Install

* `gem install optimist`

## Synopsis

```ruby
require 'optimist'
opts = Optimist::options do
  opt :monkey, "Use monkey mode"                    # flag --monkey, default false
  opt :name, "Monkey name", :type => :string        # string --name <s>, default nil
  opt :num_limbs, "Number of limbs", :default => 4  # integer --num-limbs <i>, default to 4
end

p opts # a hash: { :monkey=>false, :name=>nil, :num_limbs=>4, :help=>false }
```

## License

Copyright &copy; 2008-2014 [William Morgan](http://masanjin.net/).

Copyright &copy; 2014 Red Hat, Inc.

Copyright &copy; 2019-2020 Ben Bowers

Optimist is released under the [MIT License](http://www.opensource.org/licenses/MIT).
