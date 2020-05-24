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
    puts Dir.pwd.inspect
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
          FileUtils.cp("./graphiql.js", "#{VGLIST_DIR}/app/javascript/vendor/graphiql-#{new_version}.js")
          FileUtils.cp("./graphiql.css", "#{VGLIST_DIR}/app/javascript/vendor/graphiql-#{new_version}.css")
        end

        FileUtils.cd("./node_modules/react") do
          new_version = npm_version("./package.json")
          new_js_versions["react"] = new_version

          puts "Copying React #{new_version}"
          FileUtils.cp("./umd/react.development.js", "#{VGLIST_DIR}/app/javascript/vendor/react-#{new_version}.js")
        end

        FileUtils.cd("./node_modules/react-dom") do
          new_version = npm_version("./package.json")
          new_js_versions["react-dom"] = new_version

          puts "Copying ReactDOM #{new_version}"
          FileUtils.cp("./umd/react-dom.development.js", "#{VGLIST_DIR}/app/javascript/vendor/react-dom-#{new_version}.js")
        end
      end
    end
  end
end
