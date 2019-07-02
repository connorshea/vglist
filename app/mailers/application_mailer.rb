# typed: strict
class ApplicationMailer < ActionMailer::Base
  default from: 'noreply@vglist.co'
  layout 'mailer'
end
