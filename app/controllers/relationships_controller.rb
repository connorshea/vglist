# typed: true
class RelationshipsController < ApplicationController
  before_action :authenticate_user!

  def create
    @followed = User.find(params[:user_id])

    authorize @followed, policy_class: RelationshipPolicy

    @relationship = Relationship.new(follower: current_user, followed: @followed)

    if @relationship.save
      redirect_to @followed, success: "#{@followed.username} was successfully followed."
    else
      redirect_to @followed, error: "Unable to follow #{@followed.username}."
    end
  end

  def destroy
    @followed = User.find(params[:user_id])

    authorize @followed, policy_class: RelationshipPolicy

    @relationship = Relationship.find_by(follower: current_user, followed: @followed)

    if @relationship&.destroy
      redirect_to user_path(@followed), success: "#{@followed.username} was successfully unfollowed."
    else
      redirect_to user_path(@followed), error: "Unable to unfollow #{@followed.username}."
    end
  end
end
