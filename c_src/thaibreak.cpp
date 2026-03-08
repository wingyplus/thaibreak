#include <thai/thbrk.h>
#include <thai/thwbrk.h>

#include <fine.hpp>
#include <stdexcept>
#include <string>
#include <vector>

// Global word breaker instance, initialized in the NIF load callback.
static ThBrk *g_brk = nullptr;

static const fine::Registration load_reg =
    fine::Registration::register_load([](ErlNifEnv *, void **, ERL_NIF_TERM) {
      g_brk = th_brk_new(nullptr);
      if (!g_brk) {
        throw std::runtime_error("Failed to initialize Thai word breaker");
      }
    });

static const fine::Registration unload_reg =
    fine::Registration::register_unload([](ErlNifEnv *, void *) {
      if (g_brk) {
        th_brk_delete(g_brk);
        g_brk = nullptr;
      }
    });

// Convert UTF-8 string to a null-terminated wide char (UCS-4) vector.
static std::vector<thwchar_t> utf8_to_wchar(const std::string &utf8) {
  std::vector<thwchar_t> result;
  result.reserve(utf8.size() + 1);

  const unsigned char *s =
      reinterpret_cast<const unsigned char *>(utf8.c_str());
  const unsigned char *end = s + utf8.size();

  while (s < end) {
    thwchar_t cp;
    unsigned char c = *s;

    if (c < 0x80) {
      cp = c;
      s += 1;
    } else if (c < 0xE0) {
      cp = static_cast<thwchar_t>((c & 0x1F) << 6) | (s[1] & 0x3F);
      s += 2;
    } else if (c < 0xF0) {
      cp = static_cast<thwchar_t>((c & 0x0F) << 12) |
           static_cast<thwchar_t>((s[1] & 0x3F) << 6) | (s[2] & 0x3F);
      s += 3;
    } else {
      cp = static_cast<thwchar_t>((c & 0x07) << 18) |
           static_cast<thwchar_t>((s[1] & 0x3F) << 12) |
           static_cast<thwchar_t>((s[2] & 0x3F) << 6) | (s[3] & 0x3F);
      s += 4;
    }
    result.push_back(cp);
  }

  result.push_back(0);  // null terminator
  return result;
}

// Convert a wide char (UCS-4) vector to a UTF-8 string.
static std::string wchar_to_utf8(const thwchar_t *wstr) {
  std::string result;

  for (; *wstr; ++wstr) {
    thwchar_t cp = *wstr;
    if (cp < 0x80) {
      result += static_cast<char>(cp);
    } else if (cp < 0x800) {
      result += static_cast<char>(0xC0 | (cp >> 6));
      result += static_cast<char>(0x80 | (cp & 0x3F));
    } else if (cp < 0x10000) {
      result += static_cast<char>(0xE0 | (cp >> 12));
      result += static_cast<char>(0x80 | ((cp >> 6) & 0x3F));
      result += static_cast<char>(0x80 | (cp & 0x3F));
    } else {
      result += static_cast<char>(0xF0 | (cp >> 18));
      result += static_cast<char>(0x80 | ((cp >> 12) & 0x3F));
      result += static_cast<char>(0x80 | ((cp >> 6) & 0x3F));
      result += static_cast<char>(0x80 | (cp & 0x3F));
    }
  }

  return result;
}

// Convert a wide char position (in wchar units) to a UTF-8 byte position.
static size_t wchar_pos_to_utf8_pos(const std::string &utf8, size_t wchar_pos) {
  const unsigned char *s =
      reinterpret_cast<const unsigned char *>(utf8.c_str());
  size_t byte_pos = 0;

  for (size_t i = 0; i < wchar_pos; i++) {
    unsigned char c = s[byte_pos];
    if (c < 0x80)
      byte_pos += 1;
    else if (c < 0xE0)
      byte_pos += 2;
    else if (c < 0xF0)
      byte_pos += 3;
    else
      byte_pos += 4;
  }

  return byte_pos;
}

// Find word break positions in a Thai UTF-8 string.
// Returns a list of UTF-8 byte positions where word breaks occur.
std::vector<int64_t> find_breaks(ErlNifEnv *env, std::string text) {
  ThBrk *brk = g_brk;

  auto wtext = utf8_to_wchar(text);
  // wtext.size() - 1 to exclude the null terminator
  size_t wlen = wtext.size() - 1;
  std::vector<int> pos(wlen + 1);

  int n = th_brk_wc_find_breaks(brk, wtext.data(), pos.data(), pos.size());

  std::vector<int64_t> result;
  result.reserve(n);
  for (int i = 0; i < n; i++) {
    result.push_back(static_cast<int64_t>(wchar_pos_to_utf8_pos(text, pos[i])));
  }

  return result;
}

// Insert a delimiter between Thai words in a UTF-8 string.
// Returns the resulting UTF-8 string with delimiters inserted.
std::string insert_breaks(ErlNifEnv *env, std::string text, std::string delim) {
  ThBrk *brk = g_brk;

  auto wtext = utf8_to_wchar(text);
  auto wdelim = utf8_to_wchar(delim);
  // Remove null terminator from wdelim before use as length
  size_t wdelim_len = wdelim.size() - 1;
  size_t wtext_len = wtext.size() - 1;

  // Worst case: delimiter inserted between every wide char
  size_t out_sz = wtext_len * (wdelim_len + 1) + 1;
  std::vector<thwchar_t> wout(out_sz, 0);

  th_brk_wc_insert_breaks(brk, wtext.data(), wout.data(), out_sz,
                          wdelim.data());

  return wchar_to_utf8(wout.data());
}

FINE_NIF(find_breaks, 0);
FINE_NIF(insert_breaks, 0);
FINE_INIT("Elixir.Thaibreak.NIF");
