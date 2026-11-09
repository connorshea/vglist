# frozen_string_literal: true

namespace :vglist do
  namespace :users do
    # Read-only. Devise downcases and strips emails before saving (see
    # config.case_insensitive_keys / strip_whitespace_keys), so every stored
    # email should already be normalized. This reports any that aren't, plus any
    # groups of users whose emails only differ by case or surrounding
    # whitespace. Both must be empty before adding a unique index on
    # lower(email) or a CHECK constraint that emails are lowercase.
    desc "Report users whose emails aren't normalized or collide when compared case-insensitively"
    task check_email_case: :environment do
      not_normalized = User.where("email <> lower(btrim(email))").pluck(:id, :email)

      duplicates = User.connection.select_rows(<<~SQL.squish)
        SELECT lower(btrim(email)) AS normalized, string_agg(id::text, ', ' ORDER BY id) AS ids
        FROM users
        GROUP BY lower(btrim(email))
        HAVING count(*) > 1
        ORDER BY normalized
      SQL

      puts "Users: #{User.count}"
      puts "Emails not stored lowercase/stripped: #{not_normalized.size}"
      not_normalized.each { |id, email| puts "  user #{id}: #{email.inspect}" }
      puts "Case-insensitive duplicate groups: #{duplicates.size}"
      duplicates.each { |normalized, ids| puts "  #{normalized.inspect}: user IDs #{ids}" }

      puts(not_normalized.empty? && duplicates.empty? ? "OK: all emails are normalized and unique." : "Needs cleanup before adding a case-insensitive constraint.")
    end
  end
end
