RUBY_ENGINE == 'opal' ? (require 'mathematical-treeprocessor/extension') : (require_relative 'mathematical-treeprocessor/extension')

Extensions.register do
  treeprocessor MathematicalTreeprocessor
end
