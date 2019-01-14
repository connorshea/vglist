class CompaniesController < ApplicationController
  before_action :authenticate_user!, except: [:show, :index]

  def index
    @companies = Company.order(:id).page params[:page]
    skip_policy_scope
  end

  def show
    @company = Company.find(params[:id])

    @published_releases = ReleasePublisher.all
                                          .where(company: @company.id)
                                          .includes(:release)

    @developed_releases = ReleaseDeveloper.all
                                          .where(company: @company.id)
                                          .includes(:release)

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

  private

  def company_params
    params.require(:company).permit(:name, :description)
  end
end
