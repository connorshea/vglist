# typed: strict
# This only gets loaded by Rails when the `SRB_YES` environment variable is present (this is checked in `config/application.rb`)
require 'sparql'
require 'sparql/client'
require 'graphql/rake_task'
require 'selenium/webdriver'
require 'rspec/expectations'
require 'rdf'
require 'rack'
