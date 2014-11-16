##
# unplist - bad xml begone!
###
EXE := unplist
OBJECTS := $(patsubst %.m,%.o,$(wildcard *.m))

CFLAGS := -Wall
CFLAGS += -O2

LDFLAGS := -framework Foundation

$(EXE): $(OBJECTS)
	$(CC) -o $(EXE) $(OBJECTS) $(LDFLAGS)

clean:
	rm -f $(EXE) $(OBJECTS)
