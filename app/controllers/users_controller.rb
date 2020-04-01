# typed: true
class UsersController < ApplicationController
  # Skip bullet on activity to avoid errors.
  around_action :skip_bullet, if: -> { defined?(Bullet) }

  def index
    # Hide banned users from users that aren't moderators or admins.
    if current_user&.member? || current_user.nil?
      @users = User.where(banned: false).order(:id).page helpers.page_param
    elsif current_user&.moderator? || current_user&.admin?
      @users = User.order(:id).page helpers.page_param
    end
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

  def update_role
    @user = User.friendly.find(params[:id])
    role = params.fetch(:role).to_sym

    authorize @user

    unless [:member, :moderator, :admin].include? role
      flash[:error] = "Invalid role."
      redirect_to(user_path(@user.id)) && return
    end

    if role == :member
      @user.role = :member
    elsif role == :moderator
      @user.role = :moderator
    elsif role == :admin
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

    user_games_count_before = @user.games.count

    steam_account = ExternalAccount.find_by(user_id: @user.id, account_type: :steam)
    raise if steam_account.nil?

    steam_api_url = "https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/?key=#{ENV['STEAM_WEB_API_KEY']}&steamid=#{steam_account[:steam_id]}&include_appinfo=1&include_played_free_games=1"
    json = JSON.parse(T.must(T.must(URI.open(steam_api_url)).read))

    steam_games = json.dig('response', 'games')

    # If no games are returned, return an error message.
    if steam_games.nil?
      respond_to do |format|
        format.html do
          flash[:error] = "Unable to find any games in your Steam library. Are you sure it's public and that you've connected the correct account?"
          redirect_to settings_import_path
          return
        end
      end
    end

    # Ignore games without logo URLs, this filters out most DLC, which we don't want to import.
    steam_games.reject! { |game| game['img_logo_url'] == "" }
    unmatched_games = []
    matched_games_count = 0

    steam_games&.each do |steam_game|
      steam_app_id_record = SteamAppId.find_by(app_id: steam_game['appid'])
      if steam_app_id_record.nil?
        unmatched_games << steam_game
        next
      end
      game = steam_app_id_record.game
      # Convert playtime from minutes to hours, rounded to one decimal place.
      hours_played = (steam_game['playtime_forever'].to_f / 60).round(1)

      # Find by game id and user id, add hours played if it gets created.
      GamePurchase.create_with(hours_played: hours_played).find_or_create_by(
        game_id: game.id,
        user_id: @user.id
      )

      matched_games_count += 1
    end

    unmatched_games_count = unmatched_games.count

    T.must(unmatched_games).map! { |game| { name: game['name'], steam_id: game['appid'] } }

    user_games_count_diff = @user.games.count - user_games_count_before

    # Limit to the first 50 games because of cookie size limits.
    # Sample 50 at random to make sure the same games aren't always
    # displayed every time the user runs an import.
    cookies[:unmatched_games] = JSON.generate(unmatched_games.sample(50))

    respond_to do |format|
      format.html do
        flash[:success] = "Added #{user_games_count_diff} games. #{unmatched_games_count} games weren't found in the vglist database."
        redirect_to settings_import_path
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
    games_with_completion_statuses = game_purchases.where.not(completion_status: nil).count

    # TODO: Figure out what to do about dropped, not_applicable, and paused.
    # Prevent division by zero.
    if games_with_completion_statuses.positive?
      completed_games = game_purchases.where(completion_status: [:completed, :fully_completed]).count
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

    @user&.authentication_token = Devise.friendly_token

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

    # Note: There's no good way to destroy sessions of users besides the
    # current user, but there's a before_action method run on every request,
    # so banned users will get logged out if they do anything.

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
