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
//! @file	tpc_functions.h
//! @brief	Defines a micro API to access the functions available in a 
//!             hardware threadpool, perform enumeration, locking etc.
//! @authors	J. Korinth, TU Darmstadt (jk@esa.cs.tu-darmstadt.de)
//!
#ifndef __TPC_FUNCTIONS_H__
#define __TPC_FUNCTIONS_H__

#include <tpc_api.h>

#define TPC_MAX_INSTANCES					128

/**
 * Identifies a 'slot' in the configuration, i.e., one possible instantiation
 * place for a kernel in the bitstream.
 **/
typedef int32_t tpc_func_slot_id_t;

/** Implementation defined functions struct. (opaque) */
typedef struct tpc_functions tpc_functions_t;

/**
 * Initializes a function struct by populating with current data from device.
 * @param funcs pointer to internal functions struct pointer.
 * @return TPC_SUCCESS if successful.
 **/
tpc_res_t tpc_functions_init(tpc_functions_t **funcs);

/**
 * Releases the given function struct an allocated memory.
 * @param funcs pointer to internal functions struct.
 **/
void tpc_functions_deinit(tpc_functions_t *funcs);

/**
 * Supporting function: Perform initial setup of the system, e.g., activate 
 * interrupts at each kernel instance, etc.
 * @param dev_ctx device context.
 * @param ctx functions context.
 **/
void tpc_functions_setup_system(tpc_dev_ctx_t *dev_ctx, tpc_functions_t *ctx);

/**
 * Reserves a slot containing an instance of the given function (if possible).
 * @param ctx functions context.
 * @param f_id function identifier.
 * @return slot_id >= 0 if successful, < 0 otherwise.
 **/
tpc_func_slot_id_t tpc_functions_acquire(tpc_functions_t *ctx,
		tpc_func_id_t const f_id);

/**
 * Releases a previously acquired slot.
 * @param ctx functions context.
 * @param s_id slot identifier.
 */
void tpc_functions_release(tpc_functions_t *ctx, tpc_func_slot_id_t const s_id);

/**
 * Returns the number of available instances of the kernel with the given
 * function identifier.
 * @param ctx functions context.
 * @param f_id function identifier.
 * @param Number of instances currently configured (0 if none).
 **/
uint32_t tpc_functions_count(tpc_functions_t const *ctx, tpc_func_id_t const f_id);

#endif /* __TPC_FUNCTIONS_H__ */

