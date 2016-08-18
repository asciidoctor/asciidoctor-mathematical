require 'asciidoctor/extensions'

autoload :Digest, 'digest'
autoload :Mathematical, 'mathematical'

class MathematicalTreeprocessor < Asciidoctor::Extensions::Treeprocessor
  LineFeed = %(\n)
  StemInlineMacroRx = /\\?(?:stem|latexmath):([a-z,]*)\[(.*?[^\\])\]/m
  LatexmathInlineMacroRx = /\\?latexmath:([a-z,]*)\[(.*?[^\\])\]/m

  def process document
    to_html = document.basebackend? 'html'
    format = ((document.attr 'mathematical-format') || 'png').to_sym
    image_ext = %(.#{format})
    scale = format == :png ? 72.0/300.0 : 1.0
    ppi = format == :png ? 300.0 : 72.0
    # The no-args constructor defaults to SVG and standard delimiters ($..$ for inline, $$..$$ for block)
    mathematical = ::Mathematical.new format: format, ppi: ppi
    image_output_dir = resolve_image_output_dir document
    image_target_dir = document.attr 'imagesoutdir', (document.attr 'imagesdir')
    image_target_dir = '.' if image_target_dir.nil_or_empty?

    unless (stem_blocks = document.find_by context: :stem).nil_or_empty?
      ::Asciidoctor::Helpers.mkdir_p image_output_dir unless ::File.directory? image_output_dir

      stem_blocks.each do |stem|
        equation_type = stem.style.to_sym
        next unless equation_type == :latexmath
        equation_data = %($$#{stem.content}$$)

        # FIXME auto-generate id if one is not provided
        unless (stem_id = stem.id)
          stem_id = %(stem-#{::Digest::MD5.hexdigest stem.content})
        end

        alt_text = stem.attr 'alt', equation_data

        image_target = %(#{stem_id}#{image_ext})
        image_file = ::File.join image_output_dir, image_target
        image_target = ::File.join image_target_dir, image_target unless image_target_dir == '.'

        # TODO check for error
        result = mathematical.parse equation_data
        ::IO.write image_file, result[:data]

        attrs = { 'target' => image_target, 'alt' => alt_text, 'align' => 'center' }
        if format == :png
          attrs['width'] = %(#{result[:width]}pt)
          attrs['height'] = %(#{result[:height]}pt)
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

    unless (prose_blocks = document.find_by {|b|
          (b.content_model == :simple && (b.subs.include? :macros)) || b.context == :list_item
        }).nil_or_empty?
      support_stem_prefix = document.attr? 'stem', 'latexmath'
      ::Asciidoctor::Helpers.mkdir_p image_output_dir unless ::File.directory? image_output_dir
      stem_rx = support_stem_prefix ? StemInlineMacroRx : LatexmathInlineMacroRx

      prose_blocks.each do |block|
        source_modified = false
        source = block.context == :list_item ? (block.instance_variable_get :@text) : (block.lines * LineFeed)
        # TODO skip passthroughs in the source (e.g., +stem:[x^2]+)
        source.gsub!(stem_rx) {
          if (m = $~)[0].start_with? '\\'
            next m[0][1..-1]
          end

          if (eq_data = m[2].rstrip).empty?
            next
          else
            source_modified = true
          end

          eq_data.gsub! '\]', ']'
          subs = m[1].nil_or_empty? ? (to_html ? [:specialcharacters] : []) : (block.resolve_pass_subs m[1])
          eq_data = block.apply_subs eq_data, subs unless subs.empty?

          eq_id = %(stem-#{::Digest::MD5.hexdigest eq_data})
          eq_input = %($#{eq_data}$)

          img_target = %(#{eq_id}#{image_ext})
          img_file = ::File.join image_output_dir, img_target
          img_target = ::File.join image_target_dir, img_target unless image_target_dir == '.'

          eq_result = mathematical.parse eq_input

          ::IO.write img_file, eq_result[:data]
          %(image:#{img_target}[width=#{eq_result[:width]}])
        } if (source.include? ':') && ((support_stem_prefix && (source.include? 'stem:')) || (source.include? 'latexmath:'))

        if source_modified
          if block.context == :list_item
            block.instance_variable_set :@text, source
          else
            block.lines = source.split LineFeed
          end
        end
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
