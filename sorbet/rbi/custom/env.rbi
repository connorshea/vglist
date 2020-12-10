# typed: strict

# This is a bit of a hack to enable usage of methods like `Rails.env.test?`.
class ActiveSupport::StringInquirer
  sig { returns(T::Boolean) }
  def development?; end

  sig { returns(T::Boolean) }
  def test?; end

  sig { returns(T::Boolean) }
  def production?; end
end
