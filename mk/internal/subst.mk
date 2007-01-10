#
# Copyright (c) 2006 LAAS/CNRS                        --  Thu Dec  7 2006
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
# From $NetBSD: subst.mk,v 1.38 2006/12/10 02:25:13 reed Exp $
# Copyright (c) 1994-2006 The NetBSD Foundation, Inc.
#
#   3. All advertising materials mentioning   features or use of this
#      software must display the following acknowledgement:
#        This product includes software developed by the NetBSD
#        Foundation, Inc. and its contributors.
#   4. Neither the  name  of The NetBSD Foundation  nor the names  of its
#      contributors  may be  used to endorse or promote  products derived
#      from this software without specific prior written permission.
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
# This Makefile fragment implements a general text replacement facility.
# Package makefiles define a ``class'', for each of which a particular
# substitution description can be defined.  For each class of files, a
# target subst-<class> is created to perform the text replacement.
#
# Package-settable variables:
#
# SUBST_CLASSES
#	A list of class names. 	A new class name must be appended (+=).
#
# SUBST_STAGE.<class>
#	"stage" at which we do the text replacement. Should be one of
#	{pre,do,post}-{extract,patch,configure,build,install}.
#
# SUBST_MESSAGE.<class>
#	The message to display when the substitution is done.
#
# SUBST_FILES.<class>
#	A list of file patterns on which to run the substitution;
#	the filenames are either absolute or relative to ${WRKSRC}.
#
# SUBST_SED.<class>
#	List of sed(1) arguments to run on the specified files. Multiple
#	commands can be specified using the -e option of sed.
#
# SUBST_FILTER_CMD.<class>
#	Filter used to perform the actual substitution on the specified
#	files.  Defaults to ${SED} ${SUBST_SED.<class>}.
#
# SUBST_POSTCMD.<class>
#	Command to clean up after sed(1). Defaults to ${RM} -f
#	$$file${_SUBST_BACKUP_SUFFIX}. For debugging, set it to ${DO_NADA}.

ECHO_SUBST_MSG?=	${STEP_MSG}

# _SUBST_IS_TEXT_FILE returns 0 if $${file} is a text file.
_SUBST_IS_TEXT_FILE?= \
	{ ${TEST} -f "$$$$file"						\
	  && ${FILE_CMD} "$$$$file"					\
	     | ${EGREP} "(executable .* script|shell script|text|Assembler source|libtool)";	\
	} >/dev/null 2>&1

_SUBST_BACKUP_SUFFIX=	.subst.sav

define _SUBST_vars
_SUBST_COOKIE.${_class_}=	${WRKDIR}/.subst_${_class_}_done

SUBST_FILTER_CMD.${_class_}?=	${SED} ${SUBST_SED.${_class_}}
SUBST_POSTCMD.${_class_}?=	${RM} -f "$$$$$$$$tmpfile"

SUBST_TARGETS+=			subst-${_class_}
endef
$(foreach _class_,${SUBST_CLASSES},$(eval $(_SUBST_vars)))

define _SUBST_rules
ifdef SUBST_STAGE.${_class_}
${SUBST_STAGE.${_class_}}: subst-${_class_}
endif

.PHONY: subst-${_class_}
subst-${_class_}: ${_SUBST_COOKIE.${_class_}}

${_SUBST_COOKIE.${_class_}}:
  ifdef SUBST_MESSAGE.${_class_}
	${RUN}								\
	${ECHO_SUBST_MSG} $(call quote,${SUBST_MESSAGE.${_class_}})
  endif
	${RUN}								\
	cd ${WRKSRC};							\
	files=${SUBST_FILES.${_class_}};				\
	for file in $$$$files; do					\
		case $$$$file in /*) ;; *) file="./$$$$file";; esac;	\
		tmpfile="$$$$file"${_SUBST_BACKUP_SUFFIX};		\
		if ${_SUBST_IS_TEXT_FILE}; then				\
			${MV} -f "$$$$file" "$$$$tmpfile" || exit 1;	\
			${SUBST_FILTER_CMD.${_class_}}			\
			< "$$$$tmpfile"					\
			> "$$$$file";					\
			if ${TEST} -x "$$$$tmpfile"; then		\
				${CHMOD} +x "$$$$file";			\
			fi;						\
			if ${CMP} -s "$$$$tmpfile" "$$$$file"; then 	\
				${MV} -f "$$$$tmpfile" "$$$$file";	\
			else						\
				${SUBST_POSTCMD.${_class_}};		\
				${ECHO} "$$$$file" >> $$@;		\
			fi;						\
		elif ${TEST} -f "$$$$file"; then			\
			${WARNING_MSG} "[subst.mk] Ignoring non-text file \"$$$$file\"." 1>&2; \
		else							\
			${WARNING_MSG} "[subst.mk] Ignoring non-existent file \"$$$$file\"." 1>&2; \
		fi;							\
	done
	${RUN}${TOUCH} ${TOUCH_FLAGS} $$@
endef
$(foreach _class_,${SUBST_CLASSES},$(eval $(_SUBST_rules)))
