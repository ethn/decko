def store_dir
  coded? ? coded_dir : upload_dir
end

def retrieve_dir
  coded? ? coded_dir : upload_dir
end

# place for files of regular file cards
def upload_dir
  id ? "#{files_base_dir}/#{id}" : tmp_upload_dir
end

def files_base_dir type="files"
  dir = bucket ? bucket_config[:subdirectory] : Card.paths[type].existent.first
  dir || files_base_dir_configuration_error
end

def files_base_dir_configuration_error
  raise StandardError,
        "missing directory for file cache (default is `files` in deck root)"
end

# used in the identifier
def file_dir
  if coded?
    codename_parts.map { |c| ":#{c}" }.join Name.joint
  elsif cloud?
    "(#{bucket})/#{file_id}"
  else
    "~#{file_id}"
  end
end

def public?
  who_can(:read).include? Card::AnyoneID
end

def file_id
  id? ? id : upload_cache_card.id
end
