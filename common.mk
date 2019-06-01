SHELL=/bin/bash

ifndef DCP_WORKSPACE_HOME
$(error Please run "source environment" in the dcp-workspace repo root directory before running make commands)
endif
