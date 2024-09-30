# frozen_string_literal: true

require_relative 'lib/torque/admin/version'
require 'date'

Gem::Specification.new do |spec|
  spec.name        = 'torque-admin'
  spec.version     = Torque::Admin::VERSION
  spec.date        = Date.today.to_s
  spec.authors     = ['Carlos Silva']
  spec.email       = ['me@carlosfsilva.com']
  spec.homepage    = 'https://github.com/crashtech/torque-admin'
  spec.summary     = 'Pristine Rails Admin Engine that uses Hotwire and known front-end Frameworks'
  spec.description = 'A brand new Rails Admin Engine that uses Hotwire and known front-end Frameworks to provide a better experience for developers and users.'
  spec.license     = 'MIT'

  spec.metadata    = {
    # 'homepage_uri'    => 'https://torque.dev/admin',
    "source_code_uri" => 'https://github.com/crashtech/torque-admin',
    'bug_tracker_uri' => 'https://github.com/crashtech/torque-admin/issues',
    'changelog_uri'   => 'https://github.com/crashtech/torque-admin/releases',
  }

  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.0.0'

  spec.files        = Dir['LICENSE.txt', 'lib/**/*', 'sig/**/*', 'Rakefile']
  spec.test_files   = Dir['spec/**/*']
  spec.rdoc_options = ['--title', 'Torque Admin']

  spec.add_dependency 'rails', '>= 7.0'
end
