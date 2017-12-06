#
# Student preferences
#

preferences = {}
CSV.foreach(PREFERENCE_FILE, :headers => true, :header_converters => :symbol, :converters => :all) do |row|
  student = row[1]

  unless classrooms.include? student
    puts "ERROR: Student #{student} has no assigned classroom"
  end

  classroom = classrooms[student]
  preferences[classroom] ||= {}

  if preferences[classroom].include? student
    puts "WARNING: duplicate preferences for student #{student}. Using the last line."
  end

  raw = Hash[row.headers.zip(row.fields)]

  parsed = preferences[classroom][student] = { name: student, timestamp: raw[:timestamp] }

  parsed[:positive] = raw[:positive_feels_please_check_exactly_3_companies_only_select_companies_you_have_interviewed_at].split(',').map { |str| str.strip }
  parsed[:neutral] = raw[:neutral_feels_please_check_exactly_2_companies_only_select_companies_you_have_interviewed_at].split(',').map { |str| str.strip }
  parsed[:negative] = raw[:with_reservation_please_check_exactly_1_companies_only_select_companies_you_have_interviewed_at].split(',').map { |str| str.strip }
  parsed[:companies] = parsed[:positive] + parsed[:neutral] + parsed[:negative]
  parsed[:companies].sort!
end


#
# Interview Results
#
def load_interview_file(filename)
  data = {}
  CSV.foreach(filename, :headers => true, :header_converters => :symbol, :converters => :all) do |row|
    student = row[3]
    data[student] ||= []
    data[student] << Hash[row.headers.zip(row.fields)]
  end
  return data
end

interview_results = load_interview_file(INTERVIEW_FILE)

parsed_interview_results = {}

interview_results.each do |student, results|
  unless classrooms.include? student
    puts "ERROR: Student #{student} has no assigned classroom"
  end

  classroom = classrooms[student]

  parsed_interview_results[classroom] ||= {}
  parsed_interview_results[classroom][student] ||= {}
  student_results = parsed_interview_results[classroom][student]

  results.each do |interview|
    company = interview[:company]

    interview[:numeric_result] = INTERVIEW_SCORES[interview[:feedback_summary]]
    if interview[:numeric_result].nil?
      puts "ERROR: invalid interview result #{interview[:feedback_summary]} for student #{student} company #{company}"
    end
    if student_results.include? interview[:company]
      # puts "Duplicate interview for student #{student} company #{company}"
      if student_results[company][:numeric_result] >= interview[:numeric_result]
        # puts "Using existing score of #{student_results[company][:numeric_result]}"
        next
      else
        # puts "Using new score of #{interview[:numeric_result]}"
      end
    end
    student_results[company] = interview
  end

  if student_results.length < 6
    puts "ERROR: student #{student} only has #{student_results.length} interviews: #{student_results.keys}"

  else
    unless preferences[classroom].include? student
      puts "ERROR: student #{student} not in preference list"
    end

    if student_results.keys.sort != preferences[classroom][student][:companies]
      puts "ERROR: company mismatch for student #{student}"
      puts "    Interview companies: #{student_results.keys}"
      puts "    Preference companies: #{preferences[classroom][student][:companies]}"
    end
  end
end
interview_results = parsed_interview_results

if interview_results.keys.sort != preferences.keys.sort
  puts "ERROR: student names do not all match!"
  puts "    In interview_results but not in preferences: #{interview_results.keys - preferences.keys}"
  puts "    In preferences but not in interview_results: #{preferences.keys - interview_results.keys}"
end

interview_results.each do |classroom, students|
  CSV.open("#{classroom}_#{PARSED_INTERVIEW_FILE}", 'wb') do |csv|
    headers = ["Timestamp", "Interviewer Name", "Company", "Student Name", "Hiring Decision", "Reason for Hiring Decision", "Technical Feedback for Candidate", "Nontechnical Feedback for Candidate"]
    csv << headers

    students.each do |student, results|
      results.each do |company, interview|
        line = [
          interview[:timestamp],
          interview[:interviewer_name],
          company,
          student,
          interview[:numeric_result],
          interview[:explanation_of_feedback_summary],
          interview[:technical_feedback_for_candidate],
          interview[:nontechnical_feedback_for_candidate]
        ]
        # if line.include? nil or line.length != headers.length
        #   puts "ERROR: student #{student} company #{company} is missing some interview result data! Line:"
        #   puts line
        # end
        csv << line
      end
    end
  end
end

preferences.each do |classroom, prefs|
  CSV.open("#{classroom}_#{PARSED_PREFERENCE_FILE}", 'wb') do |csv|
    headers = ["Timestamp", "Student Name", "Positive Feelings", "Positive Feelings", "Positive Feelings", "Neutral Feelings", "Neutral Feelings", "Negative Feelings"]
    csv << headers

    prefs.each do |student, results|
      line = [
        results[:timestamp],
        student
      ] + results[:positive] + results[:neutral] + results[:negative]
      if line.include? nil or line.length != headers.length
        puts "ERROR: student #{student} is missing some preference data! Line:"
        puts line
      end
      csv << line
    end
  end
end