#!/bin/bash

# this script need to run under /TensorRT-LLM/benchmarks/cpp
# It generates a random datasets using TensorRT-LLM's code.
# change this script below to get what you need.

generate_dataset() {
  local model_name=$1
  local isl=$2
  local osl=$3
  local num_requests=$4
  local tp_size=$5

  echo "Generating dataset for $model_name with ISL=$isl, OSL=$osl, TP=$tp_size"

  dataset_file="/tmp/dataset/${model_name##*/}_${isl}_${osl}_tp${tp_size}.json"

  echo "creating $dataset_file"
  python prepare_dataset.py \
    --tokenizer=$model_name \
    --stdout token-norm-dist \
    --num-requests=$num_requests \
    --input-mean=$isl \
    --output-mean=$osl \
    --input-stdev=0 \
    --output-stdev=0 > $dataset_file
}

# model_name="mistralai/Mixtral-8x7B-v0.1"
# tp_size=8
# generate_dataset "$model_name" 128 128 1000 $tp_size
# generate_dataset "$model_name" 128 128 30000 $tp_size
# generate_dataset "$model_name" 128 2048 3000 $tp_size
# generate_dataset "$model_name" 128 4096 1500 $tp_size
# generate_dataset "$model_name" 500 2000 3000 $tp_size
# generate_dataset "$model_name" 1000 1000 3000 $tp_size
# generate_dataset "$model_name" 2048 128 3000 $tp_size
# generate_dataset "$model_name" 2048 2048 1500 $tp_size
# generate_dataset "$model_name" 5000 500 1500 $tp_size
# generate_dataset "$model_name" 20000 2000 1000 $tp_size

model_name="meta-llama/Llama-3.1-8B-Instruct"
tp_size=1
generate_dataset "$model_name" 128 128 1000 $tp_size