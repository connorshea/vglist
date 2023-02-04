# typed: true

# This is a monkey patch to override a dumb type signature in actionpack.rbi.
module ParamsMonkeyPatch
  extend T::Sig

  sig { params(args: T.untyped).returns(ActionController::Parameters) }
  def typed_require(*args)
    T.unsafe(self).require(*args)
  end
end

ActionController::Parameters.include ParamsMonkeyPatch
