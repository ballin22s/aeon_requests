# ArchivesSpace Aeon Requests plugin

Send requests from ArchivesSpace to Aeon.

Versions tested:

- 2.1.1

## Setup

For developers only:

- use a release copy of archivesspace for testing, not the source
- download this plugin using git to the `plugins` directory

Apply configuration in `config.rb`:

```ruby
AppConfig[:plugins] << 'aspace_aeon_requests'
# [required] aeon hostname
AppConfig[:aspace_aeon_requests_endpoint] = 'aeon.myinstitution.edu'
# [optional] map aspace repo_code to site identifier in aeon
AppConfig[:aspace_aeon_requests_repo_map] = {
  'aspace_repo_1' => 'aeon_repo_1'
  'aspace_repo_2' => 'aeon_repo_2'
}
# [required] use this to set a default aeon repository / site
# if mapping lookup is unmatched default site is used for the request
AppConfig[:aspace_aeon_requests_repo_default] = "aeon_repo_1"
# [optional] cleanup aeon request params using a lambda to process
AppConfig[:aspace_aeon_requests_params_transform] = {
  volume: ->(param) {
    param.split(";").map{ |s| s.gsub(/\(.*\)/, '').strip }
  },
}

# you may want to edit these ArchivesSpace default settings:
AppConfig[:pui_requests_permitted_for_types] = [
  :resource,
  :archival_object,
  :accession,
  :digital_object,
  :digital_object_component
]
# set to 'true' if you want to disable if there is no top container
AppConfig[:pui_requests_permitted_for_containers_only] = false
```

## Request data

Without container (minimal):

```ruby
{
  :user_name=>"Mickey Mouse",
  :user_email=>"mickey.mouse@disney.com",
  :date=>"12/25/2017",
  :note=>"",
  :request_uri=>"/repositories/2/resources/1",
  :title=>"QQQ",
  :resource_name=>nil,
  :identifier=>"123",
  :cite=>"QQQ. TEST.   http://localhost:8081/repositories/2/resources/1  Accessed  September 07,
  2017.",
  :restrict=>nil,
  :hierarchy=>nil,
  :repo_name=>"TEST",
  :resource_id=>nil,
  :linked_record_uris=>nil,
  :machine=>nil,
  :top_container_url=>nil,
  :container=>nil,
  :barcode=>nil,
  :location_title=>nil,
  :location_url=>nil,
  :repo_uri=>"/repositories/2",
  :repo_code=>"TEST"
}
```

With container (and location):

```ruby
{
  :user_name=>"Mickey Mouse",
  :user_email=>"mickey.mouse@disney.com",
  :date=>"12/25/2017",
  :note=>"",
  :request_uri=>"/repositories/2/archival_objects/2",
  :title=>"B",
  :resource_name=>"QQQ",
  :identifier=>"",
  :cite=>"B. QQQ,
  . TEST.   http://localhost:8081/repositories/2/archival_objects/2  Accessed  September 07,
  2017.",
  :restrict=>nil,
  :hierarchy=>["QQQ", "A"],
  :repo_name=>"TEST",
  :resource_id=>"123",
  :linked_record_uris=>nil,
  :machine=>nil,
  :top_container_url=>["/repositories/2/top_containers/1"],
  :container=>["Box: 1, Folder: 1 (Mixed Materials)"],
  :barcode=>["123456"],
  :location_title=>["Library, 1, Stacks, Y [Shelf: 1, Row: 2]"],
  :location_url=>["/locations/1"],
  :repo_uri=>"/repositories/2",
  :repo_code=>"TEST"
}
```

The request data is mapped to Aeon url parameters.

## Aeon request mapping

The mapping is currently fixed but could be pushed into config later:

```
Aeon field name,Aeon openURL mapping,ArchivesSpace request property
CallNumber,callnum,id|identifier
Site,site,repo_code[mapped via config]
SpecialRequest,specialrequest,note
SubLocation,sublocation,location_title
Title,title,title[with hierarchy]
ItemVolume,volume,container[with barcode]
```

---