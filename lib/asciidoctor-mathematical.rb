require_relative 'asciidoctor-mathematical/extension'

Asciidoctor::Extensions.register do
  treeprocessor MathematicalTreeprocessor
end
