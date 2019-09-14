# typed: false
module SorbetRailsHack
  extend T::Sig

  # This is a disgusting hack to make `params.require` less verbose for its
  # most common case. I am not proud of what I have done.
  sig { params(key: Symbol).returns(ActionController::Parameters) }
  def typed_require(key)
    require_typed(key, TA[ActionController::Parameters].new)
  end
end
