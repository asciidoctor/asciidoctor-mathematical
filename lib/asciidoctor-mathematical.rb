RUBY_ENGINE == 'opal' ? (require 'asciidoctor-mathematical/extension') : (require_relative 'asciidoctor-mathematical/extension')

Extensions.register do
  preprocessor MathematicalPreprocessor
  treeprocessor MathematicalTreeprocessor
end
