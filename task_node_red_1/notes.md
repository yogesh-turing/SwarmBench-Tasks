```export FIREWORKS_API_KEY=fw_fcxAa4Ds1z7Ue81Q5ynvF```

# Folder: W:\git\tasks\task_node_red_1

```TASK_DIRECTUS_2=../tasks/task_node_red_1```

```echo $TASK_DIRECTUS_2```
```echo $FIREWORKS_API_KEY```

## Run Oracle
```
uv run harbor run -p "../tasks/task_node_red_1" -a oracle --job-name "oracle" --jobs-dir "../tasks/task_node_red_1/execution_logs" --ve FIREWORKS_API_KEY=$FIREWORKS_API_KEY
```

## Run Single Agent
```
uv run harbor run -p "../tasks/task_node_red_1" -a swarm-kimi-single -m fireworks_ai/accounts/fireworks/models/kimi-k2p5 -k 1 -n 1 --job-name "single-kimi-agent" --jobs-dir "../tasks/task_node_red_1/execution_logs" --ve FIREWORKS_API_KEY=$FIREWORKS_API_KEY  --ae FIREWORKS_API_KEY=$FIREWORKS_API_KEY  --quiet
```

## Run Multi Agent
```
uv run harbor run -p "../tasks/task_node_red_1" -a swarm-kimi-multi -m fireworks_ai/accounts/fireworks/models/kimi-k2p5 -k 1 -n 1 --job-name "multi-kimi-agent" --jobs-dir "../tasks/task_node_red_1/execution_logs" --ve FIREWORKS_API_KEY=$FIREWORKS_API_KEY  --ae FIREWORKS_API_KEY=$FIREWORKS_API_KEY  --quiet
```

# Outputs

### oracle



--------------------------------------------------------------------------------------------------------------------------------------


### Single agent




--------------------------------------------------------------------------------------------------------------------------------------

#### Multi agent



--------------------------------------------------------------------------------------------------------------------------------------