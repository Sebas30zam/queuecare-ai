class HomeController < ApplicationController
  before_action :authenticate_user!

  def index
    render inertia: "home/index"
  end
end
