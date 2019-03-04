# frozen_string_literal: true

class UsersController < ApplicationController
  def index
    @users = User.all.limit(10_000_000).select(:name, :settings, :accepted_terms)

    respond_to do |format|
      format.csv do
        render csv_stream: @users, filename: 'users.csv', sanitize: false
      end
      format.json do
        render json_stream: @users, filename: 'users.json'
      end
    end
  end
end
