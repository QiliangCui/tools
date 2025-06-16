# tools

#### ./scripts/get_config.sh 

Prestep
```
export HF_TOKEN=<token>
```

Run
```
sage: ./scripts/get_config.sh <model_name> <num_devices>
Example 1 (single device): ./scripts/get_config.sh meta-llama/Meta-Llama-3-8B 1
Example 2 (multiple devices): ./scripts/get_config.sh meta-llama/Meta-Llama-3-8B "1,8,16"
```