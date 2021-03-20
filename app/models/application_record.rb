# typed: strong
class ApplicationRecord < ActiveRecord::Base
  extend T::Sig
  self.abstract_class = true
end
