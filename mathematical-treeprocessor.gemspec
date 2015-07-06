Gem::Specification.new do |s|
  s.name        = 'mathematical-treeprocessor'
  s.version     = '0.0.3'
  s.date        = '2015-07-06'
  s.summary     = "Wrapper for Mathematical"
  s.description = "Converts latexmath equations in Asciidoctor to SVG"
  s.authors     = ["Tobias Stumm"]
  s.email       = 'tstumm@users.noreply.github.com'
  s.files       = ["lib/mathematical-treeprocessor.rb", "lib/mathematical-treeprocessor/extension.rb"]
  s.homepage    =
    'https://github.com/tstumm/mathematical-treeprocessor'
  s.license       = 'MIT'
  s.add_dependency 'ruby-enum', '~> 0.4'
  s.add_dependency 'mathematical', '~> 1.4.2'
  s.add_runtime_dependency "asciidoctor", "~> 1.5.0"
end
