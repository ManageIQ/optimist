## lib/trollop.rb -- trollop command-line processing library
## Author::    William Morgan (mailto: wmorgan-trollop@masanjin.net)
## Copyright:: Copyright 2007 William Morgan
## License::   GNU GPL version 2

module Trollop

VERSION = "1.0"

class CommandlineError < StandardError; end
class HelpNeeded < StandardError; end
class VersionNeeded < StandardError; end

## regex for floating point numbers
FLOAT_RE = /^-?((\d+(\.\d+)?)|(\.\d+))$/

## regex for parameters
PARAM_RE = /^-(-|\.$|[^\d\.])/ # possible parameter

class Parser
  TYPES = [:flag, :boolean, :bool, :int, :integer, :string, :double, :float]
  attr_reader :leftovers, :specs

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

  def version s=nil;
    if s
      @version = s
      opt :version, "Print version and exit"
    end
    @version
  end
  
  def banner s=nil; @banner = s if s; @banner end

  ## yield successive arg, parameter pairs
  def each_arg args
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

  def parse args
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

  def width
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

  def educate stream=$stdout
    if @banner
      stream.puts wrap(@banner)
    elsif @version
      stream.puts @version
    end

    unless @banner
      stream.puts
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
    stream.printf("  %#{leftcol_width}s:   ", "--help, -h");
  end

  def wrap_line str, opts={}
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

  def wrap str, opts={}
    if str == ""
      [""]
    else
      str.split("\n").map { |s| wrap_line s, opts }.flatten
    end
  end
end

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

def die arg, msg
  $stderr.puts "Error: parameter for option '--#{@p.specs[arg][:long]}' or '-#{@p.specs[arg][:short]}' #{msg}."
  $stderr.puts "Try --help for help."
  exit(-1)
end

module_function :options, :die

end # module
