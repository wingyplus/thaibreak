defmodule ThaibreakTest do
  use ExUnit.Case
  doctest Thaibreak

  describe "break_words/1" do
    test "breaks a simple greeting" do
      assert Thaibreak.break_words("สวัสดีครับ") == ["สวัสดี", "ครับ"]
    end

    test "breaks a meal-time question" do
      # "Have you eaten yet?"
      words = Thaibreak.break_words("กินข้าวแล้วหรือยัง")
      assert words == ["กิน", "ข้าว", "แล้ว", "หรือ", "ยัง"]
    end

    test "breaks a sentence about Thai language" do
      # "Thai language is beautiful"
      words = Thaibreak.break_words("ภาษาไทยสวยงาม")
      assert is_list(words)
      assert length(words) > 1
      assert Enum.join(words) == "ภาษาไทยสวยงาม"
    end

    test "breaks common nouns" do
      # "cat dog elephant"
      words = Thaibreak.break_words("แมวหมาช้าง")
      assert is_list(words)
      assert Enum.join(words) == "แมวหมาช้าง"
    end

    test "breaks a news-style sentence" do
      # "The weather today is very hot"
      words = Thaibreak.break_words("อากาศวันนี้ร้อนมาก")
      assert is_list(words)
      assert length(words) > 1
      assert Enum.join(words) == "อากาศวันนี้ร้อนมาก"
    end

    test "breaks a sentence about food" do
      # "I want to eat spicy papaya salad"
      words = Thaibreak.break_words("อยากกินส้มตำรสเผ็ด")
      assert is_list(words)
      assert length(words) > 1
      assert Enum.join(words) == "อยากกินส้มตำรสเผ็ด"
    end

    test "handles a single Thai word" do
      words = Thaibreak.break_words("ไทย")
      assert is_list(words)
      assert Enum.join(words) == "ไทย"
    end

    test "handles empty string" do
      assert Thaibreak.break_words("") == [""]
    end

    test "handles ASCII-only text" do
      result = Thaibreak.break_words("hello world")
      assert Enum.join(result) == "hello world"
    end

    test "always preserves the full text when joined" do
      sentences = [
        "ประเทศไทยสวยงาม",
        "ฉันรักประเทศไทย",
        "กรุงเทพมหานคร",
        "วันนี้อากาศดีมาก"
      ]

      for sentence <- sentences do
        words = Thaibreak.break_words(sentence)
        assert Enum.join(words) == sentence,
               "Failed to preserve text for: #{sentence}, got: #{inspect(words)}"
      end
    end

    test "returns a list of valid UTF-8 strings" do
      words = Thaibreak.break_words("สวัสดีประเทศไทย")

      for word <- words do
        assert is_binary(word)
        assert String.valid?(word)
      end
    end
  end

  describe "insert_breaks/2" do
    test "inserts pipe delimiter" do
      result = Thaibreak.insert_breaks("สวัสดีครับ", "|")
      assert result == "สวัสดี|ครับ"
    end

    test "inserts space delimiter" do
      result = Thaibreak.insert_breaks("กินข้าวแล้วหรือยัง", " ")
      assert String.contains?(result, " ")
      # Removing spaces should give back original
      assert String.replace(result, " ", "") == "กินข้าวแล้วหรือยัง"
    end

    test "inserts slash delimiter" do
      result = Thaibreak.insert_breaks("แมวหมาช้าง", "/")
      assert String.contains?(result, "/")
      assert String.replace(result, "/", "") == "แมวหมาช้าง"
    end

    test "uses pipe as default delimiter" do
      result = Thaibreak.insert_breaks("สวัสดีครับ")
      assert result == "สวัสดี|ครับ"
    end

    test "insert_breaks result splits back to same words as break_words" do
      text = "กินข้าวแล้วหรือยัง"
      delim = "@@"
      broken = Thaibreak.insert_breaks(text, delim)
      via_insert = String.split(broken, delim)
      via_break = Thaibreak.break_words(text)
      assert via_insert == via_break
    end

    test "handles a sentence about Bangkok" do
      result = Thaibreak.insert_breaks("กรุงเทพมหานคร", "|")
      assert String.contains?(result, "|")
      assert String.replace(result, "|", "") == "กรุงเทพมหานคร"
    end
  end

  describe "word count" do
    test "counts words correctly for known sentences" do
      assert length(Thaibreak.break_words("สวัสดีครับ")) == 2
      assert length(Thaibreak.break_words("กินข้าวแล้วหรือยัง")) == 5
    end
  end
end
