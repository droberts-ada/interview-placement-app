require 'test_helper'

describe InterviewFeedback do
  describe 'associations' do
    it 'belongs to an Interview' do
      interview_assoc = InterviewFeedback.reflect_on_association(:interview)
      expect(interview_assoc.macro).must_equal :belongs_to
    end
  end

  describe 'validations' do
    let(:feedback) { interview_feedbacks(:ada_space) }

    it 'can be valid' do
      expect(feedback).must_be :valid?
    end

    it 'is not valid without an interview' do
      feedback.interview = nil

      expect(feedback).wont_be :valid?
    end

    it 'is is not valid without an interviewer name' do
      feedback.interviewer_name = ''

      expect(feedback).wont_be :valid?
    end

    it 'is is not valid without an interview result' do
      feedback.interview_result = nil

      expect(feedback).wont_be :valid?
    end

    it 'is is not valid without a result explanation' do
      feedback.result_explanation = ''

      expect(feedback).wont_be :valid?
    end

    it 'validates interview result to be 1-5' do
      [nil, 0, -1, 6].each do |bad_result|
        feedback.interview_result = bad_result

        expect(feedback).wont_be :valid?
      end
    end
  end
end
