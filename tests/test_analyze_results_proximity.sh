#!/bin/bash

export DEBUG=1
cp sample_config_file_proximity.txt .spt_pipeline.config
spt-analyze-results > logs/test_analysis_proximity.out
