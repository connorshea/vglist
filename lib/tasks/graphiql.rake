# typed: false

namespace :graphiql do
  desc "Generate vendored files for use with GraphiQL"
  task generate: :environment do
    require 'tmpdir'
    require 'fileutils'
    require 'json'

    new_js_versions = {}
    new_css_versions = {}

    def npm_version(package_json_path)
      npm_config = JSON.parse(File.read(package_json_path))
      npm_config["version"]
    end

    VGLIST_DIR = Dir.pwd
    Dir.mktmpdir do |dir|
      puts "My new temp dir: #{dir}"
      FileUtils.cd(dir) do
        sh("npm init --force")
        sh("npm install graphiql@1.0.0-alpha.10 react react-dom")

        FileUtils.cd("./node_modules/graphiql") do
          new_version = npm_version("./package.json")
          new_js_versions["graphiql"] = new_version
          new_css_versions["graphiql"] = new_version

          puts "Copying GraphiQL #{new_version}"
          # sh('ls ./dist/')
          FileUtils.cp("./graphiql.min.js", "#{VGLIST_DIR}/app/javascript/src/vendor/graphiql-#{new_version}.static.js")
          FileUtils.cp("./graphiql.min.css", "#{VGLIST_DIR}/app/javascript/src/vendor/graphiql-#{new_version}.css")
        end

        FileUtils.cd("./node_modules/react") do
          new_version = npm_version("./package.json")
          new_js_versions["react"] = new_version

          puts "Copying React #{new_version}"
          FileUtils.cp("./umd/react.production.min.js", "#{VGLIST_DIR}/app/javascript/src/vendor/react-#{new_version}.static.js")
        end

        FileUtils.cd("./node_modules/react-dom") do
          new_version = npm_version("./package.json")
          new_js_versions["react-dom"] = new_version

          puts "Copying ReactDOM #{new_version}"
          FileUtils.cp("./umd/react-dom.production.min.js", "#{VGLIST_DIR}/app/javascript/src/vendor/react-dom-#{new_version}.static.js")
        end
      end
    end
  end
end
