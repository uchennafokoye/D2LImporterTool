require './lib/ext/string'

class Answer

  attr_reader :index, :correct_answer
  def initialize(index, correct_answer)
    unless validate index, correct_answer
      raise ArgumentError, "Index or correct answer are illegal"
    end
    @index = index.to_i
    @correct_answer = correct_answer.downcase
  end

  def validate index, correct_answer
    index_is_number = (index.is_a? (String)) ? (index.is_i?) : (index.is_a? (Fixnum))
    index_is_number && correct_answer.is_a?(String)
  end

  def to_s
    "MultipleChoice No: #{@index}, Correct Answer: #{@correct_answer}"
  end

  def to_hash
    {@index => @correct_answer}
  end
end