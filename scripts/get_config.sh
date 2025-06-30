#!/bin/bash

# --- Configuration ---
if [ -z "${HF_TOKEN}" ]; then
  echo "Error: The HF_TOKEN environment variable is not set." >&2
  echo "Please set it to your Hugging Face API token." >&2
  echo "Example: export HF_TOKEN=\"hf_YOUR_ACTUAL_TOKEN_HERE\"" >&2
  exit 1
fi

# --- Script Logic ---
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <model_name> <num_devices>" >&2
  echo "Example: $0 meta-llama/Meta-Llama-3-8B 1" >&2
  exit 1
fi

MODEL_NAME="$1"
INPUT_NUM_DEVICES="$2"
PROCESSED_NUM_DEVICES=$(echo "$INPUT_NUM_DEVICES" | jq -R 'split(",") | map(tonumber)')
if [ $? -ne 0 ]; then
  echo "Error: Could not parse num_devices input \"$INPUT_NUM_DEVICES\"." >&2
  exit 1
fi

CONFIG_URL="https://huggingface.co/${MODEL_NAME}/raw/main/config.json"
echo "${CONFIG_URL}"

JSON_CONTENT=$(curl -sL -H "Authorization: Bearer ${HF_TOKEN}" "${CONFIG_URL}")

ARCHITECTURES=$(echo "$JSON_CONTENT" | jq -r '.architectures // .text_config.architectures // empty | join(", ")')
echo "Architectures: $ARCHITECTURES"
if [ $? -ne 0 ]; then
  echo "Error: curl command failed." >&2
  exit 1
fi

if echo "$JSON_CONTENT" | head -n 1 | grep -q '<!doctype html>'; then
  echo "Error: Received HTML instead of JSON." >&2
  echo "$JSON_CONTENT" | head -n 20 >&2
  exit 1
fi

# Extract fields with fallback to text_config
NUM_Q_HEADS=$(echo "$JSON_CONTENT" | jq -r '.num_attention_heads // .text_config.num_attention_heads // 0')
NUM_KV_HEADS=$(echo "$JSON_CONTENT" | jq -r '.num_key_value_heads // .text_config.num_key_value_heads // 0')
HIDDEN_SIZE=$(echo "$JSON_CONTENT" | jq -r '.hidden_size // .text_config.hidden_size // 0')
HEAD_DIM_RAW=$(echo "$JSON_CONTENT" | jq -r '.head_dim // .text_config.head_dim // 0')

# Compute head_dim2
if [ "$NUM_Q_HEADS" -gt 0 ]; then
  HEAD_DIM2=$((HIDDEN_SIZE / NUM_Q_HEADS))
else
  HEAD_DIM2=0
fi

# Use JSON's head_dim if valid, otherwise fall back to head_dim2
if [[ "$HEAD_DIM_RAW" =~ ^[0-9]+$ && "$HEAD_DIM_RAW" -gt 0 ]]; then
  HEAD_DIM="$HEAD_DIM_RAW"
else
  HEAD_DIM="$HEAD_DIM2"
fi

BASE_MODEL_NAME=$(echo "$MODEL_NAME" | awk -F'/' '{print $NF}')

# Output JSON
if [ "$HEAD_DIM" -ne "$HEAD_DIM2" ]; then
  OUTPUT_JSON=$(jq -n \
    --arg model "$BASE_MODEL_NAME" \
    --argjson num_q_heads "$NUM_Q_HEADS" \
    --argjson num_kv_heads "$NUM_KV_HEADS" \
    --argjson head_dim "$HEAD_DIM" \
    --argjson head_dim2 "$HEAD_DIM2" \
    --argjson num_devices_arr "$PROCESSED_NUM_DEVICES" \
  '{
    ($model): {
      "num_q_heads": $num_q_heads,
      "num_kv_heads": $num_kv_heads,
      "head_dim": $head_dim,
      "head_dim2": $head_dim2,
      "num_devices": $num_devices_arr
    }
  }')
else
  OUTPUT_JSON=$(jq -n \
    --arg model "$BASE_MODEL_NAME" \
    --argjson num_q_heads "$NUM_Q_HEADS" \
    --argjson num_kv_heads "$NUM_KV_HEADS" \
    --argjson head_dim "$HEAD_DIM" \
    --argjson num_devices_arr "$PROCESSED_NUM_DEVICES" \
  '{
    ($model): {
      "num_q_heads": $num_q_heads,
      "num_kv_heads": $num_kv_heads,
      "head_dim": $head_dim,
      "num_devices": $num_devices_arr
    }
  }')
fi

echo "$OUTPUT_JSON"
