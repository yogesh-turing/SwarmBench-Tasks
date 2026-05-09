# env setp
export FIREWORKS_API_KEY=fw_fcxAa4Ds1z7Ue81Q5ynvF
echo $FIREWORKS_API_KEY


# Task Folder
W:\git\tasks\0_task_supabase

## Run Oracle

rm -rf ../tasks/0_task_supabase/execution_logs/oracle
uv run harbor run -p "../tasks/0_task_supabase" -a oracle --job-name "oracle" --jobs-dir "../tasks/0_task_supabase/execution_logs" --ve FIREWORKS_API_KEY=$FIREWORKS_API_KEY


## Run Single Agent

uv run harbor run -p "../tasks/task_directus_2" -a swarm-kimi-single -m fireworks_ai/accounts/fireworks/models/kimi-k2p5 -k 1 -n 1 --job-name "single-kimi-agent" --jobs-dir "../tasks/task_directus_2/execution_logs" --ve FIREWORKS_API_KEY=$FIREWORKS_API_KEY  --ae FIREWORKS_API_KEY=$FIREWORKS_API_KEY  --quiet


## Run Multi Agent

uv run harbor run -p "../tasks/task_directus_2" -a swarm-kimi-multi -m fireworks_ai/accounts/fireworks/models/kimi-k2p5 -k 1 -n 1 --job-name "multi-kimi-agent" --jobs-dir "../tasks/task_directus_2/execution_logs" --ve FIREWORKS_API_KEY=$FIREWORKS_API_KEY  --ae FIREWORKS_API_KEY=$FIREWORKS_API_KEY  --quiet

