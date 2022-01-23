# typed: strict

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `ActionMailer::Parameterized::DeliveryJob`.
# Please instead update this file by running `bin/tapioca dsl ActionMailer::Parameterized::DeliveryJob`.

class ActionMailer::Parameterized::DeliveryJob
  class << self
    sig { params(mailer: T.untyped, mail_method: T.untyped, delivery_method: T.untyped, params: T.untyped, args: T.untyped).returns(T.any(ActionMailer::Parameterized::DeliveryJob, FalseClass)) }
    def perform_later(mailer, mail_method, delivery_method, params, *args); end

    sig { params(mailer: T.untyped, mail_method: T.untyped, delivery_method: T.untyped, params: T.untyped, args: T.untyped).returns(T.untyped) }
    def perform_now(mailer, mail_method, delivery_method, params, *args); end
  end
end
