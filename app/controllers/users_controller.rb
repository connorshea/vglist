# typed: false
class UsersController < ApplicationController
  # Skip bullet on activity to avoid errors.
  around_action :skip_bullet, if: -> { defined?(Bullet) }

  def index
    # Hide banned users from users that aren't moderators or admins.
    if current_user&.member? || current_user.nil?
      @users = User.where(banned: false)
    elsif current_user&.moderator? || current_user&.admin?
      @users = User.all
    end

    order_by_sym = T.cast(params[:order_by], T.nilable(String))&.to_sym
    if !order_by_sym.nil? && [
      :most_games,
      :most_followers
    ].include?(order_by_sym)
      # Call the scope dynamically.
      @users = @users.public_send(order_by_sym)
    else
      @users = @users.order(:id)
    end

    @users = @users.page helpers.page_param

    skip_policy_scope
  end

  def show
    @user = User.friendly.find(params[:id])
    # The user can access the page, but it'll just have a message about the
    # account being private. The visibility of data is handled in the user
    # view.
    skip_authorization
  end

  def update
    @user = User.friendly.find(params[:id])
    authorize @user

    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, success: "#{@user.username} was successfully updated." }
        format.json { render json: @user, status: :ok, location: @user }
      else
        format.html do
          flash[:error] = "Unable to update user."
          redirect_to settings_path
        end
        format.json { render json: @user.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  def search
    if params[:query].present?
      @users = User.search(params[:query]).page(helpers.page_param)
    else
      @users = User.none.page(helpers.page_param)
    end

    authorize nil, policy_class: UserPolicy

    respond_to do |format|
      format.json { render json: @users }
    end
  end

  def update_role
    @user = User.friendly.find(params[:id])
    role = params.fetch(:role).to_sym

    authorize @user

    unless [:member, :moderator, :admin].include? role
      flash[:error] = "Invalid role."
      redirect_to(user_path(@user.id)) && return
    end

    case role
    when :member
      @user.role = :member
    when :moderator
      @user.role = :moderator
    when :admin
      @user.role = :admin
    end

    redirect_to @user, success: "#{@user.username} was given the role #{params[:role]}." if @user.save
  end

  def remove_avatar
    @user = User.friendly.find(params[:id])
    authorize @user

    @user.avatar&.purge

    respond_to do |format|
      format.html { redirect_to @user, success: "Avatar successfully removed." }
      format.json { render json: @user, status: :ok, location: @user }
    end
  end

  def steam_import
    @user = User.friendly.find(params[:id])
    authorize @user
    # Coerce the value to a boolean.
    @update_hours = params[:update_hours] == 'true'

    @result = SteamImportService.new(user: @user, update_hours: @update_hours).call

    respond_to do |format|
      format.html do
        added_games_count = @result.added_games.count
        unmatched_count = @result.unmatched.count
        updated_games_count = @result.updated_games.count
        flash[:success] = "Added #{added_games_count} #{'game'.pluralize(added_games_count)}. Updated #{updated_games_count} #{'game'.pluralize(updated_games_count)}. #{unmatched_count} games weren't found in the vglist database."
        render
      end
    end
  rescue SteamImportService::NoGamesError
    # If no games are returned, return an error message.
    respond_to do |format|
      format.html do
        flash[:error] = "Unable to find any games in your Steam library. Are you sure it's public and that you've connected the correct account?"
        redirect_to settings_import_path
        return
      end
    end
  end

  def connect_steam
    @user = User.friendly.find(params[:id])
    authorize @user

    # Resolve the numerical Steam ID based on the provided username.
    steam_api_url = "https://api.steampowered.com/ISteamUser/ResolveVanityURL/v1/?key=#{ENV['STEAM_WEB_API_KEY']}&vanityurl=#{params[:steam_username]}"
    json = JSON.parse(T.must(T.must(URI.open(steam_api_url)).read))

    steam_id = json.dig("response", "steamid")

    unless steam_id.nil?
      # If one already exists, don't create it.
      # If not, create it and pass in the steam_id and steam_profile_url.
      @steam_account = ExternalAccount.create_with(
        steam_id: steam_id,
        steam_profile_url: "https://steamcommunity.com/id/#{params[:steam_username]}/"
      ).find_or_create_by!(
        user_id: @user.id,
        account_type: :steam
      )
    end

    respond_to do |format|
      if @steam_account&.save
        format.html do
          flash[:success] = "Steam account successfully connected."
          redirect_to settings_import_path
        end
      else
        format.html do
          flash[:error] = "Unable to find a Steam account with that username."
          redirect_to settings_import_path
        end
      end
    end
  end

  def disconnect_steam
    @user = User.friendly.find(params[:id])
    authorize @user

    @steam_account = ExternalAccount.find_by(user_id: @user.id, account_type: :steam)

    respond_to do |format|
      if @steam_account&.destroy
        format.html do
          flash[:success] = "Successfully disconnected Steam account."
          redirect_to settings_import_path
        end
      else
        format.html do
          flash[:error] = "Unable to disconnect Steam account."
          redirect_to settings_import_path
        end
      end
    end
  end

  def reset_game_library
    @user = User.friendly.find(params[:id])
    authorize @user

    @game_purchases = GamePurchase.where(user_id: @user.id)

    respond_to do |format|
      if @game_purchases.destroy_all
        format.html do
          flash[:success] = "Successfully reset game library."
          redirect_to user_path(@user)
        end
      else
        format.html do
          flash[:error] = "Unable to delete all the games in your library."
          redirect_to settings_account_path
        end
      end
    end
  end

  def statistics
    @user = User.friendly.find(params[:id])
    authorize @user

    game_purchases = @user.game_purchases
    @stats = {}
    total_time_played = game_purchases.sum(:hours_played)
    games_with_ratings = game_purchases.where.not(rating: nil).count
    # Get all game purchases that have a status besides not_applicable.
    games_with_completion_statuses = game_purchases.where.not(completion_status: [nil, :not_applicable]).count

    # Prevent division by zero.
    if games_with_completion_statuses.positive?
      # If a game is completed, fully_completed, or dropped, count it as completed.
      completed_games = game_purchases.where(completion_status: [:completed, :fully_completed, :dropped]).count
      @stats[:percent_completed] = ((completed_games.to_f / games_with_completion_statuses).round(3) * 100).round(1)
    else
      @stats[:percent_completed] = nil
    end

    if games_with_completion_statuses.positive?
      @stats[:completion_statuses] = {}
      GamePurchase.completion_statuses.each do |key, value|
        @stats[:completion_statuses][key] = game_purchases.where(completion_status: value).count
      end
      @stats[:completion_statuses][:unknown] = game_purchases.where(completion_status: nil).count
    else
      @stats[:completion_statuses] = nil
    end

    # Prevent division by zero.
    if games_with_ratings.positive?
      @stats[:average_rating] = (game_purchases.sum(:rating).to_f / games_with_ratings).round(2)
    else
      @stats[:average_rating] = nil
    end

    # Sum of total hours played, represented as days.
    @stats[:total_days_played] = (total_time_played / 24).to_f.round(2)

    @stats[:games_count] = game_purchases.count

    respond_to do |format|
      format.json { render json: @stats }
    end
  end

  def compare
    @user1 = User.friendly.find(params[:user_id])
    @user2 = User.friendly.find(params[:other_user_id])

    authorize @user1
    authorize @user2

    respond_to do |format|
      format.html
      format.json { render json: @game_purchases }
    end
  end

  def activity
    @user = User.friendly.find(params[:id])

    # Handle authorization with a redirect.
    skip_authorization

    # Redirect if the user's page is private.
    redirect_to user_path(@user) unless policy(@user).activity?

    @events = Event.recently_created
                   .joins(:user)
                   .where(user_id: @user.id)
                   .includes(eventable: [:game])
                   .page helpers.page_param
  end

  def favorites
    @user = User.friendly.find(params[:id])

    # Handle authorization with a redirect.
    skip_authorization

    # Redirect if the user's page is private.
    redirect_to user_path(@user) unless policy(@user).favorites?

    @favorites = @user.favorite_games.page helpers.page_param
  end

  def following
    @user = User.friendly.find(params[:id])

    # Handle authorization with a redirect.
    skip_authorization

    # Redirect if the user's page is private.
    redirect_to user_path(@user) unless policy(@user).following?

    @following = @user.following.page helpers.page_param
  end

  def followers
    @user = User.friendly.find(params[:id])

    # Handle authorization with a redirect.
    skip_authorization

    # Redirect if the user's page is private.
    redirect_to user_path(@user) unless policy(@user).followers?

    @followers = @user.followers.page helpers.page_param
  end

  def reset_token
    @user = current_user
    authorize @user

    @user&.api_token = Devise.friendly_token

    if @user&.save
      redirect_to oauth_applications_path, success: "API token successfully reset."
    else
      redirect_to oauth_applications_path, error: "Unable to reset API token."
    end
  end

  def ban
    @user = User.find(params[:id])

    authorize @user

    @user.banned = true
    # Revoke any special roles from the banned user.
    @user.role = :member unless @user.member?

    # There's no good way to destroy sessions of users besides the current
    # user, but there's a before_action method run on every request, so
    # banned users will get logged out if they do anything.

    if @user.save
      redirect_to user_path(@user), success: "#{@user.username} was successfully banned."
    else
      redirect_to user_path(@user), error: "#{@user.username} could not be banned."
    end
  end

  def unban
    @user = User.find(params[:id])

    authorize @user

    @user.banned = false

    if @user.save
      redirect_to user_path(@user), success: "#{@user.username} was successfully unbanned."
    else
      redirect_to user_path(@user), error: "#{@user.username} could not be unbanned."
    end
  end

  private

  sig { returns(ActionController::Parameters) }
  def user_params
    params.typed_require(:user).permit(
      :bio,
      :avatar,
      :privacy
    )
  end

  def skip_bullet
    previous_value = Bullet.enable?
    Bullet.enable = false
    yield
  ensure
    Bullet.enable = previous_value
  end
end
