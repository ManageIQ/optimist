## lib/trollop.rb -- trollop command-line processing library
## Author::    William Morgan (mailto: wmorgan-trollop@masanjin.net)
## Copyright:: Copyright 2007 William Morgan
## License::   GNU GPL version 2

module Trollop

VERSION = "1.9"

## Thrown by Parser in the event of a commandline error. Not needed if
## you're using the Trollop::options entry.
class CommandlineError < StandardError; end
  
## Thrown by Parser if the user passes in '-h' or '--help'. Handled
## automatically by Trollop#options.
class HelpNeeded < StandardError; end

## Thrown by Parser if the user passes in '-h' or '--version'. Handled
## automatically by Trollop#options.
class VersionNeeded < StandardError; end

## Regex for floating point numbers
FLOAT_RE = /^-?((\d+(\.\d+)?)|(\.\d+))$/

## Regex for parameters
PARAM_RE = /^-(-|\.$|[^\d\.])/

## The commandline parser. In typical usage, the methods in this class
## will be handled internally by Trollop#options, in which case only the
## methods #opt, #banner and #version, #depends, and #conflicts will
## typically be called.
class Parser

  ## The set of values that indicate a flag type of option when one of
  ## the values is given to the :type parameter to #opt.
  FLAG_TYPES = [:flag, :bool, :boolean]

  ## The set of values that indicate an option that takes a single
  ## parameter when one of the values is given to the :type parameter to
  ## #opt.
  SINGLE_ARG_TYPES = [:int, :integer, :string, :double, :float]

  ## The set of values that indicate an option that takes multiple
  ## parameters when one of the values is given to the :type parameter to
  ## #opt.
  MULTI_ARG_TYPES = [:ints, :integers, :strings, :doubles, :floats]

  ## The set of values specifiable as the :type parameter to #opt.
  TYPES = FLAG_TYPES + SINGLE_ARG_TYPES + MULTI_ARG_TYPES

  INVALID_SHORT_ARG_REGEX = /[\d-]/ #:nodoc:

  ## The values from the commandline that were not interpreted by #parse.
  attr_reader :leftovers

  ## The complete configuration hashes for each option. (Mainly useful
  ## for testing.)
  attr_reader :specs

  ## Initializes the parser, and instance-evaluates any block given.
  def initialize *a, &b
    @version = nil
    @leftovers = []
    @specs = {}
    @long = {}
    @short = {}
    @order = []
    @constraints = []
    @stop_words = []
    @stop_on_unknown = false

    #instance_eval(&b) if b # can't take arguments
    cloaker(&b).bind(self).call(*a) if b
  end

  ## Add an option. 'name' is the argument name, a unique identifier
  ## for the option that you will use internally. 'desc' a string
  ## description which will be displayed in help messages. Takes the
  ## following optional arguments:
  ##
  ## * :long: Specify the long form of the argument, i.e. the form
  ##   with two dashes. If unspecified, will be automatically derived
  ##   based on the argument name.
  ## * :short: Specify the short form of the argument, i.e. the form
  ##   with one dash. If unspecified, will be automatically derived
  ##   based on the argument name.
  ## * :type: Require that the argument take a parameter or parameters
  ##   of type 'type'. For a single parameter, the value can be a
  ##   member of the SINGLE_ARG_TYPES constant or a corresponding class
  ##   (e.g. Integer for :int). For multiple parameters, the value can
  ##   be a member of the MULTI_ARG_TYPES constant. If unset, the
  ##   default argument type is :flag, meaning that the argument does
  ##   not take a parameter. The specification of :type is not
  ##   necessary if :default is given.
  ## * :default: Set the default value for an argument. Without a
  ##   default value, the hash returned by #parse (and thus
  ##   Trollop#options) will not contain the argument unless it is
  ##   given on the commandline. The argument type is derived
  ##   automatically from the class of the default value given, if
  ##   any. Specifying a :flag argument on the commandline whose
  ##   default value is true will change its value to false.
  ## * :required: If set to true, the argument must be provided on the
  ##   commandline.
  ## * :multi: If set to true, allows multiple instances of the
  ##   option. Otherwise, only a single instance of the option is
  ##   allowed.
  def opt name, desc="", opts={}
    raise ArgumentError, "you already have an argument named '#{name}'" if @specs.member? name

    ## fill in :type
    opts[:type] = 
      case opts[:type]
      when :flag, :boolean, :bool; :flag
      when :int, :integer; :int
      when :ints, :integers; :ints
      when :string; :string
      when :strings; :strings
      when :double, :float; :float
      when :doubles, :floats; :floats
      when Class
        case opts[:type].to_s # sigh... there must be a better way to do this
        when 'TrueClass', 'FalseClass'; :flag
        when 'String'; :string
        when 'Integer'; :int
        when 'Float'; :float
        else
          raise ArgumentError, "unsupported argument type '#{opts[:type].class.name}'"
        end
      when nil; nil
      else
        raise ArgumentError, "unsupported argument type '#{opts[:type]}'" unless TYPES.include?(opts[:type])
      end

    type_from_default =
      case opts[:default]
      when Integer; :int
      when Numeric; :float
      when TrueClass, FalseClass; :flag
      when String; :string
      when Array
        if opts[:default].empty?
          raise ArgumentError, "multiple argument type cannot be deduced from an empty array for '#{opts[:default][0].class.name}'"
        end
        case opts[:default][0]    # the first element determines the types
        when Integer; :ints
        when Numeric; :floats
        when String; :strings
        else
          raise ArgumentError, "unsupported multiple argument type '#{opts[:default][0].class.name}'"
        end
      when nil; nil
      else
        raise ArgumentError, "unsupported argument type '#{opts[:default].class.name}'"
      end

    raise ArgumentError, ":type specification and default type don't match" if opts[:type] && type_from_default && opts[:type] != type_from_default

    opts[:type] = (opts[:type] || type_from_default || :flag)

    ## fill in :long
    opts[:long] = opts[:long] ? opts[:long].to_s : name.to_s.gsub("_", "-")
    opts[:long] =
      case opts[:long]
      when /^--([^-].*)$/
        $1
      when /^[^-]/
        opts[:long]
      else
        raise ArgumentError, "invalid long option name #{opts[:long].inspect}"
      end
    raise ArgumentError, "long option name #{opts[:long].inspect} is already taken; please specify a (different) :long" if @long[opts[:long]]

    ## fill in :short
    opts[:short] = opts[:short].to_s if opts[:short] unless opts[:short] == :none
    opts[:short] =
      case opts[:short]
      when nil
        c = opts[:long].split(//).find { |c| c !~ INVALID_SHORT_ARG_REGEX && !@short.member?(c) }
        raise ArgumentError, "can't generate a short option name for #{opts[:long].inspect}: out of unique characters" unless c
        c
      when /^-(.)$/
        $1
      when /^.$/
        opts[:short]
      when :none
        nil
      else
        raise ArgumentError, "invalid short option name '#{opts[:short].inspect}'"
      end
    if opts[:short]
      raise ArgumentError, "short option name #{opts[:short].inspect} is already taken; please specify a (different) :short" if @short[opts[:short]]
      raise ArgumentError, "a short option name can't be a number or a dash" if opts[:short] =~ INVALID_SHORT_ARG_REGEX
    end

    ## fill in :default for flags
    opts[:default] = false if opts[:type] == :flag && opts[:default].nil?

    ## fill in :multi
    opts[:multi] ||= false

    opts[:desc] ||= desc
    @long[opts[:long]] = name
    @short[opts[:short]] = name if opts[:short]
    @specs[name] = opts
    @order << [:opt, name]
  end

  ## Sets the version string. If set, the user can request the version
  ## on the commandline. Should be of the form "<program name>
  ## <version number>".
  def version s=nil; @version = s if s; @version end

  ## Adds text to the help display.
  def banner s; @order << [:text, s] end
  alias :text :banner

  ## Marks two (or more!) options as requiring each other. Only handles
  ## undirected (i.e., mutual) dependencies. Directed dependencies are
  ## better modeled with Trollop::die.
  def depends *syms
    syms.each { |sym| raise ArgumentError, "unknown option '#{sym}'" unless @specs[sym] }
    @constraints << [:depends, syms]
  end
  
  ## Marks two (or more!) options as conflicting.
  def conflicts *syms
    syms.each { |sym| raise ArgumentError, "unknown option '#{sym}'" unless @specs[sym] }
    @constraints << [:conflicts, syms]
  end

  ## Defines a set of words which cause parsing to terminate when encountered,
  ## such that any options to the left of the word are parsed as usual, and
  ## options to the right of the word are left intact.
  ##
  ## A typical use case would be for subcommand support, where these would be
  ## set to the list of subcommands. A subsequent Trollop invocation would
  ## then be used to parse subcommand options.
  def stop_on *words
    @stop_words = [*words].flatten
  end

  ## Similar to stop_on, but stops on any unknown word when encountered (unless
  ## it is a parameter for an argument).
  def stop_on_unknown
    @stop_on_unknown = true
  end

  ## yield successive arg, parameter pairs
  def each_arg args # :nodoc:
    remains = []
    i = 0

    until i >= args.length
      if @stop_words.member? args[i]
        remains += args[i .. -1]
        return remains
      end
      case args[i]
      when /^--$/ # arg terminator
        remains += args[(i + 1) .. -1]
        return remains
      when /^--(\S+?)=(\S+)$/ # long argument with equals
        yield "--#{$1}", [$2]
        i += 1
      when /^--(\S+)$/ # long argument
        params = collect_argument_parameters(args, i + 1)
        unless params.empty?
          num_params_taken = yield args[i], params
          unless num_params_taken
            if @stop_on_unknown
              remains += args[i + 1 .. -1]
              return remains
            else
              remains += params
            end
          end
          i += 1 + num_params_taken
        else # long argument no parameter
          yield args[i], nil
          i += 1
        end
      when /^-(\S+)$/ # one or more short arguments
        shortargs = $1.split(//)
        shortargs.each_with_index do |a, j|
          if j == (shortargs.length - 1)
            params = collect_argument_parameters(args, i + 1)
            unless params.empty?
              num_params_taken = yield "-#{a}", params
              unless num_params_taken
                if @stop_on_unknown
                  remains += args[i + 1 .. -1]
                  return remains
                else
                  remains += params
                end
              end
              i += 1 + num_params_taken
            else # argument no parameter
              yield "-#{a}", nil
              i += 1
            end
          else
            yield "-#{a}", nil
          end
        end
      else
        if @stop_on_unknown
          remains += args[i .. -1]
          return remains
        else
          remains << args[i]
          i += 1
        end
      end
    end

    remains
  end

  def parse cmdline #:nodoc:
    vals = {}
    required = {}

    opt :version, "Print version and exit" if @version unless @specs[:version] || @long["version"]
    opt :help, "Show this message" unless @specs[:help] || @long["help"]

    @specs.each do |sym, opts|
      required[sym] = true if opts[:required]
      vals[sym] = opts[:default]
    end

    ## resolve symbols
    given_args = {}
    @leftovers = each_arg cmdline do |arg, params|
      sym = 
        case arg
        when /^-([^-])$/
          @short[$1]
        when /^--([^-]\S*)$/
          @long[$1]
        else
          raise CommandlineError, "invalid argument syntax: '#{arg}'"
        end
      raise CommandlineError, "unknown argument '#{arg}'" unless sym

      if given_args.include?(sym) && !@specs[sym][:multi]
        raise CommandlineError, "option '#{arg}' specified multiple times"
      end

      given_args[sym] ||= {}

      given_args[sym][:arg] = arg
      given_args[sym][:params] ||= []

      # The block returns the number of parameters taken.
      num_params_taken = 0

      unless params.nil?
        if SINGLE_ARG_TYPES.include?(@specs[sym][:type])
          given_args[sym][:params] << params[0, 1]  # take the first parameter
          num_params_taken = 1
        elsif MULTI_ARG_TYPES.include?(@specs[sym][:type])
          given_args[sym][:params] << params        # take all the parameters
          num_params_taken = params.size
        end
      end

      num_params_taken
    end

    ## check for version and help args
    raise VersionNeeded if given_args.include? :version
    raise HelpNeeded if given_args.include? :help

    ## check constraint satisfaction
    @constraints.each do |type, syms|
      constraint_sym = syms.find { |sym| given_args[sym] }
      next unless constraint_sym

      case type
      when :depends
        syms.each { |sym| raise CommandlineError, "--#{@specs[constraint_sym][:long]} requires --#{@specs[sym][:long]}" unless given_args.include? sym }
      when :conflicts
        syms.each { |sym| raise CommandlineError, "--#{@specs[constraint_sym][:long]} conflicts with --#{@specs[sym][:long]}" if given_args.include?(sym) && (sym != constraint_sym) }
      end
    end

    required.each do |sym, val|
      raise CommandlineError, "option '#{sym}' must be specified" unless given_args.include? sym
    end

    ## parse parameters
    given_args.each do |sym, given_data|
      arg = given_data[:arg]
      params = given_data[:params]

      opts = @specs[sym]
      raise CommandlineError, "option '#{arg}' needs a parameter" if params.empty? && opts[:type] != :flag

      case opts[:type]
      when :flag
        vals[sym] = !opts[:default]
      when :int, :ints
        vals[sym] = params.map { |pg| pg.map { |p| parse_integer_parameter p, arg } }
      when :float, :floats
        vals[sym] = params.map { |pg| pg.map { |p| parse_float_parameter p, arg } }
      when :string, :strings
        vals[sym] = params.map { |pg| pg.map { |p| p.to_s } }
      end

      if SINGLE_ARG_TYPES.include?(opts[:type])
        unless opts[:multi]       # single parameter
          vals[sym] = vals[sym][0][0]
        else                      # multiple options, each with a single parameter
          vals[sym] = vals[sym].map { |p| p[0] }
        end
      elsif MULTI_ARG_TYPES.include?(opts[:type]) && !opts[:multi]
        vals[sym] = vals[sym][0]  # single option, with multiple parameters
      end
      # else: multiple options, with multiple parameters
    end

    vals
  end

  def parse_integer_parameter param, arg #:nodoc:
    raise CommandlineError, "option '#{arg}' needs an integer" unless param =~ /^\d+$/
    param.to_i
  end

  def parse_float_parameter param, arg #:nodoc:
    raise CommandlineError, "option '#{arg}' needs a floating-point number" unless param =~ FLOAT_RE
    param.to_f
  end

  def collect_argument_parameters args, start_at #:nodoc:
    params = []
    pos = start_at
    while args[pos] && args[pos] !~ PARAM_RE && !@stop_words.member?(args[pos]) do
      params << args[pos]
      pos += 1
    end
    params
  end

  def width #:nodoc:
    @width ||= 
      if $stdout.tty?
        if `stty size` =~ /^(\d+) (\d+)$/
          $2.to_i
        else
          begin
            require 'curses'
            Curses::init_screen
            x = Curses::cols
            Curses::close_screen
            x
          rescue Exception
          end
        end
      end || 80
  end

  ## Print the help message to 'stream'.
  def educate stream=$stdout
    width # just calculate it now; otherwise we have to be careful not to
          # call this unless the cursor's at the beginning of a line.

    left = {}
    @specs.each do |name, spec| 
      left[name] = "--#{spec[:long]}" +
        (spec[:short] ? ", -#{spec[:short]}" : "") +
        case spec[:type]
        when :flag; ""
        when :int; " <i>"
        when :ints; " <i+>"
        when :string; " <s>"
        when :strings; " <s+>"
        when :float; " <f>"
        when :floats; " <f+>"
        end
    end

    leftcol_width = left.values.map { |s| s.length }.max || 0
    rightcol_start = leftcol_width + 6 # spaces

    unless @order.size > 0 && @order.first.first == :text
      stream.puts "#@version\n" if @version
      stream.puts "Options:"
    end

    @order.each do |what, opt|
      if what == :text
        stream.puts wrap(opt)
        next
      end

      spec = @specs[opt]
      stream.printf "  %#{leftcol_width}s:   ", left[opt]
      desc = spec[:desc] + 
        if spec[:default]
          if spec[:desc] =~ /\.$/
            " (Default: #{spec[:default]})"
          else
            " (default: #{spec[:default]})"
          end
        else
          ""
        end
      stream.puts wrap(desc, :width => width - rightcol_start - 1, :prefix => rightcol_start)
    end
  end

  def wrap_line str, opts={} # :nodoc:
    prefix = opts[:prefix] || 0
    width = opts[:width] || (self.width - 1)
    start = 0
    ret = []
    until start > str.length
      nextt = 
        if start + width >= str.length
          str.length
        else
          x = str.rindex(/\s/, start + width)
          x = str.index(/\s/, start) if x && x < start
          x || str.length
        end
      ret << (ret.empty? ? "" : " " * prefix) + str[start ... nextt]
      start = nextt + 1
    end
    ret
  end

  def wrap str, opts={} # :nodoc:
    if str == ""
      [""]
    else
      str.split("\n").map { |s| wrap_line s, opts }.flatten
    end
  end

  ## instance_eval but with ability to handle block arguments
  ## thanks to why: http://redhanded.hobix.com/inspect/aBlockCostume.html
  def cloaker &b #:nodoc:
    (class << self; self; end).class_eval do
      define_method :cloaker_, &b
      meth = instance_method :cloaker_
      remove_method :cloaker_
      meth
    end
  end
end

## The top-level entry method into Trollop. Creates a Parser object,
## passes the block to it, then parses +args+ with it, handling any
## errors or requests for help or version information appropriately
## (and then exiting). Modifies +args+ in place. Returns a hash of
## option values.
##
## The block passed in should contain one or more calls to #opt
## (Parser#opt), one or more calls to text (Parser#text), and
## probably a call to version (Parser#version).
##
## See the synopsis in README.txt for examples.
def options args = ARGV, *a, &b
  @p = Parser.new(*a, &b)
  begin
    vals = @p.parse args
    args.clear
    @p.leftovers.each { |l| args << l }
    vals
  rescue CommandlineError => e
    $stderr.puts "Error: #{e.message}."
    $stderr.puts "Try --help for help."
    exit(-1)
  rescue HelpNeeded
    @p.educate
    exit
  rescue VersionNeeded
    puts @p.version
    exit
  end
end

## Informs the user that their usage of 'arg' was wrong, as detailed by
## 'msg', and dies. Example:
##
##   options do
##     opt :volume, :default => 0.0
##   end
##
##   die :volume, "too loud" if opts[:volume] > 10.0
##   die :volume, "too soft" if opts[:volume] < 0.1
##
## In the one-argument case, simply print that message, a notice
## about -h, and die. Example:
##
##   options do
##     opt :whatever # ...
##   end
##
##   Trollop::die "need at least one filename" if ARGV.empty?
def die arg, msg=nil
  if msg
    $stderr.puts "Error: argument --#{@p.specs[arg][:long]} #{msg}."
  else
    $stderr.puts "Error: #{arg}."
  end
  $stderr.puts "Try --help for help."
  exit(-1)
end

module_function :options, :die

end # module
