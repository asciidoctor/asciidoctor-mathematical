Gem::Specification.new do |s|
  s.name        = 'asciidoctor-mathematical'
  s.version     = '0.0.4'
  s.date        = '2015-07-06'
  s.summary     = "Wrapper for Mathematical"
  s.description = "Converts latexmath equations in Asciidoctor to SVG"
  s.authors     = ["Tobias Stumm"]
  s.email       = 'tstumm@users.noreply.github.com'
  s.files       = ["lib/asciidoctor-mathematical", "lib/asciidoctor-mathematical/extension.rb"]
  s.homepage    =
    'https://github.com/tstumm/asciidoctor-mathematical'
  s.license       = 'MIT'
  s.add_dependency 'ruby-enum', '~> 0.4'
  s.add_runtime_dependency 'mathematical', '~> 1.4', '>= 1.4.2'
  s.add_runtime_dependency "asciidoctor", '~> 1.5', '>= 1.5.0'
end
