class D2lCsvFactory



  module NamingConfig
    #d2l specified names for row headers in csv
    TITLE = :Title
    TYPE = :NewQuestion
    QUESTION = :QuestionText
    POINTS = :Points
    DIFFICULTY = :Difficulty
    OPTION = :Option

    #Program-Specific Naming Configs
    OPTIONS = :Options
    ANSWER = :Answer
  end

  module Type
    MC = 'MC'
    TF = 'TF'
  end

  attr_reader :factory

  include NamingConfig
  include Type


  def initialize question_text, answer, answer_options, options: {}
    @factory = self.class.make_factory question_text, answer, answer_options, get_options: {}
  end

  def self.make_factory question_text, answer, answer_options, options: {}
      if answer_options[answer] == nil
        raise "Correct Answer is not in Answer Options"
      end
     hash = {QUESTION => question_text, ANSWER => answer, OPTIONS => answer_options}
     @factory = default_options(options).merge!(hash)
  end

  private
  def self.default_options options: {}
    type = options[:type] || MC
    title = options[:title] || ""
    difficulty = options[:difficulty] || 1
    points = options[:points] || 1
    {TYPE => type, TITLE => title, DIFFICULTY => difficulty, POINTS => points}
  end


end