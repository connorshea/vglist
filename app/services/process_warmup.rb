# frozen_string_literal: true

# Work that every process would otherwise do on its first requests, done once
# in Puma's master process before it forks the workers (see config/puma.rb),
# so the workers inherit the results and their first requests don't pay for
# it.
#
# Eager loading loads the code, but each model still reads its columns from
# Postgres the first time it's used, one catalog query per table. A game page
# touches ~20 tables, so right after a deploy its first requests made ~50
# schema queries on top of their own, while also competing for CPU with the
# other worker doing the same.
module ProcessWarmup
  module_function

  # Never raises: if this fails (say, the database is briefly unreachable),
  # the workers just do the work themselves, as they did before.
  def run
    load_model_schemas
    OperationAllowlist.canonical_documents if OperationAllowlist.enabled?
  rescue StandardError => e
    Rails.logger.warn("ProcessWarmup failed: #{e.class}: #{e.message}")
  ensure
    # Connections can't be shared with forked children. Rails would discard
    # them in each worker anyway, but don't leave them open in the master.
    ActiveRecord::Base.connection_pool.disconnect!
  end

  # Load every model's columns and define its attribute methods. Both are
  # stored on the model class, so forked workers keep them.
  def load_model_schemas
    ActiveRecord::Base.descendants.each do |model|
      next if model.abstract_class?

      model.load_schema
      model.define_attribute_methods
    end
  end
end
