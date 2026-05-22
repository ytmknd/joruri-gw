class ApplicationController < ActionController::Base
###  include Cms::Controller::Public
  protect_from_forgery #:secret => '1f0d667235154ecf25eaf90055d99e99'
  before_action :initialize_application #, :miniprofiler
  #rescue_from Exception, :with => :rescue_exception

  def initialize_application
###    mobile_view if Page.mobile? || request.mobile?
    return false if Core.dispatched?
    return Core.dispatched
  end

  def send_mail(mail_fr, mail_to, subject, message)
    return false if mail_fr.blank?
    return false if mail_to.blank?
    Sys::Lib::Mail::Base.deliver_default(mail_fr, mail_to, subject, message)
  end

  def send_data(data, options = {})
    if options.include?(:filename) && self.class.helpers.file_name_encode?(request.headers['HTTP_USER_AGENT'])
      options[:filename] = options[:filename].tosjis
    end
    super(data, options)
  end

private
  def miniprofiler
    Rack::MiniProfiler.authorize_request
  end
  def rescue_exception(exception)
    Core.terminate

    log  = exception.to_s
    log += "\n" + exception.backtrace.join("\n") if Rails.env.to_s == 'production'
    error_log(log)

    html  = %Q(<div style="padding: 15px 20px; color: #e00; font-weight: bold; line-height: 1.8;">)
    case
    when exception.is_a?(Mysql2::Error)
      html += %Q(データベースへの接続に失敗しました。<br />#{exception} &lt;#{exception.class}&gt;)
    else
#      html += %Q(エラーが発生しました。<br />#{exception} &lt;#{exception.class}&gt;)
      html += %Q(error! <br />#{exception} &lt;#{exception.class}&gt;)
    end
    html += %Q(</div>)
    if Rails.env.to_s != 'production'
      html += %Q(<div style="padding: 15px 20px; border-top: 1px solid #ccc; color: #800; line-height: 1.4;">)
      html += exception.backtrace.join("<br />")
      html += %Q(</div>)
    end
    render plain: html
    #render :inline => html, :layout => true, :status => 500
    #respond_to do |format|
      # format.html { render :inline => html, :layout => "base"  }
      #format.html { render :inline => html, :layout => true, :status => 500  }
      #format.json { render json: @micropost.errors, status: :unprocessable_entity }
    #end
  end

  def http_error(status, message = nil)
    Core.terminate

###    Page.error = status

    ## errors.log
    if status != 404
      request_uri = request.fullpath.force_encoding('UTF-8')
      error_log("#{status} #{request_uri} #{message.to_s.gsub(/\n/, ' ')}")
    end

    ## Render
    file = "#{Rails.public_path}/500.html"
###    if Page.site && FileTest.exist?("#{Page.site.public_path}/#{status}.html")
###      file = "#{Page.site.public_path}/#{status}.html"
###    elsif Core.site && FileTest.exist?("#{Core.site.public_path}/#{status}.html")
###      file = "#{Core.site.public_path}/#{status}.html"
###    els
    if FileTest.exist?("#{Rails.public_path}/#{status}.html")
      file = "#{Rails.public_path}/#{status}.html"
    end

    @message = message
    return respond_to do |format|
      #render plain: "<html><body><h1>#{message}</h1></body></html>"
      format.html { render(:status => status, :file => file, :layout => false) }
      format.xml  { render :xml => "<errors><error>#{status} #{message}</error></errors>" }
    end
  end

  def flash_notice(action_description = '処理', done = nil, mode=nil)
    ret = action_description + 'に' + ( done ? '成功' : '失敗' ) + 'しました'
    if mode.blank?
      flash[:notice] = ret
    else
      return ret
    end
  end
end
