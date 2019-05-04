#
# Copyright (C) 2005-2012 MaNGOS project <http://getmangos.com/>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#


file(GLOB_RECURSE GDK_SRCS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.cpp *.h)

include_directories(
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${CMAKE_SOURCE_DIR}/library/raknet
  ${CMAKE_SOURCE_DIR}/library/RapidXml
  ${CMAKE_SOURCE_DIR}/library/RapidJson
  ${CMAKE_SOURCE_DIR}/library/log4z
  ${CMAKE_SOURCE_DIR}/library/lua-5.3.0/src
  ${CMAKE_BINARY_DIR}
  ${MYSQL_INCLUDE_DIR}
  ${CMAKE_SOURCE_DIR}/library/eigen
  ${CMAKE_SOURCE_DIR}/library/boost/include/boost-1_62/
)

add_library(GDK STATIC
  ${GDK_SRCS}
)


