class UsersController < ApplicationController
  def index
    @users = User.order(:id).page params[:page]
    skip_policy_scope
  end

  def show
    @user = User.friendly.find(params[:id])
    skip_authorization
  end

  def update
    @user = User.friendly.find(params[:id])
    authorize @user

    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, success: "#{@user.username} was successfully updated." }
      else
        format.html do
          flash[:error] = "Unable to update user."
          redirect_to settings_path
        end
      end
    end
  end

  def update_role
    @user = User.friendly.find(params[:id])
    role = params[:role].to_sym

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

    @user.avatar.purge

    respond_to do |format|
      format.html { redirect_to @user, success: "Avatar successfully removed." }
    end
  end

  def steam_import
    @user = User.friendly.find(params[:id])
    authorize @user

    steam_account = ExternalAccount.find_by(user_id: @user.id, account_type: :steam)
    raise if steam_account.nil?

    steam_api_url = "https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/?key=#{ENV['STEAM_WEB_API_KEY']}&steamid=#{steam_account[:steam_id]}&include_appinfo=1&include_played_free_games=1"
    json = JSON.parse(URI.open(steam_api_url).read)

    steam_games = json.dig('response', 'games')
    unmatched_games = []
    matched_games_count = 0

    steam_games&.each do |steam_game|
      game = Game.find_by(steam_app_id: steam_game['appid'])
      # Convert playtime from minutes to hours, rounded to one decimal place.
      hours_played = (steam_game['playtime_forever'].to_f / 60).round(1)
      if game.nil?
        unmatched_games << steam_game
        next
      end

      # Find by game id and user id, add hours played if it gets created.
      GamePurchase.create_with(hours_played: hours_played).find_or_create_by(
        game_id: game.id,
        user_id: @user.id
      )

      matched_games_count += 1
    end

    respond_to do |format|
      format.html do
        flash[:success] = "Added #{matched_games_count} games. #{unmatched_games.count} games weren't found in the VGList database."
        redirect_to settings_connections_path
      end
    end
  end

  def disconnect_steam
    @user = User.friendly.find(params[:id])
    authorize @user

    @steam_account = ExternalAccount.find_by(user_id: @user.id, account_type: :steam)

    respond_to do |format|
      if @steam_account.destroy
        format.html do
          flash[:success] = "Disconnected Steam account."
          redirect_to settings_connections_path
        end
      else
        format.html do
          flash[:error] = "Steam account couldn't be disconnected."
          redirect_to settings_connections_path
        end
      end
    end
  end

  private

  def user_params
    params.require(:user).permit(
      :bio,
      :avatar
    )
  end
end
