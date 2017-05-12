require "cgi"

class AeonRequestsController < ApplicationController

  before_action :get_repository

  def archival_object
    archival_object = JSONModel(:archival_object).find(params[:id], repo_id: params[:repo_id])
    raise RecordNotFound.new if (!archival_object || archival_object.has_unpublished_ancestor || !archival_object.publish)

    locations = fetch_locations_for(archival_object)
    resource  = fetch_resource_for(archival_object)

    result = {
      aeon_request_data: aeon_request_hash(archival_object),
      archival_object:   archival_object,
      locations:         locations,
      resource:          resource
    }

    respond_to do |format|
      format.html { redirect_to aeon_link(archival_object) }
      format.json { render text: result.to_json }
    end

  end

  def resource
    resource = JSONModel(:resource).find(params[:id], repo_id: params[:repo_id])
    raise RecordNotFound.new if (!resource || !resource.publish)

    locations = fetch_locations_for(resource)

    result = {
      aeon_request_data: aeon_request_hash(resource),
      resource:          resource,
      locations:         locations
    }

    respond_to do |format|
      format.html { redirect_to aeon_link(resource) }
      format.json { render text: result.to_json }
    end

  end

  private

  def get_repository
    @repository = @repositories.select{|repo| JSONModel(:repository).id_for(repo.uri).to_s === params[:repo_id]}.first
  end

  def fetch_resource_for(record)
    resource_id = record["resource"]["ref"].split("/").last
    JSONModel(:resource).find(resource_id, repo_id: params[:repo_id])
  rescue
    "resource not found"
  end

  def callnum_for(record)
    if record["jsonmodel_type"] == "archival_object"
      resource_id = record["resource"]["ref"].split("/").last
      JSONModel(:resource).find(resource_id, repo_id: params[:repo_id])["id_0"]
    elsif record["jsonmodel_type"] == "resource"
      record["id_0"]
    end
  end

  def fetch_locations_for(record)
    locations = []

    record["instances"].each do |instance|
      next unless instance["container"].present?
      next unless instance["container"]["container_locations"].present?

      container_details = "#{instance["container"]["type_1"]} #{instance["container"]["indicator_1"]} " +
        "#{instance["container"]["type_2"]} #{instance["container"]["indicator_2"]}"

      instance["container"]["container_locations"].each do |container_location|
        next unless container_location["ref"].present?

        location_id = container_location["ref"].split("/").last
        location    = JSONModel(:location).find(location_id)
        title       = location["title"]
        locations << {
          area:     title,
          sub_area: container_details,
          location: location
        }
      end
    end

    locations
  end

  # returns locations associated with the record
  # if no locations are found, move up the records hierarchy and check again
  def locations_data_for(record)
    records = ancestry_for(record).reverse

    records.each do |record|
      locations = fetch_locations_for(record)
      return locations unless locations.empty?
    end

    []
  end

  def ancestry_for(record)
    case record["jsonmodel_type"]
    when "archival_object"
      archival_object = ArchivalObjectView.new(record)
      tree_node_from_root = get_tree_node_from_root_for_uri(archival_object.uri)

      breadcrumbs = []
      tree_node_from_root[record.id.to_s].each do |node|
        if node["node"].nil? # a resource
          id = node["root_record_uri"].split("/")[-1]
          r  = JSONModel(:resource).find(id, repo_id: params[:repo_id])
          breadcrumbs << r
        else # an archival_object
          id = node["node"].split("/")[-1]
          ao = JSONModel(:archival_object).find(id, repo_id: params[:repo_id])
          breadcrumbs << ao
        end
      end

      breadcrumbs << record
    when "resource"
      [record]
    end
  end

  def ancestry_titles_for(record)
    case record["jsonmodel_type"]
    when "archival_object"
      # see public/app/controller/records_controller#archival_object
      archival_object = ArchivalObjectView.new(record)
      tree_node_from_root = get_tree_node_from_root_for_uri(archival_object.uri)

      breadcrumbs = []
      tree_node_from_root[record.id.to_s].each do |node|
        breadcrumbs.push node["title"]
      end

      breadcrumbs.push(archival_object.display_string)
    when "resource"
      # see public/app/controller/records_controller#resource
      resource = ResourceView.new(record)
      breadcrumb_title = resource.title
      [breadcrumb_title]
    end
  end

  def determine_site_from_repo_code(repo_code)
    if AppConfig[:aeon_request_repository_mappings].present?
      AppConfig[:aeon_request_repository_mappings][repo_code] ||
        AppConfig[:aeon_request_repository_mappings_default]
    else
      repo_code
    end
  end

  def aeon_request_hash(record)
    title = ancestry_titles_for(record).first

    site        = determine_site_from_repo_code(@repository["repo_code"])
    location    = locations_data_for(record).map{ |l| "#{l[:area]}" }.join("; ")
    item_volume = locations_data_for(record).map{ |l| "#{l[:sub_area]}" }.join("; ")
    callnum     = callnum_for(record)

    if AppConfig.has_key?(:aeon_request_location_find) and AppConfig.has_key?(:aeon_request_location_replace)
      location = location.gsub(AppConfig[:aeon_request_location_find], AppConfig[:aeon_request_location_replace])
    end

    {
      title:       title,
      site:        site,
      sub_location:    location,
      item_volume: item_volume,
      callnum:     callnum
    }
  end

  def aeon_link(record)
    params = aeon_request_hash(record).map { |k,v| "#{k.to_s.camelcase}=#{CGI.escape(v)}" }
    "#{AppConfig[:aeon_request_endpoint]}/OpenURL?#{params.join('&')}"
  end

end
