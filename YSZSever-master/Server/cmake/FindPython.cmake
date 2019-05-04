# This module defines
# Python_INCLUDE_DIRS, where to find Python headers
# Python_LIBS, Python libraries
# Python_FOUND, If false, do not try to use ant

# Look for the header file.


    find_path(PYTHON_INCLUDE_DIR Python.h PATHS
	        /usr/include/python2.7
            /opt/local/include/python2.7
            /usr/local/include/python2.7
            )
 
  find_library(PYTHON_LIB python2.7 PATHS               
               /usr/lib
               /opt/local/lib
               /usr/local/lib
			   /usr/lib64
               /opt/local/lib64
               /usr/local/lib64
               )
			   
#FIND_PATH(Python_INCLUDE_DIR  NAMES  Python.h  PATHS  /usr/include/python2.7/)
MARK_AS_ADVANCED(PYTHON_INCLUDE_DIR)

# Look for the library.
#FIND_LIBRARY(Python_LIB  NAMES  libpython  PATHS  /usr/lib/  /usr/lib64/)	
MARK_AS_ADVANCED(PYTHON_LIB)
	
IF (PYTHON_LIB AND PYTHON_INCLUDE_DIR)
SET(PYTHON_FOUND TRUE)
  SET(PYTHON_LIBS ${PYTHON_LIB})
  SET(PYTHON_INCLUDE_DIRS ${PYTHON_INCLUDE_DIR})
ELSE ()
  SET(PYTHON_FOUND FALSE)
ENDIF ()


	
#IF (PYTHON_FOUND)
#    MESSAGE (STATUS "PYTHON_INCLUDE_DIRS=${PYTHON_INCLUDE_DIR}")
#    MESSAGE (STATUS "PYTHON_LIBS=${PYTHON_LIB}")
#ELSE ()
#    MESSAGE(STATUS "PYTHON NOT FOUND.")
#ENDIF ()