require 'paperclip/meta'

module Paperclip
  module Meta
    if defined? ::Rails::Railtie
      class Railtie < ::Rails::Railtie
        initializer :paperclip_meta do
          ActiveSupport.on_load :active_record do
            Paperclip::Meta::Railtie.insert
          end
        end

        rake_tasks { load 'tasks/paperclip-meta.rake' }
      end
    end

    class Railtie
      def self.insert
        Paperclip::Attachment.send(:include, Paperclip::Meta::Attachment)
      end
    end
  end
end
