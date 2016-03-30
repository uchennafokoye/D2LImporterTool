class MultipleChoice

  attr_reader :index, :question, :answer_options

  def initialize index, question, answer_options
    @index = index
    @question = question
    @answer_options = answer_options
  end


  def to_s
    "#{@index}. #{@question}"
  end

  def to_hash
    {@index => {:get_question => @question, :answer_options => @answer_options}}
  end


end