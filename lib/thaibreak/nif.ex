defmodule Thaibreak.NIF do
  @moduledoc false

  @on_load :load_nif

  def load_nif do
    path = :filename.join(:code.priv_dir(:thaibreak), ~c"thaibreak")
    :erlang.load_nif(path, 0)
  end

  def find_breaks(_text), do: :erlang.nif_error(:not_loaded)
  def insert_breaks(_text, _delim), do: :erlang.nif_error(:not_loaded)
end
