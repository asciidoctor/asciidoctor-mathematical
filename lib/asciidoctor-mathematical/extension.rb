require 'pathname'
require 'asciidoctor/extensions'
require 'asciimath'

autoload :Digest, 'digest'
autoload :Mathematical, 'mathematical'

class MathematicalTreeprocessor < Asciidoctor::Extensions::Treeprocessor
  LineFeed = %(\n)
  StemInlineMacroRx = /\\?(?:stem|latexmath|asciimath):([a-z,]*)\[(.*?[^\\])\]/m
  LatexmathInlineMacroRx = /\\?latexmath:([a-z,]*)\[(.*?[^\\])\]/m
  AsciiMathInlineMacroRx = /\\?asciimath:([a-z,]*)\[(.*?[^\\])\]/m

  def process document
    return unless document.attr? 'stem'

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

    (document.find_by context: :stem, traverse_documents: true).each do |stem|
      handle_stem_block stem, mathematical, image_output_dir, image_target_dir, format, inline
    end

    document.find_by(traverse_documents: true) {|b|
      (b.content_model == :simple && (b.subs.include? :macros)) || b.context == :list_item
    }.each do |prose|
      handle_prose_block prose, mathematical, image_output_dir, image_target_dir, format, inline
    end

    (document.find_by content: :section).each do |sect|
      handle_section_title sect, mathematical, image_output_dir, image_target_dir, format, inline
    end

    nil
  end

  def handle_stem_block(stem, mathematical, image_output_dir, image_target_dir, format, inline)
    equation_type = stem.style.to_sym

    case equation_type
    when :latexmath
      content = stem.content
    when :asciimath
      content = AsciiMath.parse(stem.content).to_latex
    else
      return
    end

    img_target, img_width, img_height = make_equ_image content, stem.id, false, mathematical, image_output_dir, image_target_dir, format, inline

    parent = stem.parent
    if inline
      stem_image = create_pass_block parent, %{<div class="stemblock"> #{img_target} </div>}, {}
      parent.blocks[parent.blocks.index stem] = stem_image
    else
      alt_text = stem.attr 'alt', (equation_type == :latexmath ? %($$#{content}$$) : %(`#{content}`))
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
    if prose.context == :list_item || prose.context == :table_cell
      use_text_property = true
      text = prose.instance_variable_get :@text
    else
      text = prose.lines * LineFeed
    end
    text, source_modified = handle_inline_stem prose, text, mathematical, image_output_dir, image_target_dir, format, inline
    if source_modified
      if use_text_property
        prose.text = text
      else
        prose.lines = text.split LineFeed
      end
    end
  end

  def handle_section_title(sect, mathematical, image_output_dir, image_target_dir, format, inline)
    text = sect.instance_variable_get :@title
    text, source_modified = handle_inline_stem sect, text, mathematical, image_output_dir, image_target_dir, format, inline
    sect.title = text if source_modified
  end

  def handle_inline_stem(node, text, mathematical, image_output_dir, image_target_dir, format, inline)
    document = node.document
    to_html = document.basebackend? 'html'

    case document.attr 'stem'
    when 'latexmath'
      support_stem_prefix = true
      stem_rx = LatexmathInlineMacroRx
    when 'asciimath'
      support_stem_prefix = true
      stem_rx = AsciiMathInlineMacroRx
    else
      support_stem_prefix = false
      stem_rx = StemInlineMacroRx
    end

    source_modified = false

    # TODO skip passthroughs in the source (e.g., +stem:[x^2]+)
    if text != nil && (text.include? ':')
      text = text.gsub(stem_rx) {
        if (m = $~)[0].start_with? '\\'
          next m[0][1..-1]
        end

        if (eq_data = m[2].rstrip).empty?
          next
        else
          source_modified = true
        end

        if text.include? 'asciimath:'
          eq_data = AsciiMath.parse(eq_data).to_latex
        elsif (support_stem_prefix && (text.include? 'stem:')) || (text.include? 'latexmath:')
          eq_data.gsub! '\]', ']'
          subs = m[1].nil_or_empty? ? (to_html ? [:specialcharacters] : []) : (node.resolve_pass_subs m[1])
          eq_data = node.apply_subs eq_data, subs unless subs.empty?
        else
          source_modified = false
          return text
        end
          
        img_target, img_width, img_height = make_equ_image eq_data, nil, true, mathematical, image_output_dir, image_target_dir, format, inline
        if inline
          %(pass:[<span class="steminline"> #{img_target} </span>])
        else
          %(image:#{img_target}[width=#{img_width},height=#{img_height}])
        end
      }
    end

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

  def image_output_and_target_dir(doc)
    output_dir = doc.attr('imagesoutdir')
    if output_dir
      if doc.attr('imagesdir').nil_or_empty?
        target_dir = output_dir
      else
        # When imagesdir attribute is set, every relative path is prefixed with it. So the real target dir shall then be relative to the imagesdir, instead of being relative to document root.
        abs_imagesdir = ::Pathname.new doc.normalize_system_path(doc.attr('imagesdir'))
        abs_outdir = ::Pathname.new doc.normalize_system_path(output_dir)
        target_dir = abs_outdir.relative_path_from(abs_imagesdir).to_s
      end
    else
      output_dir = doc.attr('imagesdir')
      # since we store images directly to imagesdir, target dir shall be NULL and asciidoctor converters will prefix imagesdir.
      target_dir = "."
    end

    output_dir = doc.normalize_system_path(output_dir, doc.attr('docdir'))
    return [output_dir, target_dir]
  end

end
