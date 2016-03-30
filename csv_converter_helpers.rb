require 'byebug'
require 'csv'
require './answer'
require './multiple_choice'
require './d2l_csv_factory'

module CSVConverterHelpers

  include D2lCsvFactory::NamingConfig

  def self.convert_answers_to_yaml filename: filename, options: {}

    newfile = options[:newfile] || "#{File.dirname(filename)}/answers.yml"
    File.open(newfile, "w") do | file |
      hash = {}
      CSV.foreach(filename) do | row |
        if $. == 1 then
          next
        end

        index = row[0]
        correct_answer = row[1]

        if (index.nil? || correct_answer.nil?)
          next
        end

        answer = Answer.new(index,correct_answer)
        hash.merge! answer.to_hash
      end

      file.write hash.to_yaml
    end
  end

  def self.convert_questions_to_yaml(filename:filename, options: {})
    newfile = options[:newfile] || "#{File.dirname(filename)}/questions.yml"
    File.open(newfile, "w") do |file|
      hash = {}
      get_paragraphs(filename).map do | paragraph |
        index = get_question_no paragraph
        question = remove_question_no get_question(paragraph)
        answer_options = get_options paragraph
        mc = MultipleChoice.new(index, question, answer_options)
        hash.merge! mc.to_hash
      end
      file.write hash.to_yaml
    end

  end


  #This would output a file in the format needed for the D2L Question Importer Tool
  #Future Build for the Actual CSV Format for D2L Importer
  def self.d2lConverterFormat dir: dir, options: {}

    answer_file = "#{dir}/answers.yml"
    question_file = "#{dir}/questions.yml"

    answers = YAML::load_file(answer_file)
    questions = YAML::load_file(question_file)

    text_builder = ""

    questions.each do | key, value|
      answer = answers.fetch(key)
      answer_options = value[:answer_options]
      text_builder = text_builder + value[:get_question] + astericizeAnswerOptions(answer_options, answer) + "\n"
    end

    newfile = options[:newfile] || "#{dir}/converter_format.txt"

    File.open(newfile, "w") do |file|
      file.write text_builder
    end

  end

  #This would output the official csv format to directly import to d2l
  def self.convertD2LCSVFormat dir: dir, options: {}

    answer_file = "#{dir}/answers.yml"
    question_file = "#{dir}/questions.yml"

    answers = YAML::load_file(answer_file)
    questions = YAML::load_file(question_file)

    factories = questions.map do | key, value|
      answer = answers.fetch(key)
      answer_options = value[:answer_options]
      question_text = value[:get_question]
      D2lCsvFactory.make_factory(question_text, answer, answer_options)
    end

    factories_to_csv factories, dir
  end


  private


  #answer_options built as a string with an asterisk in the beginning of the correct answer
  #useful for D2L Question Importer Tool that helps convert txt files to D2L CSV files
    def self.astericizeAnswerOptions answer_options, answer

      answer_options.map do |key, value|
        (key == answer) ? "*#{value}" : value
      end.join

    end



    #get question no
    def self.get_question_no paragraph
      paragraph[0].match(/(^\d+(?=\.))/)[0].to_i
    end

    #get option alphabet no
    def self.get_option_alphabet option
      option.match(/(^[^\d\s\.](?=\.))/)[0]
    end

    #Remove question no
    def self.remove_question_no question
      question.sub(/(^\d+(?:\.)\s+)/, '')
    end

    #Remove option alphabet no
    def self.remove_option_alphabet option
      option.gsub(/(^[^\d\s\.](?:\.)\s+)/, '')
    end

    #get question paragraph
    #use clean_up_question to remove question no
    def self.get_question paragraph
      paragraph.inject do |question, line|
        line  !~ /(^[^\d\s\.]\.)/ ? question << line : question
      end
    end

    #get options as an array
    #use clean_up_option to remove option alphabets
    def self.get_options paragraph
      hash = paragraph.find_all { |p| p =~ /(^[abcd\.]\.)/ }.inject({}) do | hash, option |
        alphabet = get_option_alphabet(option).downcase
        if alphabet != 'a' && hash[(alphabet.ord - 1).chr] == nil
          raise "Missing previous option #{hash[(alphabet.ord - 1).chr]}. Please check question format"
        end
        hash[alphabet] = remove_option_alphabet(option)
        hash
      end
      if hash['d'] == nil
        raise "Missing option d. Please check"
      end
      hash
    end

    def self.get_paragraphs filename

      paragraphs = []
      File.foreach(filename).chunk { |line|
        /\A\s*\z/ !~ line || nil
      }.each { |_, lines|
        paragraphs << lines
      }

      paragraphs
    end


    def self.factories_to_csv factories, dirname

      total_no_of_questions = 0
      newfile = "#{dirname}/csv_format.csv"

      CSV.open(newfile, 'w') do |csv|
        factories.each do |factory|
          csv << [TYPE, factory[TYPE]]
          csv << [TITLE, factory[TITLE]]
          csv << [QUESTION, factory[QUESTION]]
          csv << [POINTS, factory[POINTS]]

          factory[OPTIONS].each do |key, option|
            weight = (key == factory[ANSWER]) ? 100 : 0
            csv << [OPTION, weight, option]
          end
          total_no_of_questions = total_no_of_questions + 1

        end
      end

      puts "#{total_no_of_questions} processed"

    end
end