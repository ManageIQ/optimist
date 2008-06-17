== trollop

by William Morgan <wmorgan-trollop@masanjin.net>

http://trollop.rubyforge.org

Documentation quickstart: See Trollop::Parser.

== DESCRIPTION

Trollop is YAFCLAP --- yet another fine commandline argument processor
for Ruby. Trollop is designed to provide the maximal amount of GNU-style
argument processing in the minimum number of lines of code (for you, the
programmer).

Trollop provides a nice automatically-generated help page, robust option
parsing, and sensible defaults for everything you don't specify.

Trollop: getting you 90% of the way there with only 10% of the effort.

== FEATURES/PROBLEMS

- Simple usage.
- Sensible defaults. No tweaking necessary, much tweaking possible.
- Support for long options, short options, short option bundling,
  and automatic type validation and conversion.
- Automatic help message generation, wrapped to current screen width.
- Lots of unit tests.

== SYNOPSIS

  ###### simple ######

  require 'trollop'
  opts = Trollop::options do
    opt :monkey, "Use monkey mode"
    opt :goat, "Use goat mode", :default => true
    opt :num_limbs, "Set number of limbs", :default => 4
  end

  p opts

  ###### medium ######

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

  ##### sub-command support ######

  require 'trollop'
  global_opts = Trollop::options do
    opt :global_option, "This is a global option"
    stop_on %w(sub-command-1 sub-command-2)
  end

  cmd = ARGV.shift
  cmd_opts = Trollop::options do
    opt :cmd_option, "This is an option only for the subcommand"
  end

  puts "global: #{global_opts.inspect}, cmd: #{cmd.inspect}, cmd options: #{cmd_opts.inspect}"

== REQUIREMENTS

* none!

== INSTALL

* gem install trollop

== LICENSE

Copyright (c) 2008 William Morgan.

Trollop is distributed under the same terms as Ruby.
