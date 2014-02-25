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
            meta[style] = meta_from_file(file)
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
          m = meta_for_style(style)
          w = m[:width]
          h = m[:height]
          "#{w}#{h && "x#{h}"}" if w || h
        end
        alias_method :image_size, :dimensions

      private

        def meta_from_file(file)
          m = {size: file.size}
          begin
            geo = Geometry.from_file file
            m[:width] = geo.width.to_i
            m[:height] = geo.height.to_i
          rescue Paperclip::Errors::NotIdentifiedByImageMagickError
          end
          m
        end

        def meta_for_style(style)
          read_meta.try(:[], style) || {}
        end

        def read_meta
          if encoded = instance_read(:meta)
            meta = {}
            encoded.split(',').each do |s|
              if s =~ %r{\A(.*):(\d+)?/(\d+)?x(\d+)?\z}
                meta[$1.to_sym] = {size: $2.to_i, width: $3 && $3.to_i, height: $4 && $4.to_i}
              end
            end
            meta
          end
        end

        def write_meta(meta)
          instance_write(:meta, meta.map do |style, m|
            "#{style}:#{m[:size]}/#{m[:width]}x#{m[:height]}"
          end.join(','))
        end
      end
    end
  end
end
