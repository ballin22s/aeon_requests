# check for required config settings
[
  { setting: :aspace_aeon_requests_endpoint, required: true },
  { setting: :aspace_aeon_requests_repo_default, required: true },
  { setting: :aspace_aeon_requests_repo_map, required: false },
  { setting: :aspace_aeon_requests_params_transform, required: false },
].each do |config|
  required = config[:required]
  setting  = config[:setting]

  if required and not AppConfig.has_key?(setting)
    raise "Config variable #{setting} is required!"
  end
  AppConfig[setting] = {} unless AppConfig.has_key?(setting)
end

$stdout.puts "\n\n\nArchivesSpace Aeon requests plugin enabled =)\n\n\n"
