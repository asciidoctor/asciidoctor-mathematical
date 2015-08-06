require 'asciidoctor/extensions' unless RUBY_ENGINE == 'opal'
require 'mathematical'
autoload :Digest, 'digest'

include ::Asciidoctor

class MathematicalTreeprocessor < Extensions::Treeprocessor
  def process document
    if (stem_blocks = document.find_by context: :stem)
      format = :png
      if document.attributes['mathematical-format']
        format_str = document.attributes['mathematical-format']
        if format_str == 'png'
          format = :png
        elsif format_str == 'svg'
          format = :svg
        end
      end
      image_postfix = ".#{format}"
      scale = 1.0
      if format == :png
        scale = 72.0/300.0
      end
      ppi = 72.0
      if format == :png
        ppi = 300.0
      end
      # The no-args constructor defaults to SVG and standard delimiters ($..$ for inline, $$..$$ for block)
      mathematical = ::Mathematical.new({ :format => format, :ppi => ppi })
      image_output_dir = resolve_image_output_dir document
      image_target_dir = document.attr 'imagesoutdir', (document.attr 'imagesdir')
      image_target_dir = '.' if image_target_dir.nil_or_empty?
      ::FileUtils.mkdir_p image_output_dir unless ::File.directory? image_output_dir

      stem_blocks.each do |stem|
        equation_data = %($$#{stem.content}$$)
        equation_type = stem.style.to_sym
        next unless equation_type == :latexmath

        # FIXME auto-generate id if one is not provided
        unless (stem_id = stem.id)
          stem_id = %(stem-#{::Digest::MD5.hexdigest stem.content})
        end

        alt_text = stem.attr 'alt', equation_data

        image_target = %(#{stem_id}#{image_postfix})
        image_file = ::File.join image_output_dir, image_target
        image_target = ::File.join image_target_dir, image_target unless image_target_dir == '.'

        # TODO check for error
        result = mathematical.parse equation_data
        ::IO.write image_file, result[:data]

        attrs = { 'target' => image_target, 'alt' => alt_text, 'align' => 'center' }
        if format == :png
          attrs['width'] = "#{result[:width]}pt"
          attrs['height'] = "#{result[:height]}pt"
        end
        parent = stem.parent
        stem_image = create_image_block parent, attrs
        stem_image.id = stem.id if stem.id
        if (title = stem.attributes['title'])
          stem_image.title = title
        end
        parent.blocks[parent.blocks.index stem] = stem_image
      end
    end
    nil
  end

  def resolve_image_output_dir doc
    if (images_dir = doc.attr 'imagesoutdir')
      base_dir = nil
    else
      base_dir = (doc.attr 'outdir') || ((doc.respond_to? :options) && doc.options[:to_dir])
      images_dir = doc.attr 'imagesdir'
    end

    doc.normalize_system_path images_dir, base_dir
  end
end

class MathematicalPreprocessor < Extensions::Preprocessor
  LATEXMATH_PTN = /latexmath:\[([^\]]+)\]/
  def process document, reader
    # Setup image format information
    format = :png
    if document.attributes['mathematical-format']
      format_str = document.attributes['mathematical-format']
      if format_str == 'png'
        format = :png
      elsif format_str == 'svg'
        format = :svg
      end
    end
    image_postfix = ".#{format}"
    scale = 1.0
    if format == :png
      scale = 72.0/300.0
    end
    ppi = 72.0
    if format == :png
      ppi = 300.0
    end

    # Since at preprocessing stage, we have no document attribute avaliable,
    # so fix the image output dir to be simple.
    image_output_dir = './images'
    image_target_dir = './images'
    ::FileUtils.mkdir_p image_output_dir unless ::File.directory? image_output_dir

    mathematical = ::Mathematical.new({ :format => format, :ppi => ppi })

    lines = reader.readlines
    lines.each do |line|
      md = LATEXMATH_PTN.match line
      while md
        stem_content = md[1]
        equation_data = %($#{stem_content}$)
        stem_id = %(stem-#{::Digest::MD5.hexdigest stem_content})

        image_target = %(#{stem_id}#{image_postfix})
        image_file = ::File.join image_output_dir, image_target
        image_target = ::File.join image_target_dir, image_target unless image_target_dir == '.'

        # TODO check for error
        result = mathematical.parse equation_data
        ::IO.write image_file, result[:data]

        subst = %(image:#{image_target}[width=#{result[:width]}pt])
        line.gsub! md[0], subst
        md = LATEXMATH_PTN.match md.post_match
      end
    end

    reader.unshift_lines lines
    reader
  end
end
