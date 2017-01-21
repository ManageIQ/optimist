require 'stringio'
require 'test_helper'


module Trollop

  ## cant register this, b/c it doesnt inherit OptBase
  class Foobaz
  end
  ## can register this, but it's missing a #parse method
  class Foobar < Option
  end

  class Foobird < Option
    def parse (optsym, paramlist, _neg)
      paramlist.map do |pg|
        pg.map do |param|
          raise CommandlineError, "option '#{optsym}' needs to have foo in the name" unless param =~ /foo/
          param.sub(/foo/, "FOOBIRD")
        end
      end
    end
  end
  
  class EngineeringNotation < Option
    UNITS = { 'z' => 1e-18, # zepto
              'a' => 1e-15, # atto
              'p' => 1e-12, # pico
              'n' => 1e-9, # nano
              'u' => 1e-6, # micro
              'm' => 1e-3, # milli
              'k' => 1e3, # kilo
              'M' => 1e6, # mega
              'G' => 1e9, # giga
              'T' => 1e12, # tera
              "" => 1,  # unitless
            }
    
    def unitparse (optsym,name)
      matched = name.match( /^
      (?<num> -? ( (\d+(\.\d+)?) | (\.\d+) ) )     # numeric part
      (?<suffix> [a-zA-Z]?)                        # float part
      $/x )
      raise CommandlineError, "option '#{optsym}' must begin with a number and end with an engineering unit (#{UNITS.keys.join(',')})" unless matched
      num, unit_letter = matched[:num], matched[:suffix]
      unit_value = UNITS[unit_letter]
      raise CommandlineError, "option '#{optsym}' has malformatted engineering suffix '#{$2}'" unless unit_value
      return num.to_f * unit_value
    end
    
    def parse (optsym, paramlist, _neg)
      paramlist.map do |pg|
        pg.map do |param|
          unitparse(optsym,param)
        end
      end
    end
  end

  class PosRange < Option
    
    def rangeparse (optsym,name)
      matched = name.match( /^([-]?\d+):([-]?\d+)$/ )
      raise CommandlineError, "option '#{optsym}' must be formatted as #:#" unless matched
      start, finish = $1, $2
      raise CommandlineError, "option '#{optsym}' expecting start value #{start} to be less than finish value #{finish}'" unless start.to_i < finish.to_i
      return [start.to_i, finish.to_i]
    end
    
    def parse (optsym, paramlist, _neg)
      paramlist.map do |pg|
        pg.map do |param|
          rangeparse(optsym, param)
        end
      end
    end
    
    def educate ; "=<i1:i2>" ; end

  end

  class RegistryTest < ::MiniTest::Test

    def setup
      @p = Parser.new
    end

    def parser
      @p ||= Parser.new
    end


    def test_cannot_use_unregisted_types
      assert_raises(ArgumentError) { 
        @p.opt "fooarg", "desc", :type => Foobar
      }
    end

    def test_registered_type_inherits_opttype
      assert_raises(RuntimeError) { 
        Parser.register :foobaz, Foobaz
      }
    end

    def test_registered_type_needs_parse_method
      Parser.register :foobar, Foobar
      @p.opt "fooarg", "desc", :type => :foobar
      assert_raises(NotImplementedError) { 
        @p.parse(%w(--fooarg awesome_foo_bar))
      }
    end
    
    def test_registered_type
      Parser.register :foobird, Foobird
      @p.opt "fooarg", "desc", :type => :foobird

      # test bad argument.
      assert_raises(CommandlineError) { 
        @p.parse(%w(--fooarg awesome_bird))
      }
      # test good argument
      opts = @p.parse(%w(--fooarg awesome_foo))

      # registered type replaces data
      assert_equal opts.fooarg, "awesome_FOOBIRD"
    end

    def test_engineering_notation
      Parser.register :engnot, EngineeringNotation
      @p.opt "hair", "hair width", :type => :engnot
      @p.opt "earth", "earth diameter", :type => :engnot

      opts = @p.parse(%w(--hair 45u --earth 12742.0k ))
      assert_in_epsilon opts.hair, 45.000e-6, 1e-10, 'hair is 45 microns'
      assert_in_epsilon opts.earth, 12.742e6, 1, 'earth is 12742 kilometers'
      # invalid
      assert_raises(CommandlineError) { 
        opts = @p.parse(%w(--ab abcd )) 
      }
      # invalid
      assert_raises(CommandlineError) { 
        opts = @p.parse(%w(--ab 1x1 ))
      }
      # invalid suffix 'e'
      assert_raises(CommandlineError) { 
        opts = @p.parse(%w(--ab 14.0e ))
      }
    end

    def test_positive_range
      Parser.register :posrange, PosRange
      @p.opt "ab", "range as a:b", :type => :posrange

      # range parse, see that it returns array.
      opts = @p.parse(%w(--ab 13:41 ))
      assert_equal opts.ab[0], 13
      assert_equal opts.ab[1], 41

      # see that custom educate string worked
      sio = StringIO.new "w"
      @p.educate sio
      help = sio.string.split "\n"
      assert help[1] =~ /<i1:i2>/, 'expect :posrange type'

      # downcounting range is invalid for this posrange type
      assert_raises(CommandlineError) { 
        opts = @p.parse(%w(--ab 13:7 ))
      }

      # invalid 
      assert_raises(CommandlineError) { 
        opts = @p.parse(%w(--ab baz ))
      }

 
    end
    
  end

end
