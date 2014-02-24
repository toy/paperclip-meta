module Paperclip
  module Meta
    module Attachment
      def self.included(base)
        base.send :include, InstanceMethods
        base.alias_method_chain :save, :meta_data
        base.alias_method_chain :post_process_styles, :meta_data
        base.alias_method_chain :size, :meta_data
      end

      module InstanceMethods
        def save_with_meta_data
          if @queued_for_delete.any? && @queued_for_write.empty?
            write_meta({})
          end
          save_without_meta_data
        end

        def post_process_styles_with_meta_data(*style_args)
          post_process_styles_without_meta_data(*style_args)
          return unless instance.respond_to?(:"#{name}_meta=")

          meta = read_meta || {}
          @queued_for_write.each do |style, file|
            begin
              geo = Geometry.from_file file
              meta[style] = { width: geo.width.to_i, height: geo.height.to_i, size: file.size }
            rescue Paperclip::Errors::NotIdentifiedByImageMagickError
              meta[style] = {}
            end
          end
          write_meta(meta)
        end

        # Use meta info for style if required
        def size_with_meta_data(style = nil)
          style ? meta_for_style(style)[:size] : size_without_meta_data
        end

        def height(style = default_style)
          meta_for_style(style)[:height]
        end

        def width(style = default_style)
          meta_for_style(style)[:width]
        end

        # Return image dimesions ("WxH") for given style name. If style name not given,
        # return dimesions for default_style.
        def dimensions(style = default_style)
          meta = meta_for_style(style)
          w = meta[:width]
          h = meta[:height]
          "#{w}#{h && "x#{h}"}" if w || h
        end
        alias_method :image_size, :dimensions

      private

        def meta_for_style(style)
          read_meta.try(:[], style) || {}
        end

        def read_meta
          encoded = instance_read(:meta)
          encoded && Marshal.load(Base64.decode64(encoded))
        end

        def write_meta(meta)
          instance_write(:meta, Base64.encode64(Marshal.dump(meta)))
        end
      end
    end
  end
end
