# typed: false
class CompaniesController < ApplicationController
  before_action :authenticate_user!, except: [:show, :index]

  def index
    @companies = Company.order(:id).page(helpers.page_param)
    skip_policy_scope
    respond_to do |format|
      format.html
      format.json { render json: @companies }
    end
  end

  def show
    @company = Company.find(params[:id])

    @published_games = @company.published_games
                               .with_attached_cover
                               .includes(:platforms, :developers)
                               .page(helpers.page_param(param: :publisher_page))

    @developed_games = @company.developed_games
                               .with_attached_cover
                               .includes(:platforms, :developers)
                               .page(helpers.page_param(param: :developer_page))

    skip_authorization
  end

  def new
    @company = Company.new
    authorize @company
  end

  def edit
    @company = Company.find(params[:id])
    authorize @company
  end

  def create
    @company = Company.new(company_params)
    authorize @company
    if @company.save
      redirect_to @company, success: "#{@company.name} was successfully created."
    else
      flash.now[:error] = "Unable to create company."
      render :new
    end
  end

  def update
    @company = Company.find(params[:id])
    authorize @company

    if @company.update(company_params)
      redirect_to @company, success: "#{@company.name} was successfully updated."
    else
      flash.now[:error] = "Unable to update company."
      render :edit
    end
  end

  def destroy
    @company = Company.find(params[:id])
    authorize @company
    @company.destroy
    redirect_to companies_url, success: "Company was successfully deleted."
  end

  def search
    if params[:query].present?
      @companies = Company.search(params[:query]).page(helpers.page_param)
    else
      @companies = Company.none.page(helpers.page_param)
    end

    authorize @companies

    respond_to do |format|
      format.json { render json: @companies }
    end
  end

  private

  def company_params
    params.require(:company).permit(
      :name,
      :description,
      :wikidata_id
    )
  end
end
