module ReleasesHelper
  # Checks if the user has the given release in their library.
  # This is probably pretty slow and should be optimized.
  def release_in_user_library?(release)
    return true if current_user.release_purchases.find_by(release_id: release.id).present?

    false
  end
end
