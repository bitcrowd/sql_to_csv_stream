class UsersController < ApplicationController
  def index
    @users = User.all.select(:name, :settings, :accepted_terms)

    respond_to do |format|
      format.csv do
        render csv_stream: @users, filename: 'users.csv'
      end
      format.json do
        render json_stream: @users, filename: 'users.json'
      end
    end
  end
end
