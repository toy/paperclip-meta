namespace :paperclip do
  desc "Refreshes both metadata and thumbnails."
  task :refresh => 'paperclip:refresh:meta'

  namespace :refresh do
    desc "Regenerates meta for a given CLASS (and optional ATTACHMENT)."
    task :meta => :environment do
      klass = Paperclip::Task.obtain_class
      names = Paperclip::Task.obtain_attachments(klass)
      names.each do |name|
        Paperclip.each_instance_with_attachment(klass, name) do |instance|
          instance.send(name).refresh_meta!
          instance.save(:validate => false)
        end
      end
    end
  end
end
