
require 'base64'
class ProjectsController < ApplicationController
  before_action :set_project, only: [:show, :edit, :update, :destroy, :add_image, :export]

  # GET /projects
  # GET /projects.json
  def index

    @projects = Project.all

  end
  def decide
    if cookies[:unique_url]
      redirect_to action: :edit, unique_url: cookies[:unique_url]
    else
      redirect_to new_project_path
    end
  end

  # GET /projects/1
  # GET /projects/1.json
  def show
  end

  # GET /projects/new
  def new
    @project = Project.new name: "My first project"
    while not @project.valid?
      @project.url = Base64.encode64(Time.now.to_i.to_s)[-10..-4]
    end
    @project.save
    cookies[:unique_url] = @project.url
    redirect_to action: :edit, unique_url: @project.url
  end

  # GET /projects/1/edit
  def edit
  end

  # POST /projects
  # POST /projects.json
  def create
    @project = Project.new(project_params)
    cookies[:unique_url] = @project.url

    respond_to do |format|
      if @project.save
        format.html { redirect_to @project, notice: 'Project was successfully created.' }
        format.json { render action: 'show', status: :created, location: @project }
      else
        format.html { render action: 'new' }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /projects/1
  # PATCH/PUT /projects/1.json
  def update
    respond_to do |format|
      if @project.update(project_params)
        cookies[:unique_url] = @project.url
        format.html { redirect_to @project, notice: 'Project was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/1
  # DELETE /projects/1.json
  def destroy
    @project.destroy
    respond_to do |format|
      format.html { redirect_to projects_url }
      format.json { head :no_content }
    end
  end

  # DELETE /projects/image/1
  # DELETE /projects/image/1.json
  def destroy_image
    @image = Image.find(params[:id])
    @image.destroy
    respond_to do |format|
      format.html { head :no_content }
      format.json { head :no_content }
    end
  end

  # POST /projects/1/add_image
  def add_image
    @project.mkdir_images_dir
    @image = Image.create filename: "", project: @project
    img_name = "#{ "%09d" % @image.id}.png"
    image_file = File.join(@project.dir, img_name)
    File.open(image_file, 'wb') do |f|
      f.write(decode_from_param :image)
    end
    thumb_file = File.join(@project.thumbs_dir, img_name)
    File.open(thumb_file, 'wb') do |f|
      f.write(decode_from_param :thumb)
    end
    @image.filename = img_name
    @image.save
    respond_to do |format|
      format.json { render json: @image.to_json(:methods => [:url, :thumb_url]) }
    end
  end
  def export
    @project.render_video!
  end

  private
    def decode_from_param name
      Base64.decode64(params[name][params[name].index(",").. -1])
    end
    # Use callbacks to share common setup or constraints between actions.
    def set_project
      @project = Project.where(url: params[:id] || params[:unique_url]).first
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def project_params
      params.require(:project).permit(:name, :url, :baseimage_effect, :imagebase_id)
    end
end
