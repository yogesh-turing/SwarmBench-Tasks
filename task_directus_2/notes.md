```export FIREWORKS_API_KEY=fw_fcxAa4Ds1z7Ue81Q5ynvF```

# Folder: W:\git\tasks\task_directus_2

```TASK_DIRECTUS_2=../tasks/task_directus_2```

```echo $TASK_DIRECTUS_2```
```echo $FIREWORKS_API_KEY```

## Run Oracle
```
uv run harbor run -p "../tasks/task_directus_2" -a oracle --job-name "oracle" --jobs-dir "../tasks/task_directus_2/execution_logs" --ve FIREWORKS_API_KEY=$FIREWORKS_API_KEY
```

## Run Single Agent
```
uv run harbor run -p "../tasks/task_directus_2" -a swarm-kimi-single -m fireworks_ai/accounts/fireworks/models/kimi-k2p5 -k 1 -n 1 --job-name "single-kimi-agent" --jobs-dir "../tasks/task_directus_2/execution_logs" --ve FIREWORKS_API_KEY=$FIREWORKS_API_KEY  --ae FIREWORKS_API_KEY=$FIREWORKS_API_KEY  --quiet
```

## Run Multi Agent
```
uv run harbor run -p "../tasks/task_directus_2" -a swarm-kimi-multi -m fireworks_ai/accounts/fireworks/models/kimi-k2p5 -k 1 -n 1 --job-name "multi-kimi-agent" --jobs-dir "../tasks/task_directus_2/execution_logs" --ve FIREWORKS_API_KEY=$FIREWORKS_API_KEY  --ae FIREWORKS_API_KEY=$FIREWORKS_API_KEY  --quiet
```

# Outputs

### oracle

yoges@DESKTOP-VS0F5UF MINGW64 /w/git/harbor ((e70d5f06...))
$ uv run harbor run -p "../tasks/task_directus_2" -a oracle --job-name "oracle" --jobs-dir "../tasks/task_directus_2/execution_logs" --ve FIREWORKS_API_KEY=$FIREWORKS_API_KEY
  1/1 Mean: 1.000 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 0:00:21 0:00:00

adhoc • oracle
┏━━━━━━━━┳━━━━━━━━━━━━┳━━━━━━━┓
┃ Trials ┃ Exceptions ┃  Mean ┃
┡━━━━━━━━╇━━━━━━━━━━━━╇━━━━━━━┩
│      1 │          0 │ 1.000 │
└────────┴────────────┴───────┘

┏━━━━━━━━┳━━━━━━━┓
┃ Reward ┃ Count ┃
┡━━━━━━━━╇━━━━━━━┩
│ 1.0    │     1 │
└────────┴───────┘

Job Info
Total runtime: 21s
Results written to ..\tasks\task_directus_2\execution_logs\oracle\result.json
Inspect results by running `harbor view ..\tasks\task_directus_2\execution_logs`
Share results by running `harbor upload ..\tasks\task_directus_2\execution_logs\oracle`

--------------------------------------------------------------------------------------------------------------------------------------


### Single agent

yoges@DESKTOP-VS0F5UF MINGW64 /w/git/harbor ((e70d5f06...))
$ uv run harbor run -p "../tasks/task_directus_2" -a swarm-kimi-single -m fireworks_ai/accounts/fireworks/models/kimi-k2p5 -k 1 -n 1 --job-name "single-kimi-agent" --jobs-dir "../tasks/task_directus_2/execution_logs" --ve FIREWORKS_API_KEY=$FIREWORKS_API_KEY  --ae FIREWORKS_API_KEY=$FIREWORKS_API_KEY  --quiet
⠋ 1/1 Running trials... ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 0:00:00 -:--:--

adhoc • swarm-kimi-single • accounts/fireworks/models/kimi-k2p5
┏━━━━━━━━┳━━━━━━━━━━━━┳━━━━━━━┓
┃ Trials ┃ Exceptions ┃  Mean ┃
┡━━━━━━━━╇━━━━━━━━━━━━╇━━━━━━━┩
│      1 │          0 │ 0.500 │
└────────┴────────────┴───────┘

┏━━━━━━━━┳━━━━━━━┓
┃ Reward ┃ Count ┃
┡━━━━━━━━╇━━━━━━━┩
│ 0.5    │     1 │
└────────┴───────┘

Job Info
Total runtime: 17m 8s
Results written to ..\tasks\task_directus_2\execution_logs\single-kimi-agent\result.json
Inspect results by running `harbor view ..\tasks\task_directus_2\execution_logs`
Share results by running `harbor upload ..\tasks\task_directus_2\execution_logs\single-kimi-agent`


--------------------------------------------------------------------------------------------------------------------------------------

#### Multi agent

yoges@DESKTOP-VS0F5UF MINGW64 /w/git/harbor ((e70d5f06...))
$ uv run harbor run -p "../tasks/task_directus_2" -a swarm-kimi-multi -m fireworks_ai/accounts/fireworks/models/kimi-k2p5 -k 1 -n 1 --job-name "multi-kimi-agent" --jobs-dir "../tasks/task_directus_2/execution_logs" --ve FIREWORKS_API_KEY=$FIREWORKS_API_KEY  --ae FIREWORKS_API_KEY=$FIREWORKS_API_KEY  --quiet
  1/1 Mean: 0.917 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 0:04:31 0:00:00

adhoc • swarm-kimi-multi • accounts/fireworks/models/kimi-k2p5
┏━━━━━━━━┳━━━━━━━━━━━━┳━━━━━━━┓
┃ Trials ┃ Exceptions ┃  Mean ┃
┡━━━━━━━━╇━━━━━━━━━━━━╇━━━━━━━┩
│      1 │          0 │ 0.917 │
└────────┴────────────┴───────┘

┏━━━━━━━━━━━━━━━━━━━━┳━━━━━━━┓
┃ Reward             ┃ Count ┃
┡━━━━━━━━━━━━━━━━━━━━╇━━━━━━━┩
│ 0.9166666666666666 │     1 │
└────────────────────┴───────┘

Job Info
Total runtime: 4m 31s
Results written to ..\tasks\task_directus_2\execution_logs\multi-kimi-agent\result.json
Inspect results by running `harbor view ..\tasks\task_directus_2\execution_logs`
Share results by running `harbor upload ..\tasks\task_directus_2\execution_logs\multi-kimi-agent`

--------------------------------------------------------------------------------------------------------------------------------------




uv run harbor run -p "../final_tasks/8836d4b7ec4248fe8074265d17910ac3-SWARMBENCH-FANOUT-CODESWE-DIRECTUS-BUG-FIXES" -a oracle --job-name "oracle" --jobs-dir "../final_tasks/8836d4b7ec4248fe8074265d17910ac3-SWARMBENCH-FANOUT-CODESWE-DIRECTUS-BUG-FIXES/execution_logs" --ve FIREWORKS_API_KEY=$FIREWORKS_API_KEY



uv run harbor run -p "../final_tasks/8836d4b7ec4248fe8074265d17910ac3-SWARMBENCH-FANOUT-CODESWE-DIRECTUS-BUG-FIXES" -a swarm-kimi-single -m fireworks_ai/accounts/fireworks/models/kimi-k2p5 -k 1 -n 1 --job-name "single-kimi-agent" --jobs-dir "../final_tasks/8836d4b7ec4248fe8074265d17910ac3-SWARMBENCH-FANOUT-CODESWE-DIRECTUS-BUG-FIXES/execution_logs" --ve FIREWORKS_API_KEY=$FIREWORKS_API_KEY  --ae FIREWORKS_API_KEY=$FIREWORKS_API_KEY  --quiet



uv run harbor run -p "../final_tasks/8836d4b7ec4248fe8074265d17910ac3-SWARMBENCH-FANOUT-CODESWE-DIRECTUS-BUG-FIXES" -a swarm-kimi-multi -m fireworks_ai/accounts/fireworks/models/kimi-k2p5 -k 1 -n 1 --job-name "multi-kimi-agent" --jobs-dir "../final_tasks/8836d4b7ec4248fe8074265d17910ac3-SWARMBENCH-FANOUT-CODESWE-DIRECTUS-BUG-FIXES/execution_logs" --ve FIREWORKS_API_KEY=$FIREWORKS_API_KEY  --ae FIREWORKS_API_KEY=$FIREWORKS_API_KEY  --quiet
