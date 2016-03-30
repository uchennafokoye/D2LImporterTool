require 'optparse'
require 'optparse/range'
require 'ostruct'
require 'pp'
require 'byebug'
require './csv_converter_helpers'


class ParseQuizToCSV

  include CSVConverterHelpers
  attr_reader :options

  def initialize args
    @options = ParseQuizToCSV.parse(args)
  end

  def self.defaultOptions
    options = OpenStruct.new
    options.auto = true
    options.prefix = 'ch'
    options.suffix_range = ('1'..'24')
    options.folders = ['conceptual', 'cpa', 'computational', 'ifrs', 'eps-computational', 'dilutive-computational', 'dilutive-conceptual', 'dilutive-cpa', 'eps-computational', 'eps-conceptual', 'eps-cpa']
    options.answers_file = 'answers.csv'
    options.questions_file = 'questions.txt'
    options.root_dir = '/Users/faithfulokoye/Sites/Work/ACC_541/data_copy'
    options
  end

  # ruby parse_quiz_to_csv.rb --auto
  # ruby parse_quiz_to_csv.rb --no-auto
  def self.parse(args)
    options = OpenStruct.new
    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: parse_quiz_to_csv.rb [options]"
      opts.separator ""

      opts.on("--auto", "--[no-]auto", "This needs to be the first argument ie. example.rb --auto -f 'conceptual, tennis'") do |auto|
        if auto
          options = defaultOptions
        end
      end

      opts.on("-r", "--rootdir DIR", "Relative path to Root Directory") do |dir|
        if (dir.empty?)
          puts "Please provide a directory. Use '.' for current dir"
          exit
        end
        options.root_dir = dir
      end

      opts.on("-p", "--prefix [PREFIX]", "To remove default prefix, call -p with empty space. Indicate the prefix directory housing the q/a files if other than root dir. Prefix folders are found directly within root dir. Prefix will be incremented to get all folders. Example: 'ch' for 'ch1'..'ch10'") do |prefix|
        options.prefix = prefix
        options.suffix_range = (prefix) ? options.suffix : nil
      end

      opts.on("--suffix-range [RANGE]", OptionParser::DecimalIntegerRange, "For example, (1-10). Appended to prefix to get names of all folders in root dir. Eg. for range 2-10 and prefix: ch., prefix folders: ch2, ch3..ch10") do |range|
        unless options.prefix
          puts "Please set prefix before suffix"
          exit
        end
        options.suffix_range = range
      end


      opts.on("--folders 'x, y, z'", Array, "Names of folders housing the questions/answers if other than the root dir or prefix dir e.g. 'housing, democracy'. If you provided a prefix, this folder would be found within that prefix. Eg. ch1 -> housing") do |folders|
        options.folders = folders
      end

      opts.on("-q", "--questionfile FILENAME", "Default is questions.txt. Has to be a txt file") do |filename|
        unless (File.extname(filename) == '.txt')
          puts "Please provide a txt file"
          exit
        end
        options.questions_file = filename
      end

      opts.on("-a", "--answerfile FILENAME", "Default is answers.csv. Has to be a csv file") do |filename|
        unless (File.extname(filename) == '.csv')
          puts "Please provide a csv file"
          exit
        end
        options.answers_file = filename
      end

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end

    opt_parser.parse!(args)
    options
  end

  def parse_to_csv

    self.directories.each do | directory |
      unless File.exist? directory
        next
      end
      puts "Working on #{directory}"
      puts "Working on answers..."
      CSVConverterHelpers.convert_answers_to_yaml filename: "#{directory}/#{options.answers_file}"
      puts "Done with answers for #{directory}"
      puts "Working on questions.."
      CSVConverterHelpers.convert_questions_to_yaml filename: "#{directory}/#{options.questions_file}"
      puts "Done with questions for #{directory}"

      puts "Converting to D2L Format"
      CSVConverterHelpers.convertD2LCSVFormat dir: "#{directory}"
      puts "Done with converting to D2L Format for #{directory}"

    end

  end

  def directories
    if (options.root_dir.nil?)
      raise "Error: No root directory provided"
    end
    if (options.prefix && options.suffix_range.nil?)
      raise "Has prefix but no suffix"
    end
    if (options.prefix.nil? && options.suffix_range)
      raise "Has suffix but no prefix"
    end

    root = options.root_dir
    prefix = options.prefix
    suffix_range = options.suffix_range
    folders = options.folders

    get_directories root, prefix, suffix_range, folders
  end


  private

  def each_suffix_block root, prefix, suffix_range
      suffix_range.map do |suffix|
        string = (root + '/' + prefix + suffix.to_s + '/')
        if block_given?
          yield string
        end
      end
  end

  def append_to_folders prefix, folders
    folders.map do |folder|
      prefix + folder
    end
  end


  def get_directories root, prefix, suffix_range, folders
    directories = []
    if (prefix && !folders.empty?)
      directories = each_suffix_block root, prefix, suffix_range do |prefix|
        append_to_folders prefix, folders
      end
    end
    if (prefix && folders.empty?)
      directories = each_suffix_block root, prefix, suffix_range
    end
    if (!prefix && !folders.empty?)
      directories = append_to_folders root, folders
    end
    if (!prefix && folders.empty?)
      directories = root.split()
    end
    directories.flatten()
  end


end

options = ParseQuizToCSV.new(ARGV)
options.parse_to_csv
pp options.directories
pp options