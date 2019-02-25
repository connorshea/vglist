class EnginesController < ApplicationController
  before_action :authenticate_user!, except: [:show, :index]

  def index
    @engines = Engine.order(:id).page params[:page]
    skip_policy_scope
  end

  def show
    @engine = Engine.find(params[:id])
    skip_authorization

    @games = @engine.games
                    .with_attached_cover
  end

  def new
    @engine = Engine.new
    authorize @engine
  end

  def edit
    @engine = Engine.find(params[:id])
    authorize @engine
  end

  def create
    @engine = Engine.new(engine_params)
    authorize @engine

    respond_to do |format|
      if @engine.save
        format.html { redirect_to @engine, notice: 'Engine was successfully created.' }
        format.json { render :show, status: :created, location: @engine }
      else
        format.html do
          flash.now[:error] = "Unable to create engine."
          render :new
        end
        format.json { render json: @engine.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @engine = Engine.find(params[:id])
    authorize @engine

    respond_to do |format|
      if @engine.update(engine_params)
        format.html { redirect_to @engine, notice: 'Engine was successfully updated.' }
        format.json { render :show, status: :ok, location: @engine }
      else
        format.html do
          flash.now[:error] = "Unable to update engine."
          render :edit
        end
        format.json { render json: @engine.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @engine = Engine.find(params[:id])
    authorize @engine
    @engine.destroy

    respond_to do |format|
      format.html { redirect_to engines_url, notice: 'Engine was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def search
    if params[:query].present?
      @engines = Engine.search(params[:query]).page(params[:page])
    else
      @engines = Engine.none.page(params[:page])
    end

    authorize @engines

    respond_to do |format|
      format.json { render json: @engines }
    end
  end

  private

  def engine_params
    params.require(:engine).permit(:name)
  end
end
