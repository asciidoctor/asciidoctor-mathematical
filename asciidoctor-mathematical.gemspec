# -*- encoding: utf-8 -*-
require File.expand_path('lib/asciidoctor-mathematical/version',
                         File.dirname(__FILE__))

Gem::Specification.new do |s|
  s.name        = 'asciidoctor-mathematical'
  s.version     = Asciidoctor::Mathematical::VERSION
  s.date        = '2017-01-09'
  s.summary     = "Asciidoctor STEM processor based on Mathematical"
  s.description = "An Asciidoctor extension to converts latexmath equations to SVG or PNGs"
  s.authors     = ["Tobias Stumm", "Zhang Yang", "Dan Allen"]
  s.email       = 'tstumm@users.noreply.github.com'
  s.files       = ["lib/asciidoctor-mathematical", "lib/asciidoctor-mathematical/extension.rb", "lib/asciidoctor-mathematical.rb"]
  s.homepage    = 'https://github.com/tstumm/asciidoctor-mathematical'
  s.license     = 'MIT'
  s.add_runtime_dependency 'mathematical', '~> 1.6.0'
  s.add_runtime_dependency 'latexmath', '~> 0.1.5'
  s.add_runtime_dependency 'asciidoctor', '~> 2.0'
  s.add_runtime_dependency 'asciimath', '~> 2.0'
  s.add_development_dependency 'rake', '~> 12.3.0'
end
