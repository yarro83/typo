class Admin::ResourcesController < Admin::BaseController
  layout 'administration'

  upload_status_for :file_upload, :status => :upload_status

  cache_sweeper :blog_sweeper

  def upload
    begin
      if request.post?
        file = params[:upload][:filename]
        unless file.content_type
          mime = 'text/plain'
        else
          mime = file.content_type.chomp
        end
        @up = Resource.create(:filename => file.original_filename, :mime => mime, :created_at => Time.now)

        @up.write_to_disk(file)

        @message = _('File uploaded: ')+ file.size.to_s
        finish_upload_status "'#{@message}'"
      end
    rescue
      @message = "'" + _('Unable to upload') + " #{file.original_filename}'"
      @up.destroy unless @up.nil?
      raise
    end
  end

  def update
    @resource = Resource.find(params[:resource][:id])
    @resource.attributes = params[:resource]

    if request.post? and @resource.save
      flash[:notice] = _('Metadata was successfully updated.')
    else
      flash[:error] = _('Not all metadata was defined correctly.')
      @resource.errors.each do |meta_key,val|
        flash[:error] << "<br />" + val
      end
    end
    redirect_to :action => 'index'
  end

  def upload_status
    render :inline => "<%= upload_progress.completed_percent rescue 0 %> % " + _("complete"), :layout => false
  end

  def index
    @r = Resource.new
    @resources = Resource.paginate :page => params[:page], :order => 'created_at DESC', :per_page => this_blog.admin_display_elements
  end

  def get_thumbnails
    position = params[:position].to_i
    @resources = Resource.find(:all, :conditions => "mime LIKE '%image%'", :order => 'created_at DESC', :limit => "#{position}, 10")
    render 'get_thumbnails', :layout => false
  end

  def destroy
    begin
      @file = Resource.find(params[:id])
      mime = @file.mime
      if request.post?
        @file.destroy
        redirect_to :action => 'index'
      end
    rescue
      raise
    end
  end
end
