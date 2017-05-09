#
# Copyright (C) 2014 Jens Korinth, TU Darmstadt
#
# This file is part of ThreadPoolComposer (TPC).
#
# ThreadPoolComposer is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ThreadPoolComposer is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with ThreadPoolComposer.  If not, see <http://www.gnu.org/licenses/>.
#
export ARCH=`uname -m`
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$TPC_HOME/arch/baseline/lib/$ARCH:$TPC_HOME/platform/zynq/lib/$ARCH
export LIBPLATFORM_SERVER_LIB=$TPC_HOME/platform/zynq/lib/$ARCH/libplatform-server
export LIBPLATFORM_DEBUG=0xffffffff

