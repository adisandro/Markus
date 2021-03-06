namespace :db do

  desc 'Update fake marks for assignments'
  task :marks => :environment do
    puts 'Assign Marks for Assignments (This may take a while)'

    Assignment.find_by(short_identifier: 'A0').update(due_date: 24.hours.ago)
    Assignment.where(short_identifier: %w[A1 A2]).update_all(due_date: Time.current)

    # Open the text for the feedback files to reference
    mfile = File.open("db/data/feedback_files/machinefb.txt", "rb")
    hfile = File.open("db/data/feedback_files/humanfb.txt", "rb")
    mcont = mfile.read
    hcont = hfile.read
    mfile.close
    hfile.close
    feedbackfiles = []
    marks = []
    #Right now, only generate marks for three assignments
    Grouping.joins(:assignment).where(assessments: { short_identifier: %w[A0 A1 A2] }).each do |grouping|
      time = grouping.assignment.submission_rule.calculate_collection_time.localtime
      new_submission = Submission.create_by_timestamp(grouping, time)
      result = new_submission.results.first
      grouping.is_collected = true
      grouping.save

      if grouping.assignment.short_identifier == 'A0'
        grouping.assignment.submission_rule.apply_submission_rule(new_submission)
      end

      # add a human written feedback file
      feedbackfiles << FeedbackFile.new(
        submission: new_submission, filename: 'humanfb', mime_type: 'text', file_content: hcont
      )

      # add an machine-generated feedback file
      feedbackfiles << FeedbackFile.new(
        submission: new_submission, filename: 'machinefb', mime_type: 'text', file_content: mcont
      )

      submission_file = new_submission.submission_files.find_by(filename: 'deferred-process.jpg')
      base_attributes = {
        submission_file_id: submission_file.id,
        is_remark: new_submission.has_remark?,
        annotation_text_id: AnnotationText.all.pluck(:id).to_a.sample,
        annotation_number: new_submission.annotations.count + 1,
        creator_id: Admin.first.id,
        creator_type: 'Admin',
        result_id: new_submission.current_result.id
      }
      ImageAnnotation.create(
        x1: 132,
        y1: 199,
        x2: 346,
        y2: 370,
        **base_attributes
      )
      submission_file = new_submission.submission_files.find_by(filename: 'pdf.pdf')
      base_attributes = {
        submission_file_id: submission_file.id,
        is_remark: new_submission.has_remark?,
        annotation_text_id: AnnotationText.all.pluck(:id).to_a.sample,
        annotation_number: new_submission.annotations.count + 1,
        creator_id: Admin.first.id,
        creator_type: 'Admin',
        result_id: new_submission.current_result.id
      }
      PdfAnnotation.create(
        x1: 27_740,
        y1: 58_244,
        x2: 4977,
        y2: 29_748,
        page: 1,
        **base_attributes
      )
      submission_file = new_submission.submission_files.find_by(filename: 'hello.py')
      base_attributes = {
        submission_file_id: submission_file.id,
        is_remark: new_submission.has_remark?,
        annotation_text_id: AnnotationText.all.pluck(:id).to_a.sample,
        annotation_number: new_submission.annotations.count + 1,
        creator_id: Admin.first.id,
        creator_type: 'Admin',
        result_id: new_submission.current_result.id
      }
      TextAnnotation.create(
        line_start: 7,
        line_end: 9,
        column_start: 6,
        column_end: 15,
        **base_attributes
      )

      #Automate marks for assignment using appropriate criteria
      grouping.assignment.get_criteria(:all, :all, includes: :marks).each do |criterion|
        if criterion.class == RubricCriterion
          random_mark = criterion.max_mark / 4 * rand(0..4)
        elsif criterion.class == FlexibleCriterion
          random_mark = rand(0..criterion.max_mark.to_i)
        else
          random_mark = rand(0..1)
        end
        marks << Mark.new(
          result_id: result.id,
          markable_id: criterion.id,
          markable_type: criterion.class.to_s,
          mark: random_mark
        )
      end
    end
    FeedbackFile.import feedbackfiles

    Mark
      .joins(result: [submission: [grouping: :assignment]])
      .where(assessments: { short_identifier: %w[A0 A1 A2] }).destroy_all
    Mark.import marks

    puts 'Release Results for Assignments'
    #Release the marks after they have been inputed into the assignments
    Result.all.each do |result|
      result.update_total_mark
      result.marking_state = 'complete'
      result.released_to_students = true
      result.save
    end

    Assignment.where(short_identifier: %w(A0 A1 A2)).each do |a|
      a.update_results_stats
      a.assignment_stat.refresh_grade_distribution
    end

    puts 'Assign Marks for Spreadsheets'
    # Quiz1
    grade_entry_form = GradeEntryForm.first
    # Add marks to every student
    grade_entry_form.grade_entry_students.find_each do |student|
      # For each question, assign a random mark based on its out_of value
      grade_entry_form.grade_entry_items.each do |grade_entry_item|
        random_grade = 1 + rand(0...Integer(grade_entry_item.out_of))
        Grade.create(grade_entry_student_id: student.id,
                     grade_entry_item_id: grade_entry_item.id,
                     grade: random_grade)
      end
    end

    # Refresh total grade
    grade_entry_form.grade_entry_students.each(&:save)
    # Release spreadsheet grades
    grade_entry_form.grade_entry_students.update_all(released_to_student: true)
  end
end
