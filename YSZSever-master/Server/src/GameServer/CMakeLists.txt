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

set(EXECUTABLE_NAME gameserver)
file(GLOB_RECURSE EXECUTABLE_SRCS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *.cpp *.h)

include_directories(
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${CMAKE_SOURCE_DIR}/library/raknet
  ${CMAKE_SOURCE_DIR}/library/log4z
  ${CMAKE_SOURCE_DIR}/library/RapidJson
  ${CMAKE_SOURCE_DIR}/library/RapidXml
  ${CMAKE_SOURCE_DIR}/library/GDK
  ${CMAKE_SOURCE_DIR}/library/lua-5.3.0/src
  ${CMAKE_SOURCE_DIR}/library/event2
  ${CMAKE_SOURCE_DIR}/src/Public
  ${CMAKE_SOURCE_DIR}/library/eigen
  #${CMAKE_SOURCE_DIR}/library/boost/include/boost-1_62
  ${CMAKE_BINARY_DIR}
  ${CURL_INCLUDE_DIR}
  ${PYTHON_INCLUDE_DIRS}
)

add_executable(${EXECUTABLE_NAME}  ${EXECUTABLE_SRCS})


file(GLOB_RECURSE BOOSTLIB ${CMAKE_SOURCE_DIR}/library/boost/lib/*.a)
if(UNIX)
  target_link_libraries(
    ${EXECUTABLE_NAME}
	GDK
    ${OPENSSL_LIBRARIES}
    ${OPENSSL_EXTRA_LIBRARIES}
	${CURL_LIBRARIES}
	${PYTHON_LIBS}
	${LibEvent_LIBS}
	${CMAKE_INSTALL_PREFIX}/lib/liblua.a
	${CMAKE_INSTALL_PREFIX}/lib/libraknet.a
	#${BOOSTLIB}
  )
endif()



set_target_properties(${EXECUTABLE_NAME} PROPERTIES LINK_FLAGS  "${EXECUTABLE_LINK_FLAGS}")

install(TARGETS ${EXECUTABLE_NAME} DESTINATION ${BIN_DIR})
install(DIRECTORY GameScript/ DESTINATION ${GAME_SCRIPT_DIR} PATTERN ".svn" EXCLUDE)
#install(DIRECTORY NavMesh/ DESTINATION ${NAVMESH_DIR} PATTERN ".svn" EXCLUDE)
#install(DIRECTORY Csv/ DESTINATION ${CSV_DIR} PATTERN ".svn" EXCLUDE)
install(PROGRAMS gameserver-run DESTINATION ${BIN_DIR})
install(PROGRAMS gameserver-autorun DESTINATION ${BIN_DIR})

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/gameserver.conf ${CMAKE_CURRENT_BINARY_DIR}/gameserver.conf)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/gameserver.conf DESTINATION ${CONF_DIR})
