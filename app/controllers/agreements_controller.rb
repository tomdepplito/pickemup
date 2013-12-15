class AgreementsController < ApplicationController
  before_filter :verify_admin
  before_filter :find_agreement, only: [:edit, :update]

  def new
    @agreement = Agreement.new
    @admin_id = current_admin.id
  end

  def create
    @agreement = Agreement.new
    if @agreement.update(agreement_params)
      redirect_to admins_path
      flash[:notice] = "Agreement created!"
    else
      flash[:error] = "Agreement not saved."
      render :new
    end
  end

  def index
    @agreements = Agreement.all
  end

  def edit
  end

  def update
    if @agreement.update(agreement_params)
      redirect_to admins_path
      flash[:notice] = "Agreement updated!"
    else
      flash[:error] = "Agreement not saved."
      render :new
    end
  end

  private

  def agreement_params
    params.require(:agreement).permit(:company_id, :job_listing_id, :admin_id, :contract_type, :rate, :documentation, :description, :paid, :signed)
  end

  def find_agreement
    @agreement = Agreement.find(params[:id])
  end

  def verify_admin
    unless current_admin.present?
      redirect_to root_path
    end
  end
end
