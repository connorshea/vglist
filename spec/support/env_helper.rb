# typed: false
# Helper to enable mocking ENV variables in tests.
#
# Based on https://stackoverflow.com/questions/9611276/what-is-the-best-way-to-write-specs-for-code-that-depends-on-environment-variabl
module EnvHelper
  def with_environment(replacement_env)
    original_env = ENV.to_hash
    ENV.update(replacement_env)

    yield
  ensure
    ENV.replace(original_env)
  end
end
