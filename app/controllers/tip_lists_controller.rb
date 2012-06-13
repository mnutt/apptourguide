class TipListsController < ApplicationController
  before_filter :cors_preflight_check
  after_filter :cors_set_access_control_headers

  def update
    if tip_list.update_attributes params[:tip_list]
      render :json => {:success => true}
    else
      render :json => tip_list.errors
    end
  end

  def show
    render :json => tip_list.as_json
  end

protected

  def tip_list
    @_tip_list ||= TipList.find params[:id]
  end

  def default_origins
    %w(http://localhost:3000 http://localhost http://lh)
  end

  def allowed_origin
    u = URI.parse(request.headers['HTTP_REFERER'])
    referer_host = "#{u.host}#{':'+u.port.to_s unless u.port == u.default_port}"

    origins = default_origins + tip_list.domain.split(/[,\s]+/)
    "#{u.scheme}://#{referer_host}" if origins.include? referer_host
  end

  # If the browser sent an OPTIONS, immediately return a cors header response
  def cors_preflight_check
    if request.method == :options
      headers['Access-Control-Allow-Origin']  = allowed_origin
      headers['Access-Control-Allow-Methods'] = 'PUT, POST, GET, OPTIONS'
      headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-CSRF-Token'
      headers['Access-Control-Max-Age']       = '1728000'
      render :text => '', :content_type => 'text/plain'
    end
  end

  def cors_set_access_control_headers
    headers['Access-Control-Allow-Origin']  = allowed_origin
    headers['Access-Control-Allow-Methods'] = 'PUT, POST, GET, OPTIONS'
    headers['Access-Control-Max-Age']       = "1728000"
  end

end
