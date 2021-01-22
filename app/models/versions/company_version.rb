# typed: true
module Versions
  class CompanyVersion < PaperTrail::Version
    self.table_name = :company_versions
  end
end
