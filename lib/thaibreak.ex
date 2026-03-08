defmodule Thaibreak do
  @moduledoc """
  Thai word segmentation using libthai via NIF bindings.

  This module provides functions to break Thai text into individual words
  using the libthai library's dictionary-based word segmentation algorithm.

  ## Examples

      iex> Thaibreak.break_words("สวัสดีครับ")
      ["สวัสดี", "ครับ"]

      iex> Thaibreak.insert_breaks("สวัสดีครับ", "|")
      "สวัสดี|ครับ"

  """

  alias Thaibreak.NIF

  @doc """
  Breaks a Thai UTF-8 string into a list of words.

  Returns a list of word strings. Non-Thai text (ASCII, punctuation) is
  passed through without modification as part of the surrounding word segments.

  ## Examples

      iex> Thaibreak.break_words("สวัสดีครับ")
      ["สวัสดี", "ครับ"]

      iex> Thaibreak.break_words("กินข้าวแล้วหรือยัง")
      ["กิน", "ข้าว", "แล้ว", "หรือ", "ยัง"]

  """
  @spec break_words(String.t()) :: [String.t()]
  def break_words(text) when is_binary(text) do
    positions = NIF.find_breaks(text)
    split_at_positions(text, positions)
  end

  @doc """
  Inserts a delimiter string between Thai words in a UTF-8 string.

  ## Examples

      iex> Thaibreak.insert_breaks("สวัสดีครับ", "|")
      "สวัสดี|ครับ"

      iex> Thaibreak.insert_breaks("กินข้าวแล้วหรือยัง", " ")
      "กิน ข้าว แล้ว หรือ ยัง"

  """
  @spec insert_breaks(String.t(), String.t()) :: String.t()
  def insert_breaks(text, delim \\ "|") when is_binary(text) and is_binary(delim) do
    NIF.insert_breaks(text, delim)
  end

  # Split a binary string at a list of byte positions.
  defp split_at_positions(text, []), do: [text]

  defp split_at_positions(text, positions) do
    {words, last_pos} =
      Enum.reduce(positions, {[], 0}, fn pos, {acc, prev} ->
        word = binary_part(text, prev, pos - prev)
        {[word | acc], pos}
      end)

    remaining = binary_part(text, last_pos, byte_size(text) - last_pos)

    words
    |> then(fn ws -> if remaining != "", do: [remaining | ws], else: ws end)
    |> Enum.reverse()
  end
end
