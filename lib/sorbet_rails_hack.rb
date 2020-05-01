# typed: false
module SorbetRailsHack
  extend T::Sig

  # Removed from SorbetRails in 0.7.0, so we're reproducing it ourselves here.
  sig do
    type_parameters(:U)
      .params(key: Symbol, type_assert: ITypeAssert[T.type_parameter(:U)])
      .returns(T.type_parameter(:U))
  end
  def require_typed(key, type_assert)
    val = require(key)
    type_assert.assert(val)
  rescue TypeError
    raise ActionController::BadRequest,
      "Expected parameter #{key} to be an instance of type #{type_assert.get_type}, got `#{val}`"
  end

  # This is a disgusting hack to make `params.require` less verbose for its
  # most common case. I am not proud of what I have done.
  sig { params(key: Symbol).returns(ActionController::Parameters) }
  def typed_require(key)
    require_typed(key, TA[ActionController::Parameters].new)
  end
end
