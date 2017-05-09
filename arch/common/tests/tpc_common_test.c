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
//! @file	tpc_common_test.c
//! @brief	Basic check test suite implementation for arch/common unit tests.
//! @authors	J. Korinth, TU Darmstadt (jk@esa.cs.tu-darmstadt.de)
//!
#include <stdlib.h>
#include <check.h>
#include <tpc_logging.h>
#include "tpc_jobs_test.h"
#include "tpc_functions_test.h"

int main(void)
{
	TCase *testcases[] = {
		jobs_testcase(),
		functions_testcase(),
	};

	Suite *s = suite_create("tpc_common");
	for (int tc = 0; tc < sizeof(testcases) / sizeof(*testcases); ++tc)
		suite_add_tcase(s, testcases[tc]);

	int number_failed = 0;
	tpc_logging_init();
	SRunner *sr = srunner_create(s);
	srunner_run_all(sr, CK_VERBOSE);
	number_failed = srunner_ntests_failed(sr);
	srunner_free(sr);
	tpc_logging_exit();

	return number_failed == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}
