class AdminsController < ApplicationController
  before_filter :verify_admin

  def index
    @current_admin = current_admin
  end

  def sign_in
  end

  private

  def verify_admin
    unless current_admin.present?
      redirect_to root_path
    end
  end
end
