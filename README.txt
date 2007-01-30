trollop
    by William Morgan <wmorgan-trollop@masanjin.net>
    http://trollop.rubyforge.org

== DESCRIPTION:

Trollop is YAFCLAP --- yet another fine commandline argument
processing library for Ruby. Trollop is designed to provide the
maximal amount of GNU-style argument processing in the minimum number
of lines of code (for you, the programmer).

Trollop provides a nice automatically-generated help page, robust
option parsing, and sensible defaults for everything you don't
specify.

Trollop: getting you 90% of the way there with only 10% of the effort.

== FEATURES/PROBLEMS:

- Simple usage.
- Sensible defaults. No tweaking necessary, much tweaking possible.
- Support for long options, short options, short option bundling,
  and automatic type validation and conversion.
- Automatic help message generation, wrapped to current screen width.
- Lots of unit tests.

== SYNOPSYS:

  ###### simple ######

  opts = Trollop::options do
    opt :monkey, "Use monkey model."
    opt :goat, "Use goat model.", :default => true
    opt :num_limbs, "Set number of limbs", :default => 4
  end

  p opts

  ###### complex ######

  opts = Trollop::options do
    version "test 1.2.3 (c) 2007 William Morgan"
    banner <<EOS
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
  Trollop::die :file, "must exist" unless File.exists?(opts[:file]) if opts[:file]

== REQUIREMENTS:

* none

== INSTALL:

* gem install trollop

== LICENSE:

Copyright (c) 2007 William Morgan.

Trollop is distributed under the same terms as Ruby.
