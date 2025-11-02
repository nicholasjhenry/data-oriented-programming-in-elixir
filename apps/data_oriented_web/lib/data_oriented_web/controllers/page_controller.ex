defmodule DataOrientedWeb.PageController do
  use DataOrientedWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
