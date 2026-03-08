PRIV_DIR        = priv
TARGET          = $(PRIV_DIR)/thaibreak.so
CMAKE_BUILD_DIR = _cmake_build

all: $(TARGET)

$(TARGET): c_src/thaibreak.cpp CMakeLists.txt
	mkdir -p $(CMAKE_BUILD_DIR) $(PRIV_DIR)
	cmake -B $(CMAKE_BUILD_DIR) \
		-DFINE_INCLUDE_DIR=$(abspath $(FINE_INCLUDE_DIR)) \
		-DPRIV_DIR=$(abspath $(PRIV_DIR))
	cmake --build $(CMAKE_BUILD_DIR) --parallel

clean:
	rm -rf $(CMAKE_BUILD_DIR) $(TARGET)

.PHONY: all clean
