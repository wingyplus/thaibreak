defmodule ThaibreakTest do
  use ExUnit.Case
  doctest Thaibreak

  describe "break_words/1" do
    test "breaks a simple Thai sentence" do
      assert Thaibreak.break_words("สวัสดีครับ") == ["สวัสดี", "ครับ"]
    end

    test "breaks a longer Thai sentence" do
      words = Thaibreak.break_words("กินข้าวแล้วหรือยัง")
      assert is_list(words)
      assert length(words) > 1
      assert Enum.join(words) == "กินข้าวแล้วหรือยัง"
    end

    test "returns single element for empty string" do
      assert Thaibreak.break_words("") == [""]
    end

    test "handles ASCII text without breaks" do
      result = Thaibreak.break_words("hello")
      assert Enum.join(result) == "hello"
    end

    test "preserves the full text when joined" do
      text = "ภาษาไทยสวยงาม"
      words = Thaibreak.break_words(text)
      assert Enum.join(words) == text
    end
  end

  describe "insert_breaks/2" do
    test "inserts pipe delimiter between Thai words" do
      result = Thaibreak.insert_breaks("สวัสดีครับ", "|")
      assert String.contains?(result, "|")
      parts = String.split(result, "|")
      assert Enum.join(parts) == "สวัสดีครับ"
    end

    test "inserts space delimiter between Thai words" do
      result = Thaibreak.insert_breaks("กินข้าวแล้วหรือยัง", " ")
      assert String.contains?(result, " ")
    end

    test "uses pipe as default delimiter" do
      result = Thaibreak.insert_breaks("สวัสดีครับ")
      assert String.contains?(result, "|")
    end
  end
end
