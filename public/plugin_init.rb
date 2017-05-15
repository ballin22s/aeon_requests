ArchivesSpacePublic::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

module ApplicationHelper

  # record should be a resource or archival object
  # display if instances with containers and container locations are present
  def display_aeon_request_links_for(record)
    return false unless record.present?
    record["instances"].each do |i|
      return true if i["container"].present? and i["container"]["container_locations"].any?
    end
  end

  def get_tree_node_from_root_for_uri(uri)
    get_tree_by_type_for_uri("tree_node_from_root", uri)
  end

  def get_tree_waypoint_for_uri(uri)
    get_tree_by_type_for_uri("tree_waypoint", uri)
  end

  private

  def get_tree_by_type_for_uri(type, uri)
    begin
      json_str = JSONModel::HTTP::get_json("/search",
        {
          "page" => 1,
          "q" => "primary_type:#{type} AND pui_parent_id:\"#{uri}\""
        }
       )
       .fetch('results')
       .fetch(0)
       .fetch('json')

      ASUtils.json_parse(json_str)
    rescue
      raise RecordNotFound.new("Record not found: #{uri}")
    end
  end

end
