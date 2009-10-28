#
# Copyright (c) 2007,2009 LAAS/CNRS                        --  Wed May 30 2007
# All rights reserved.
#
# Redistribution  and  use in source   and binary forms,  with or without
# modification, are permitted provided that  the following conditions are
# met:
#
#   1. Redistributions  of  source code must  retain  the above copyright
#      notice, this list of conditions and the following disclaimer.
#   2. Redistributions in binary form must  reproduce the above copyright
#      notice,  this list of  conditions and  the following disclaimer in
#      the  documentation   and/or  other  materials   provided with  the
#      distribution.
#
# This project includes software developed by the NetBSD Foundation, Inc.
# and its contributors. It is derived from the 'pkgsrc' project
# (http://www.pkgsrc.org).
#
# From $NetBSD: can-be-built-here.mk,v 1.4 2007/02/10 09:01:05 rillig Exp $
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHORS AND CONTRIBUTORS ``AS IS'' AND
# ANY  EXPRESS OR IMPLIED WARRANTIES, INCLUDING,  BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES   OF MERCHANTABILITY AND  FITNESS  FOR  A PARTICULAR
# PURPOSE ARE DISCLAIMED.  IN NO  EVENT SHALL THE AUTHOR OR  CONTRIBUTORS
# BE LIABLE FOR ANY DIRECT, INDIRECT,  INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING,  BUT  NOT LIMITED TO, PROCUREMENT  OF
# SUBSTITUTE  GOODS OR SERVICES;  LOSS   OF  USE,  DATA, OR PROFITS;   OR
# BUSINESS  INTERRUPTION) HOWEVER CAUSED AND  ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE  USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

#
# This file checks whether a package can be built in the current robotpkg
# environment. It checks the following variables:
#
# PKG_FAIL_REASON, PKG_SKIP_REASON
#

_CBBH=			yes#, but see below.

# Check PKG_FAIL_REASON
ifdef PKG_FAIL_REASON
ifneq (,${PKG_FAIL_REASON})
_CBBH=			no
_CBBH_MSGS+=		"This package has failed for the following reason:"
_CBBH_MSGS+=		"${hline}"
_CBBH_MSGS+=		${PKG_FAIL_REASON}
_CBBH_MSGS+=		"${hline}"
endif
endif

# Check PKG_SKIP_REASON
ifdef PKG_SKIP_REASON
ifneq (,$(PKG_SKIP_REASON))
_CBBH=			no
_CBBH_MSGS+=		"This package has set PKG_SKIP_REASON:"
_CBBH_MSGS+=		${PKG_SKIP_REASON}
endif
endif

# In the first line, this target prints either "yes" or "no", saying
# whether this package can be built. If the package can not be built,
# the reasons are given in the following lines.
#
.PHONY: can-be-built-here cbbh

can-be-built-here:
	@${ECHO} ${_CBBH}
	@${ECHO} ${_CBBH_MSGS}

cbbh:
	@for str in ${_CBBH_MSGS}; do					\
		${ERROR_MSG} "$$str";					\
	done
	@exit 2

ifeq (no,${_CBBH})
  # include a fake file so that cbbh is called before anything else
  $(if $(filter			\
	fetch			\
	depends			\
	configure		\
	build			\
	install			\
	update			\
	package			\
	bootstrap-depends	\
	bootstrap-register,	\
	${MAKECMDGOALS}),$(eval include ${ROBOTPKG_DIR}/mk/robotpkg.prefs.mk))

  ${ROBOTPKG_DIR}/mk/robotpkg.prefs.mk: cbbh
endif
