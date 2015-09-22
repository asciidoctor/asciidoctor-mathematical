Gem::Specification.new do |s|
  s.name        = 'asciidoctor-mathematical'
  s.version     = '0.0.5'
  s.date        = '2015-09-22'
  s.summary     = "Wrapper for Mathematical"
  s.description = "Converts latexmath equations in Asciidoctor to SVG"
  s.authors     = ["Tobias Stumm", "Zhang Yang"]
  s.email       = 'tstumm@users.noreply.github.com'
  s.files       = ["lib/asciidoctor-mathematical", "lib/asciidoctor-mathematical/extension.rb", "lib/asciidoctor-mathematical.rb"]
  s.homepage    =
    'https://github.com/tstumm/asciidoctor-mathematical'
  s.license       = 'MIT'
  s.add_dependency 'ruby-enum', '~> 0.4'
  s.add_runtime_dependency 'mathematical', '~> 1.5', '>= 1.5.8'
  s.add_runtime_dependency "asciidoctor", '~> 1.5', '>= 1.5.0'
end
