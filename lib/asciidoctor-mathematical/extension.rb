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
    inline = document.attr 'mathematical-inline'
    if inline and format == :png
      warn 'Can\'t use mathematical-inline together with mathematical-format=png'
    end
    # The no-args constructor defaults to SVG and standard delimiters ($..$ for inline, $$..$$ for block)
    mathematical = ::Mathematical.new format: format, ppi: ppi
    unless inline
      image_output_dir, image_target_dir = image_output_and_target_dir document
      ::Asciidoctor::Helpers.mkdir_p image_output_dir unless ::File.directory? image_output_dir
    end

    unless (stem_blocks = document.find_by context: :stem).nil_or_empty?
      stem_blocks.each do |stem|
        handle_stem_block stem, mathematical, image_output_dir, image_target_dir, format, inline
      end
    end

    unless (prose_blocks = document.find_by {|b|
      (b.content_model == :simple && (b.subs.include? :macros)) || b.context == :list_item
    }).nil_or_empty?
      prose_blocks.each do |prose|
        handle_prose_block prose, mathematical, image_output_dir, image_target_dir, format, inline
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
            elsif cell.style != :literal
              handle_nonasciidoc_table_cell cell, mathematical, image_output_dir, image_target_dir, format, inline
            end
          end
        end
      end
    end

    unless (sect_blocks = document.find_by content: :section).nil_or_empty?
      sect_blocks.each do |sect|
        handle_section_title sect, mathematical, image_output_dir, image_target_dir, format, inline
      end
    end

    nil
  end

  def handle_stem_block(stem, mathematical, image_output_dir, image_target_dir, format, inline)
    equation_type = stem.style.to_sym
    return unless equation_type == :latexmath

    img_target, img_width, img_height = make_equ_image stem.content, stem.id, false, mathematical, image_output_dir, image_target_dir, format, inline

    parent = stem.parent
    if inline
      stem_image = create_pass_block parent, %{<div class="stemblock"> #{img_target} </div>}, {}
      parent.blocks[parent.blocks.index stem] = stem_image
    else
      alt_text = stem.attr 'alt', %($$#{stem.content}$$)
      attrs = {'target' => img_target, 'alt' => alt_text, 'align' => 'center'}
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
  end

  def handle_prose_block(prose, mathematical, image_output_dir, image_target_dir, format, inline)
    text = prose.context == :list_item ? (prose.instance_variable_get :@text) : (prose.lines * LineFeed)
    text, source_modified = handle_inline_stem prose, text, mathematical, image_output_dir, image_target_dir, format, inline
    if source_modified
      if prose.context == :list_item
        prose.instance_variable_set :@text, text
      else
        prose.lines = text.split LineFeed
      end
    end
  end

  def handle_nonasciidoc_table_cell(cell, mathematical, image_output_dir, image_target_dir, format, inline)
    text = cell.instance_variable_get :@text
    text, source_modified = handle_inline_stem cell, text, mathematical, image_output_dir, image_target_dir, format, inline
    if source_modified
      cell.instance_variable_set :@text, text
    end
  end

  def handle_section_title(sect, mathematical, image_output_dir, image_target_dir, format, inline)
    text = sect.instance_variable_get :@title
    text, source_modified = handle_inline_stem sect, text, mathematical, image_output_dir, image_target_dir, format, inline
    if source_modified
      sect.instance_variable_set :@title, text
      sect.remove_instance_variable :@subbed_title
    end
  end

  def handle_inline_stem(node, text, mathematical, image_output_dir, image_target_dir, format, inline)
    document = node.document
    to_html = document.basebackend? 'html'
    support_stem_prefix = document.attr? 'stem', 'latexmath'
    stem_rx = support_stem_prefix ? StemInlineMacroRx : LatexmathInlineMacroRx

    source_modified = false
    # TODO skip passthroughs in the source (e.g., +stem:[x^2]+)
    text = text.gsub(stem_rx) {
      if (m = $~)[0].start_with? '\\'
        next m[0][1..-1]
      end

      if (eq_data = m[2].rstrip).empty?
        next
      else
        source_modified = true
      end

      eq_data.gsub! '\]', ']'
      subs = m[1].nil_or_empty? ? (to_html ? [:specialcharacters] : []) : (node.resolve_pass_subs m[1])
      eq_data = node.apply_subs eq_data, subs unless subs.empty?
      img_target, img_width, img_height = make_equ_image eq_data, nil, true, mathematical, image_output_dir, image_target_dir, format, inline
      if inline
        %(pass:[<span class="steminline"> #{img_target} </span>])
      else
        %(image:#{img_target}[width=#{img_width},height=#{img_height}])
      end
    } if (text != nil) && (text.include? ':') && ((support_stem_prefix && (text.include? 'stem:')) || (text.include? 'latexmath:'))

    [text, source_modified]
  end

  def make_equ_image(equ_data, equ_id, equ_inline, mathematical, image_output_dir, image_target_dir, format, inline)
    input = equ_inline ? %($#{equ_data}$) : %($$#{equ_data}$$)

    # TODO: Handle exceptions.
    result = mathematical.parse input
    if inline
      result[:data]
    else
      unless equ_id
        equ_id = %(stem-#{::Digest::MD5.hexdigest input})
      end
      image_ext = %(.#{format})
      img_target = %(#{equ_id}#{image_ext})
      img_file = ::File.join image_output_dir, img_target

      ::IO.write img_file, result[:data]

      img_target = ::File.join image_target_dir, img_target unless image_target_dir == '.'
      [img_target, result[:width], result[:height]]
    end
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
