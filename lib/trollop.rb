## lib/trollop.rb -- trollop command-line processing library
## Author::    William Morgan (mailto: wmorgan-trollop@masanjin.net)
## Copyright:: Copyright 2007 William Morgan
## License::   GNU GPL version 2

module Trollop

VERSION = "1.0"

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
  def initialize &b
    @version = nil
    @banner = nil
    @leftovers = []
    @specs = {}
    @long = {}
    @short = {}

    opt :help, "Show this message"
    instance_eval(&b) if b
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
    raise ArgumentError, "you already have an argument named #{name.inspect}" if @specs.member? name

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
    opts[:short] = opts[:short].to_s if opts[:short]
    opts[:short] =
      case opts[:short]
      when nil
        opts[:long].split(//).find { |c| c !~ /[\d]/ && !@short.member?(c) }
      when /^-(.)$/
        $1
      when /^.$/
        opts[:short]
      else
        raise ArgumentError, "invalid short option name #{opts[:long].inspect}"
      end
    raise ArgumentError, "can't generate a short option name (out of characters)" unless opts[:short]
    raise ArgumentError, "short option name #{opts[:short].inspect} is already taken; please specify a (different) :short" if @short[opts[:short]]
    raise ArgumentError, "a short option name can't be a number or a dash" if opts[:short] =~ /[\d-]/

    ## fill in :default for flags
    opts[:default] = false if opts[:type] == :flag && opts[:default].nil?

    opts[:desc] ||= desc
    @short[opts[:short]] = @long[opts[:long]] = name
    @specs[name] = opts
  end

  ## Sets the version string. If set, the user can request the version
  ## on the commandline. Should be of the form "<program name>
  ## <version number>".
  def version s=nil;
    if s
      @version = s
      opt :version, "Print version and exit"
    end
    @version
  end

  ## Sets the banner. If set, this will be printed at the top of the
  ## help display.
  def banner s=nil; @banner = s if s; @banner end

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

  def parse args #:nodoc:
    vals = {}
    required = {}
    found = {}

    @specs.each do |name, opts|
      required[name] = true if opts[:required]
      vals[name] = opts[:default]
    end

    @leftovers = each_arg args do |arg, param|
      raise VersionNeeded if @version && %w(-v --version).include?(arg)
      raise HelpNeeded if %w(-h --help).include?(arg)

      name = 
        case arg
        when /^-([^-])$/
          @short[$1]
        when /^--([^-]\S*)$/
          @long[$1]
        else
          raise CommandlineError, "invalid argument syntax: '#{arg}'"
        end
      raise CommandlineError, "unknown argument '#{arg}'" unless name
      raise CommandlineError, "option '#{arg}' specified multiple times" if found[name]

      found[name] = true
      opts = @specs[name]

      case opts[:type]
      when :flag
        vals[name] = !opts[:default]
        false
      when :int
        raise CommandlineError, "option '#{arg}' needs a parameter" unless param
        raise CommandlineError, "option '#{arg}' needs an integer" unless param =~ /^\d+$/
        vals[name] = param.to_i
        true
      when :float
        raise CommandlineError, "option '#{arg}' needs a parameter" unless param
        raise CommandlineError, "option '#{arg}' needs a floating-point number" unless param =~ FLOAT_RE
        vals[name] = param.to_f
        true
      when :string
        raise CommandlineError, "option '#{arg}' needs a parameter" unless param
        vals[name] = param
        true
      end
    end

    raise CommandlineError, "option '#{required.keys.first}' must be specified" if required.any? { |name, x| !found[name] }
    vals
  end

  def width #:nodoc:
    @width ||= 
      begin
        require 'curses'
        Curses::init_screen
        x = Curses::cols
        Curses::close_screen
        x
      rescue Exception
        80
      end
  end

  ## Print the help message to 'stream'.
  def educate stream=$stdout
    width # just calculate it now; otherwise we have to be careful not to
          # call this unless the cursor's at the beginning of a line.
    if @banner
      stream.puts wrap(@banner)
    elsif @version
      stream.puts
      stream.puts @version
    end

    unless @banner
      stream.puts "Options: "
    end

    specs = @long.keys.sort.map { |longname| @specs[@long[longname]] }
    leftcols = specs.map { |spec| "--#{spec[:long]}, -#{spec[:short]}" }
    leftcol_width = leftcols.map { |s| s.length }.max
    rightcol_start = leftcol_width + 6 # spaces
    specs.each_with_index do |spec, i|
      stream.printf("  %#{leftcol_width}s:   ", leftcols[i]);
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
      stream.puts wrap(desc, :width => width - rightcol_start, :prefix => rightcol_start)
    end
  end

  def wrap_line str, opts={} # :nodoc:
    prefix = opts[:prefix] || 0
    width = opts[:width] || self.width
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
end

## The top-level entry method into Trollop. Creates a Parser object,
## passes the block to it, then parses ARGV with it, handling any
## errors or requests for help or version information appropriately
## (and then exiting). Modifies ARGV in place. Returns a hash of
## option values.
##
## The block passed in should contain one or more calls to #opt
## (Parser#opt), and optionally a call to banner (Parser#banner)
## and a call to version (Parser#version).
##
## See the synopsis in README.txt for examples.
def options &b
  @p = Parser.new(&b)
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

def die arg, msg
  $stderr.puts "Error: parameter for option '--#{@p.specs[arg][:long]}' or '-#{@p.specs[arg][:short]}' #{msg}."
  $stderr.puts "Try --help for help."
  exit(-1)
end

module_function :options, :die

end # module
