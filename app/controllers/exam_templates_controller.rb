class ExamTemplatesController < ApplicationController
  # responders setup
  responders :flash, :http_cache
  respond_to :html

  before_filter      :authorize_only_for_admin

  layout 'assignment_content'

  def index
    @assignment = Assignment.find(params[:assignment_id])
    @exam_templates = @assignment.exam_templates
  end

  def download
    assignment = Assignment.find(params[:assignment_id])
    exam_template = assignment.exam_templates.find_by(id: params[:id]) # look up a specific exam template based on the params[:id]
    filename = exam_template.filename
    assignment_name = assignment.short_identifier
    send_file("#{EXAM_TEMPLATE_DIR}/#{assignment_name}/#{filename}",
              filename: "#{filename}",
              type: "application/pdf")
  end

  def update
    assignment = Assignment.find(params[:assignment_id])
    old_exam_template = assignment.exam_templates.find_by(id: params[:id])
    # updating exam template file
    new_uploaded_io = params[:exam_template][:new_template]
    unless new_uploaded_io.nil?
      # error checking when new_uploaded_io is not pdf
      if new_uploaded_io.content_type != 'application/pdf'
        flash_message(:error, t('exam_templates.update.failure'))
      else
        old_template_filename = old_exam_template.filename
        old_exam_template.replace_with_file(new_uploaded_io.read, assignment_id: assignment.id, filename: old_template_filename)
        respond_with(old_exam_template)
      end
      redirect_to action: 'index'
    end
  end
end
