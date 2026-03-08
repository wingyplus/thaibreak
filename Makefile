PRIV_DIR = priv
TARGET = $(PRIV_DIR)/thaibreak.so

ERL_INCLUDE = $(shell erl -noshell -eval \
	"io:format(\"~s/erts-~s/include\", [code:root_dir(), erlang:system_info(version)])" \
	-s init stop 2>/dev/null)

CPPFLAGS = -I$(FINE_INCLUDE_DIR) \
           -I$(ERL_INCLUDE) \
           -std=c++17 \
           -fvisibility=hidden \
           -fPIC \
           -O2

LDFLAGS = -shared

ifeq ($(shell uname -s), Darwin)
  LDFLAGS += -undefined dynamic_lookup
  TARGET = $(PRIV_DIR)/thaibreak.so
endif

all: $(TARGET)

$(TARGET): c_src/thaibreak.cpp
	mkdir -p $(PRIV_DIR)
	$(CXX) $(CPPFLAGS) $(LDFLAGS) -o $@ $< -lthai

clean:
	rm -f $(TARGET)

.PHONY: all clean
