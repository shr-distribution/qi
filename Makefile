# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston,
# MA 02111-1307 USA
#

include config.mk

LDS	= src/cpu/$(CPU)/qi.lds
INCLUDE	= include
IMAGE_DIR	= image
TOOLS	= tools
CFLAGS	= -Wall -Werror -I $(INCLUDE) $(EXTRA_CFLAGS) -g -c -Os -fno-strict-aliasing -mlong-calls \
	  -fno-common -ffixed-r8 -msoft-float -fno-builtin -ffreestanding \
	  -march=armv4t -mno-thumb-interwork -Wstrict-prototypes \
	  -DBUILD_HOST="${BUILD_HOST}" -DBUILD_VERSION="${BUILD_VERSION}" \
	  -DBUILD_DATE="${BUILD_DATE}" -DQI_CPU="${CPU}"
LDFLAGS = 

S_SRCS	= $(wildcard src/cpu/$(CPU)/*.S)
S_OBJS	= $(patsubst %.S,%.o, $(S_SRCS))
C_SRCS	= $(wildcard src/*.c) \
	  $(wildcard src/drivers/*.c)  $(wildcard src/fs/*.c) \
	  $(wildcard src/cpu/$(CPU)/*.c)
C_OBJS	= $(patsubst %.c,%.o, $(C_SRCS))

SRCS	= ${S_SRCS} ${C_SRCS}
OBJS	= ${S_OBJS} ${C_OBJS}
LIBS	= `$(CC) -print-libgcc-file-name`

ifeq ($(CPU),s3c2410)
  # GTA01 U-Boot IDs
  UDFU_VID = 0x1457
  UDFU_PID = 0x5119
  UDFU_REV = 0x0240
else
  # GTA02 A5 and A6 U-Boot will eat these for DFU action
  UDFU_VID = 0x1d50
  UDFU_PID = 0x5119
  UDFU_REV = 0x350
endif

TARGET	= $(IMAGE_DIR)/start_qi_all-$(CPU)
IMAGE = $(IMAGE_DIR)/qi-$(CPU)-$(BUILD_VERSION)
UDFU_IMAGE = $(IMAGE_DIR)/qi-$(CPU)-$(BUILD_VERSION).udfu

MKUDFU = $(TOOLS)/mkudfu

%.o: %.S
	$(CC) $(CFLAGS) -o $@ $<

%.o: %.c
	$(CC) $(CFLAGS) -o $@ $<

all:${UDFU_IMAGE}

${OBJS}:${SRCS} ${INCLUDE}/*.h

${MKUDFU}:
	 gcc tools/mkudfu.c -o ${MKUDFU} -Itools/

${UDFU_IMAGE}:${OBJS} ${MKUDFU}
	mkdir -p image
	$(LD) ${LDFLAGS} -T$(LDS) -g $(OBJS) -o ${TARGET} ${LIBS}
	$(OBJCOPY) -O binary -S ${TARGET} ${IMAGE}
	$(MKUDFU) -v ${UDFU_VID} -p ${UDFU_PID} -r ${UDFU_REV} \
						-d ${IMAGE} ${UDFU_IMAGE}
	$(OBJDUMP) -d ${TARGET} >${IMAGE}.dis

clean:
	@rm -f *~ src/*.o src/*~
	@rm -f src/cpu/*/*.o src/cpu/*/*~
	@rm -f src/drivers/*.o src/drivers/*~
	@rm -f src/fs/*.o src/fs/*~
	@rm -f include/*~ ${IMAGE_DIR}/*
	@make clean -C $(TOOLS)

