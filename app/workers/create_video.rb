Resque.logger = Logger.new("log/resque_log_file.log")
class CreateVideo
  @queue = :create_video
  def self.perform(project_id)
    Resque.logger.info "Generating video for project id: #{project_id}" 
    project = Project.find(project_id)
    video_output_path = project.video_output_path
    Resque.logger.info "video output: #{video_output_path}" 
    `ffmpeg -f image2 -i #{project.dir}/%d.png #{video_output_path}`
  end
end
