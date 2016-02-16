view :raw do |_args|
  Rails.logger.info "reading file: #{Cardio.gem_root}/mod/03_machines/lib/javascript/#{card.codename}.js.coffee"
  File.read "#{Cardio.gem_root}/mod/03_machines/lib/javascript/#{card.codename}.js.coffee"
end

format :html do
  view :editor do |_args|
    "Content is stored in file and can't be edited."
  end
end
