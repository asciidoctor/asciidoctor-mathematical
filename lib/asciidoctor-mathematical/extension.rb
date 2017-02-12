require 'pathname'
require 'asciidoctor/extensions'

autoload :Digest, 'digest'
autoload :Mathematical, 'mathematical'

class MathematicalTreeprocessor < Asciidoctor::Extensions::Treeprocessor
  LineFeed = %(\n)
  StemInlineMacroRx = /\\?(?:stem|latexmath):([a-z,]*)\[(.*?[^\\])\]/m
  LatexmathInlineMacroRx = /\\?latexmath:([a-z,]*)\[(.*?[^\\])\]/m

  def process document
    format = ((document.attr 'mathematical-format') || 'png').to_sym
    if format != :png and format != :svg
      warn %(Unknown format '#{format}', retreat to 'png')
      format = :png
    end
    ppi = ((document.attr 'mathematical-ppi') || '300.0').to_f
    ppi = format == :png ? ppi : 72.0
    # The no-args constructor defaults to SVG and standard delimiters ($..$ for inline, $$..$$ for block)
    mathematical = ::Mathematical.new format: format, ppi: ppi
    image_output_dir, image_target_dir = image_output_and_target_dir document

    unless (stem_blocks = document.find_by context: :stem).nil_or_empty?
      ::Asciidoctor::Helpers.mkdir_p image_output_dir unless ::File.directory? image_output_dir
      stem_blocks.each do |stem|
        handle_stem_block stem, mathematical, image_output_dir, image_target_dir, format
      end
    end

    unless (prose_blocks = document.find_by {|b|
          (b.content_model == :simple && (b.subs.include? :macros)) || b.context == :list_item
        }).nil_or_empty?
      ::Asciidoctor::Helpers.mkdir_p image_output_dir unless ::File.directory? image_output_dir
      prose_blocks.each do |prose|
        handle_prose_block prose, mathematical, image_output_dir, image_target_dir, format
      end
    end

    # handle table cells of the "asciidoc" type, as suggested by mojavelinux
    # at asciidoctor/asciidoctor-mathematical#20.
    unless (table_blocks = document.find_by context: :table).nil_or_empty?
      table_blocks.each do |table|
        (table.rows[:body] + table.rows[:foot]).each do |row|
          row.each do |cell|
            if cell.style == :asciidoc
              process cell.inner_document
            end
          end
        end
      end
    end

    nil
  end

  def handle_stem_block(stem, mathematical, image_output_dir, image_target_dir, format)
    equation_type = stem.style.to_sym
    return unless equation_type == :latexmath

    img_target, img_width, img_height = make_equ_image stem.content, stem.id, false, mathematical, image_output_dir, image_target_dir, format

    alt_text = stem.attr 'alt', %($$#{stem.content}$$)
    attrs = { 'target' => img_target, 'alt' => alt_text, 'align' => 'center' }
    # NOTE: The following setups the *intended width and height in pixel* for png images, which can be different that that of the generated image when PPIs larger than 72.0 is used.
    if format == :png
      attrs['width'] = %(#{img_width})
      attrs['height'] = %(#{img_height})
    end
    parent = stem.parent
    stem_image = create_image_block parent, attrs
    stem_image.id = stem.id if stem.id
    if (title = stem.attributes['title'])
      stem_image.title = title
    end
    parent.blocks[parent.blocks.index stem] = stem_image
  end

  def handle_prose_block(prose, mathematical, image_output_dir, image_target_dir, format)
    document = prose.document
    to_html = document.basebackend? 'html'
    support_stem_prefix = document.attr? 'stem', 'latexmath'
    stem_rx = support_stem_prefix ? StemInlineMacroRx : LatexmathInlineMacroRx

    source_modified = false
    source = prose.context == :list_item ? (prose.instance_variable_get :@text) : (prose.lines * LineFeed)
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
      eq_data = prose.apply_subs eq_data, subs unless subs.empty?
      img_target, img_width, img_height = make_equ_image eq_data, nil, true, mathematical, image_output_dir, image_target_dir, format
      %(image:#{img_target}[width=#{img_width},height=#{img_height}])
    } if (source != nil) && (source.include? ':') && ((support_stem_prefix && (source.include? 'stem:')) || (source.include? 'latexmath:'))

    if source_modified
      if prose.context == :list_item
        prose.instance_variable_set :@text, source
      else
        prose.lines = source.split LineFeed
      end
    end
  end

  def make_equ_image(equ_data, equ_id, equ_inline, mathematical, image_output_dir, image_target_dir, format)
    input = equ_inline ? %($#{equ_data}$) : %($$#{equ_data}$$)

    unless equ_id
      equ_id = %(stem-#{::Digest::MD5.hexdigest input})
    end
    image_ext = %(.#{format})
    img_target = %(#{equ_id}#{image_ext})
    img_file = ::File.join image_output_dir, img_target

    # TODO: Handle exceptions.
    result = mathematical.parse input
    ::IO.write img_file, result[:data]

    img_target = ::File.join image_target_dir, img_target unless image_target_dir == '.'
    [img_target, result[:width], result[:height]]
  end

  def image_output_and_target_dir(parent)
    document = parent.document

    output_dir = parent.attr('imagesoutdir')
    if output_dir
      base_dir = nil
      if parent.attr('imagesdir').nil_or_empty?
        target_dir = output_dir
      else
        # When imagesdir attribute is set, every relative path is prefixed with it. So the real target dir shall then be relative to the imagesdir, instead of being relative to document root.
        doc_outdir = parent.attr('outdir') || (document.respond_to?(:options) && document.options[:to_dir])
        abs_imagesdir = parent.normalize_system_path(parent.attr('imagesdir'), doc_outdir)
        abs_outdir = parent.normalize_system_path(output_dir, base_dir)
        p1 = ::Pathname.new abs_outdir
        p2 = ::Pathname.new abs_imagesdir
        target_dir = p1.relative_path_from(p2).to_s
      end
    else
      base_dir = parent.attr('outdir') || (document.respond_to?(:options) && document.options[:to_dir])
      output_dir = parent.attr('imagesdir')
      # since we store images directly to imagesdir, target dir shall be NULL and asciidoctor converters will prefix imagesdir.
      target_dir = "."
    end

    output_dir = parent.normalize_system_path(output_dir, base_dir)
    return [output_dir, target_dir]
  end

end
