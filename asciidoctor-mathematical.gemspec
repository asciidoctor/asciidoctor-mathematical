# -*- encoding: utf-8 -*-
require File.expand_path('lib/asciidoctor-mathematical/version',
                         File.dirname(__FILE__))

Gem::Specification.new do |s|
  s.name        = 'asciidoctor-mathematical'
  s.version     = Asciidoctor::Mathematical::VERSION
  s.date        = '2016-08-21'
  s.summary     = "Asciidoctor STEM processor based on Mathematical"
  s.description = "An Asciidoctor extension to converts latexmath equations to SVG or PNGs"
  s.authors     = ["Tobias Stumm", "Zhang Yang", "Dan Allen"]
  s.email       = 'tstumm@users.noreply.github.com'
  s.files       = ["lib/asciidoctor-mathematical", "lib/asciidoctor-mathematical/extension.rb", "lib/asciidoctor-mathematical.rb"]
  s.homepage    =
    'https://github.com/tstumm/asciidoctor-mathematical'
  s.license       = 'MIT'
  s.add_dependency 'ruby-enum', '~> 0.4'
  s.add_runtime_dependency 'mathematical', '~> 1.5', '>= 1.5.8'
  s.add_runtime_dependency "asciidoctor", '~> 1.5', '>= 1.5.0'
end
