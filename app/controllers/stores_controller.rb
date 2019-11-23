# typed: false
class StoresController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]

  def index
    @stores = Store.order(:id).page helpers.page_param
    skip_policy_scope
  end

  def show
    @store = Store.find(params[:id])
    skip_authorization

    respond_to do |format|
      format.html
      format.json { render json: @store }
    end
  end

  def new
    @store = Store.new
    authorize @store
  end

  def edit
    @store = Store.find(params[:id])
    authorize @store
  end

  def create
    @store = Store.new(store_params)
    authorize @store

    respond_to do |format|
      if @store.save
        format.html { redirect_to @store, notice: 'Store was successfully created.' }
        format.json { render :show, status: :created, location: @store }
      else
        format.html do
          flash.now[:error] = "Unable to create store."
          render :new
        end
        format.json { render json: @store.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @store = Store.find(params[:id])
    authorize @store

    respond_to do |format|
      if @store.update(store_params)
        format.html { redirect_to @store, notice: 'Store was successfully updated.' }
        format.json { render :show, status: :ok, location: @store }
      else
        format.html do
          flash.now[:error] = "Unable to update store."
          render :edit
        end
        format.json { render json: @store.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @store = Store.find(params[:id])
    authorize @store
    @store.destroy

    respond_to do |format|
      format.html { redirect_to stores_url, notice: 'Store was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def search
    if params[:query].present?
      @stores = Store.search(params[:query]).page(helpers.page_param)
    else
      @stores = Store.none.page(helpers.page_param)
    end

    authorize @stores

    respond_to do |format|
      format.json { render json: @stores }
    end
  end

  private

  def store_params
    params.typed_require(:store).permit(
      :name
    )
  end
end
