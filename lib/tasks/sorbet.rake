# typed: false
# These Rake tasks are meant to make using Sorbet easier.
namespace :sorbet do
  desc "Run Sorbet's typechecker."
  task tc: :environment do
    Bundler.with_unbundled_env do
      system('bundle exec srb tc')
    end
  end

  desc "Suggest 'typed' comments for each file in the repository."
  task suggest: :environment do
    Bundler.with_unbundled_env do
      system('bundle exec srb rbi suggest-typed')
    end
  end

  # Credit to https://github.com/jaredbeck/sorbet-progress for a lot of this.
  desc "Prints stats for Sorbet's progress in the repository."
  task stats: :environment do
    metrics = {}
    Bundler.with_unbundled_env do
      system('bundle exec srb tc --metrics-file tmp/sorbet_metrics.json')
      json = JSON.parse(File.read('tmp/sorbet_metrics.json'))
      metrics = json['metrics']
    end

    key_map = {
      total_signatures: "ruby_typer.unknown..types.sig.count",
      total_methods: "ruby_typer.unknown..types.input.methods.total",
      total_classes: "ruby_typer.unknown..types.input.classes.total",
      sigil_ignore: "ruby_typer.unknown..types.input.files.sigil.ignore",
      sigil_autogenerated: "ruby_typer.unknown..types.input.files.sigil.autogenerated",
      sigil_false: "ruby_typer.unknown..types.input.files.sigil.false",
      sigil_true: "ruby_typer.unknown..types.input.files.sigil.true",
      sigil_strict: "ruby_typer.unknown..types.input.files.sigil.strict",
      sigil_strong: "ruby_typer.unknown..types.input.files.sigil.strong",
      sends: "ruby_typer.unknown..types.input.sends.total",
      sends_typed: "ruby_typer.unknown..types.input.sends.typed"
    }

    metrics_hash = {}

    metrics.each do |metric|
      metrics_hash[metric['name']] = metric['value']
    end

    output_hash = {}
    key_map.each do |key, path|
      # Assign the value as 0 in case the specific path can't be found. (e.g.
      # because there are no files with a given typedness level).
      output_hash[key] = metrics_hash[path] || 0
    end

    sigils = [:sigil_ignore, :sigil_false, :sigil_true, :sigil_strict, :sigil_strong, :sigil_autogenerated]

    sigil_total = 0
    sigils.each do |sigil|
      sigil_total += output_hash[sigil]
    end

    # This has to be done after the sigil total is fully calculated, otherwise
    # it won't work correctly.
    # rubocop:disable Style/CombinableLoops
    sigils.each do |sigil|
      output_hash[sigil] = "#{output_hash[sigil]} (#{(output_hash[sigil].fdiv(sigil_total) * 100).round(2)}%)"
    end
    # rubocop:enable Style/CombinableLoops

    output_hash[:sends_percentage_typed] = \
      "#{(metrics_hash[key_map[:sends_typed]].fdiv(metrics_hash[key_map[:sends]]) * 100).round(2)}%"

    output_hash.each do |key, value|
      puts "#{key.to_s.rjust(25)}: #{value}"
    end
  end

  namespace :update do
    desc "Update Sorbet and Tapioca RBIs."
    task all: :environment do
      Bundler.with_unbundled_env do
        system('SRB_SORBET_TYPED_REPO="https://github.com/sorbet/sorbet-typed.git" SRB_SORBET_TYPED_REVISION="origin/master" bundle exec srb rbi sorbet-typed')
        # We don't want to include the RBI files for these gems since they're not useful.
        puts 'Removing unwanted gem definitions from sorbet-typed...'
        ['rspec-core', 'rake', 'rubocop'].each do |gem|
          FileUtils.remove_dir(Rails.root.join("sorbet/rbi/sorbet-typed/lib/#{gem}")) if Dir.exist?(Rails.root.join("sorbet/rbi/sorbet-typed/lib/#{gem}"))
        end
        system('bundle exec tapioca gem')
        # Generate Tapioca's Rails DSL RBIs.
        system('bundle exec tapioca dsl')
        system('bundle exec rake rails_rbi:all')
        system('bundle exec tapioca todo')
        system('bundle exec srb rbi suggest-typed')
      end
    end
  end

  namespace :tc do
    desc "Run the typechecker as though everything was 'typed: true' (except spec/ files)."
    task all: :environment do
      Bundler.with_unbundled_env do
        # Suppress the error for method redefinition since we end up with a
        # bunch of errors from sorbet-typed.
        system('bundle exec srb tc --typed=true --ignore spec/ --suppress-error-code=4010')
      end
    end

    namespace :all do
      desc "Run the typechecker as though everything was 'typed: strict' (except spec/ files)."
      task strict: :environment do
        Bundler.with_unbundled_env do
          # Suppress the error for method redefinition since we end up with a
          # bunch of errors from sorbet-typed.
          system('bundle exec srb tc --typed=strict --ignore spec/ --suppress-error-code=4010')
        end
      end

      desc "Run the typechecker as though everything was 'typed: strong' (except spec/ files)."
      task strong: :environment do
        Bundler.with_unbundled_env do
          # Suppress the error for method redefinition since we end up with a
          # bunch of errors from sorbet-typed.
          system('bundle exec srb tc --typed=strong --ignore spec/ --suppress-error-code=4010')
        end
      end
    end
  end
end
