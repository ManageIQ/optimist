== trollop

by William Morgan <wmorgan-trollop@masanjin.net>

http://trollop.rubyforge.org

Documentation quickstart: See Trollop::Parser.

== DESCRIPTION

Trollop is a commandline option parser for Ruby that just gets out of your
way. One line of code per option is all you need to write. For that, you get
a nice automatically-generated help page, robust option parsing, command
subcompletion, and sensible defaults for everything you don't specify.

== FEATURES/PROBLEMS

- Dirt-simple usage.
- Sensible defaults. No tweaking necessary, much tweaking possible.
- Support for long options, short options, short option bundling,
  and automatic type validation and conversion.
- Support for subcommands.
- Automatic help message generation, wrapped to current screen width.
- Lots of unit tests.

== SYNOPSIS

  ####################
  ###### simple ######
  ####################

  require 'trollop'
  opts = Trollop::options do
    opt :monkey, "Use monkey mode"
    opt :goat, "Use goat mode", :default => true
    opt :num_limbs, "Set number of limbs", :default => 4
  end

  p opts # { :monkey => false, :goat => true, :num_limbs => 4 }

  ####################
  ###### medium ######
  ####################

  require 'trollop'
  opts = Trollop::options do
    version "test 1.2.3 (c) 2007 William Morgan"
    banner <<-EOS
  Test is an awesome program that does something very, very important.

  Usage:
         test [options] <filenames>+
  where [options] are:
  EOS

    opt :ignore, "Ignore incorrect values"
    opt :file, "Extra data filename to read in, with a very long option description like this one", :type => String
    opt :volume, "Volume level", :default => 3.0
    opt :iters, "Number of iterations", :default => 5
  end
  Trollop::die :volume, "must be non-negative" if opts[:volume] < 0
  Trollop::die :file, "must exist" unless File.exist?(opts[:file]) if opts[:file]
  ################################
  ##### sub-command support ######
  ################################

  require 'trollop'
  global_opts = Trollop::options do
    opt :global_option, "This is a global option"
    stop_on %w(sub-command-1 sub-command-2)
  end

  cmd = ARGV.shift
  cmd_opts = Trollop::options do
    opt :cmd_option, "This is an option only for the subcommand"
  end

  p global_opts
  p cmd
  p cmd_opts

== REQUIREMENTS

* A burning desire to write less code.

== INSTALL

* gem install trollop

== LICENSE

Copyright (c) 2008 William Morgan.

Trollop is distributed under the same terms as Ruby.
