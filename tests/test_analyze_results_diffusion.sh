#!/bin/bash

export DEBUG=1
cp sample_config_file_diffusion.txt .spt_pipeline.config
spt-analyze-results > logs/test_analysis_diffusion.out
