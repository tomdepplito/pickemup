require 'subscription_handler'
class SubscriptionsController < ApplicationController
  before_filter :find_company, except: [:listener]
  before_filter :get_credentials, only: [:edit, :update]

  def new
    @subscription = Subscription.new
    @clicked_option = params[:clicked_option]
  end

  def create
    @subscription = @company.build_subscription(subscription_params)
    if @subscription.save_with_payment
      redirect_to root_path, notice: "Subscription created! Start adding a job listing."
    else
      flash[:error] = "Something went wrong"
      render :new
    end
  end

  def edit
  end

  def update
    if params[:cancel_subscription] == "true"
      @customer.cancel_subscription
      @subscription.active = false
    end
    if params[:plan] != @subscription.plan
      @customer.update_subscription(:plan => params[:plan])
      @subscription.update_plan(params[:plan])
    end
    if params[:reactivate_subscription] == "true"
      new_plan = param[:plan]
      @customer.update_subscription(:plan => new_plan)
      @subscription.update_plan(new_plan)
      @subscription.active = true
    end
    if @customer.save && @subscription.save_update
      flash[:success] = "Subscription info updated!"
      redirect_to edit_company_path(@subscription.company_id) #change path
    else
      flash[:error] = "Something went wrong"
      render :edit
    end
  end

  def edit_card
    @subscription = Subscription.find(params[:id])
    @customer = Stripe::Customer.retrieve(@subscription.stripe_customer_token)
    if params[:stripe_card_token].present?
      @subscription.update(subscription_params)
      @customer.update_subscription(card: params[:stripe_card_token], plan: @subscription.plan)
      if @subscription.save
        redirect_to edit_company_path(@subscription.company_id) #change this path
      end
    end
  end

  def listener
    if params.present?
      SubscriptionHandler.new(params)
      render :status => 200
    else
      render :status => 500
    end
  end

  def purchase_options
  end

  private

  def get_credentials
    @subscription = @company.subscription
    @customer = Stripe::Customer.retrieve(@subscription.stripe_customer_token)
  end

  def subscription_params
    params.permit(:company_id, :email, :plan, :stripe_card_token)
  end

  def find_company
    @company ||= Company.find(params[:company_id])
    check_invalid_permissions_company
  end
end

