require Rails.root.join('app', 'controllers', 'requests_controller')

# override public RequestsController
class RequestsController < ApplicationController

  # override make_request: redirect the request to aeon
  def make_request
    @request  = RequestItem.new(params)
    @endpoint = AppConfig[:aspace_aeon_requests_endpoint]

    # @request contains all available request data (see README.md for examples)
    $stdout.puts("\n\n\n#{@request.to_h}\n\n\n")

    errs = @request.validate
    if errs.blank?
      # TODO: error handling
      aeon_request_url = build_aeon_request_url.to_s
      $stdout.puts("\n\n\n#{aeon_request_url}\n\n\n")
      redirect_to aeon_request_url
    else
      flash[:error] = errs
      redirect_back(fallback_location: request[:request_uri]) and return
    end
  end

  private

  # generate aeon request url:
  # [title, site, callnum, sublocation, volume]
  def build_aeon_request_url
    # hash for params required for aeon extracted from @request
    callnum        = id_to_callnum
    site           = site_lookup
    specialrequest = note_to_specialrequest
    sublocation    = locations_to_sublocation
    title          = title_with_hierarchy
    volume         = containers_to_volume

    params = {
      callnum: callnum,
      site:    site,
      title:   title,
    }
    params[:specialrequest] = specialrequest unless specialrequest.empty?
    params[:sublocation]    = sublocation unless sublocation.empty?
    params[:volume]         = volume unless volume.empty?

    AppConfig[:aspace_aeon_requests_params_transform].each do |param, transform|
      params[param] = transform.call(params[param]) if params.has_key?(param)
    end

    URI::HTTPS.build(host: @endpoint, path: '/OpenURL', query: URI.encode_www_form(params))
  end

  def containers_to_volume
    volume = []
    if @request.container and @request.container.any?
      @request.container.zip(@request.barcode).each do |container, barcode|
        v = barcode.empty? ? container : "#{container}, Barcode: #{barcode}"
        volume << v
      end
    end
    volume.join(";")
  end

  def id_to_callnum
    @request.resource_id ? @request.resource_id : @request.identifier
  end

  def locations_to_sublocation
    sublocation = ""
    if @request.location_title and @request.location_title.any?
      sublocation = @request.location_title.join(";")
    end
    sublocation
  end

  def note_to_specialrequest
    @request.note ? @request.note : ""
  end

  def site_lookup
    AppConfig[:aspace_aeon_requests_repo_map].fetch(
      @request.repo_code,
      AppConfig[:aspace_aeon_requests_repo_default]
    )
  end

  def title_with_hierarchy
    @request.hierarchy ? @request.hierarchy.push(@request.title).join(",") : @request.title
  end

end
