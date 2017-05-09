//
// Copyright (C) 2014 Jens Korinth, TU Darmstadt
//
// This file is part of ThreadPoolComposer (TPC).
//
// ThreadPoolComposer is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ThreadPoolComposer is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with ThreadPoolComposer.  If not, see <http://www.gnu.org/licenses/>.
//
//! @file	warraw.c
//! @brief	Trivial kernel: Performs nonsensical computation over loop with 
//! 		WAR (write-after-read) and RAW (read-after-write) intra-loop 
//! 		dependencies.
//! @authors	J. Korinth (jk@esa.cs.tu-darmstadt.de)
//!
#include "warraw.h"

int warraw(int arr[SZ])
{
	int i = 0, r = 0;
	L1: for (; i < SZ; ++i) {
		r += arr[i];
		arr[i] = 42 + (i+1);
		r += arr[i];
	}
	return r;
}
