class Project < ActiveRecord::Base
  validates_presence_of :name, :url
  validates_uniqueness_of :url
  validates_format_of :url, with: /^[a-zA-Z0-9\-=_!]*$/m, multiline: true
  has_many :images, after_add: :set_imagebase_first
  belongs_to :imagebase, class_name: 'Image'
  after_create :mkdir_images_dir
  scope :with_images, -> { where('id in (select project_id from images)')}
  
  def mkdir_images_dir
    [dir, thumbs_dir].each do |_dir|
      Dir.mkdir _dir if not Dir.exists? _dir
    end
  end
  def dir
    @dir ||= File.join UPLOADS_DIR, self.id.to_s
  end
  def url_path
    @url_path ||= "/system/uploads/#{self.id}"
  end
  def url_thumb_path
    @url_thumb_path ||= File.join(url_path, "thumbs")
  end
  def thumbs_dir
    File.join(dir,"thumbs")
  end
  def set_imagebase_first record
    if images.count == 1
      self.imagebase = images.first
      self.save
    end
  end
  def video_url
    @video_url ||= File.join(url_path, "#{url}.mp4")
  end
  def video_output_path
    @video_output_path ||= File.join(dir, "#{url}.mp4")
  end
  def render_video!
    if Rails.env.production? 
      Resque.enqueue(CreateVideo, self.id)
    else
      CreateVideo.perform(self.id)
    end
    video_output_path
  end
end
