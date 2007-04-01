## lib/trollop.rb -- trollop command-line processing library
## Author::    William Morgan (mailto: wmorgan-trollop@masanjin.net)
## Copyright:: Copyright 2007 William Morgan
## License::   GNU GPL version 2

module Trollop

VERSION = "1.6"

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
## will be handled internally by Trollop#options, in which case only
## the methods #opt, #banner and #version will be called.
class Parser
  ## The set of values specifiable as the :type parameter to #opt.
  TYPES = [:flag, :boolean, :bool, :int, :integer, :string, :double, :float]

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
  ## * :type: Require that the argument take a parameter of type
  ##   'type'. Can by any member of the TYPES constant or a
  ##   corresponding class (e.g. Integer for :int). If unset, the
  ##   default argument type is :flag, meaning the argument does not
  ##   take a parameter. Not necessary if :default: is specified.
  ## * :default: Set the default value for an argument. Without a
  ##   default value, the hash returned by #parse (and thus
  ##   Trollop#options) will not contain the argument unless it is
  ##   given on the commandline. The argument type is derived
  ##   automatically from the class of the default value given, if
  ##   any. Specifying a :flag argument on the commandline whose
  ##   default value is true will change its value to false.
  ## * :required: if set to true, the argument must be provided on the
  ##   commandline.
  def opt name, desc="", opts={}
    raise ArgumentError, "you already have an argument named '#{name}'" if @specs.member? name

    ## fill in :type
    opts[:type] = 
      case opts[:type]
      when :flag, :boolean, :bool: :flag
      when :int, :integer: :int
      when :string: :string
      when :double, :float: :float
      when Class
        case opts[:type].to_s # sigh... there must be a better way to do this
        when 'TrueClass', 'FalseClass': :flag
        when 'String': :string
        when 'Integer': :int
        when 'Float': :float
        else
          raise ArgumentError, "unsupported argument type '#{opts[:type].class.name}'"
        end
      when nil: nil
      else
        raise ArgumentError, "unsupported argument type '#{opts[:type]}'" unless TYPES.include?(opts[:type])
      end

    type_from_default =
      case opts[:default]
      when Integer: :int
      when Numeric: :float
      when TrueClass, FalseClass: :flag
      when String: :string
      when nil: nil
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
        c = opts[:long].split(//).find { |c| c !~ /[\d]/ && !@short.member?(c) }
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
      raise ArgumentError, "a short option name can't be a number or a dash" if opts[:short] =~ /[\d-]/
    end

    ## fill in :default for flags
    opts[:default] = false if opts[:type] == :flag && opts[:default].nil?

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

  ## Marks two (or more!) options as requiring each other. Only
  ## handles undirected dependcies. Directed dependencies are better
  ## modeled with #die.
  def depends *syms
    syms.each { |sym| raise ArgumentError, "unknown option '#{sym}'" unless @specs[sym] }
    @constraints << [:depends, syms]
  end
  
  ## Marks two (or more!) options as conflicting.
  def conflicts *syms
    syms.each { |sym| raise ArgumentError, "unknown option '#{sym}'" unless @specs[sym] }
    @constraints << [:conflicts, syms]
  end

  ## yield successive arg, parameter pairs
  def each_arg args # :nodoc:
    remains = []
    i = 0

    until i >= args.length
      case args[i]
      when /^--$/ # arg terminator
        remains += args[(i + 1) .. -1]
        break
      when /^--(\S+?)=(\S+)$/ # long argument with equals
        yield "--#{$1}", $2
        i += 1
      when /^--(\S+)$/ # long argument
        if args[i + 1] && args[i + 1] !~ PARAM_RE
          remains << args[i + 1] unless yield args[i], args[i + 1]
          i += 2
        else # long argument no parameter
          yield args[i], nil
          i += 1
        end
      when /^-(\S+)$/ # one or more short arguments
        shortargs = $1.split(//)
        shortargs.each_with_index do |a, j|
          if j == (shortargs.length - 1) && args[i + 1] && args[i + 1] !~ PARAM_RE
            remains << args[i + 1] unless yield "-#{a}", args[i + 1]
            i += 1 # once more below
          else
            yield "-#{a}", nil
          end
        end
        i += 1
      else
        remains << args[i]
        i += 1
      end
    end
    remains
  end

  def parse cmdline #:nodoc:
    vals = {}
    required = {}
    found = {}

    opt :version, "Print version and exit" if @version unless @specs[:version] || @long["version"]
    opt :help, "Show this message" unless @specs[:help] || @long["help"]

    @specs.each do |sym, opts|
      required[sym] = true if opts[:required]
      vals[sym] = opts[:default]
    end

    ## resolve symbols
    args = []
    @leftovers = each_arg cmdline do |arg, param|
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
      raise CommandlineError, "option '#{arg}' specified multiple times" if found[sym]
      args << [sym, arg, param]
      found[sym] = true

      @specs[sym][:type] != :flag # take params on all except flags
    end

    ## check for version and help args
    raise VersionNeeded if args.any? { |sym, *a| sym == :version }
    raise HelpNeeded if args.any? { |sym, *a| sym == :help }

    ## check constraint satisfaction
    @constraints.each do |type, syms|
      constraint_sym = syms.find { |sym| found[sym] }
      next unless constraint_sym

      case type
      when :depends
        syms.each { |sym| raise CommandlineError, "--#{@long[constraint_sym]} requires --#{@long[sym]}" unless found[sym] }
      when :conflicts
        syms.each { |sym| raise CommandlineError, "--#{@long[constraint_sym]} conflicts with --#{@long[sym]}" if found[sym] && sym != constraint_sym }
      end
    end

    raise CommandlineError, "option '#{required.keys.first}' must be specified" if required.any? { |sym, x| !found[sym] }

    ## parse parameters
    args.each do |sym, arg, param|
      opts = @specs[sym]

      raise CommandlineError, "option '#{arg}' needs a parameter" unless param || opts[:type] == :flag

      case opts[:type]
      when :flag
        vals[sym] = !opts[:default]
      when :int
        raise CommandlineError, "option '#{arg}' needs an integer" unless param =~ /^\d+$/
        vals[sym] = param.to_i
      when :float
        raise CommandlineError, "option '#{arg}' needs a floating-point number" unless param =~ FLOAT_RE
        vals[sym] = param.to_f
      when :string
        vals[sym] = param.to_s
      end
    end

    vals
  end

  def width #:nodoc:
    @width ||= 
      if $stdout.tty?
        begin
          require 'curses'
          Curses::init_screen
          x = Curses::cols
          Curses::close_screen
          x
        rescue Exception
          80
        end
      else
        80
      end
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
        when :flag
          ""
        when :int
          " <i>"
        when :string
          " <s>"
        when :float
          " <f>"
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
## passes the block to it, then parses ARGV with it, handling any
## errors or requests for help or version information appropriately
## (and then exiting). Modifies ARGV in place. Returns a hash of
## option values.
##
## The block passed in should contain one or more calls to #opt
## (Parser#opt), one or more calls to text (Parser#text), and
## probably a call to version (Parser#version).
##
## See the synopsis in README.txt for examples.
def options *a, &b
  @p = Parser.new(*a, &b)
  begin
    vals = @p.parse ARGV
    ARGV.clear
    @p.leftovers.each { |l| ARGV << l }
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
