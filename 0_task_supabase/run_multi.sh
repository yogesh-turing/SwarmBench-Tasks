cd /w/git/harbor
echo "Running multi agent run..."
export FIREWORKS_API_KEY=fw_fcxAa4Ds1z7Ue81Q5ynvF
echo "FIREWORKS_API_KEY: $FIREWORKS_API_KEY"

rm -rf ../tasks/0_task_supabase/execution_logs/multi-kimi-agent
echo "Cleaned up old execution logs."

echo "Starting multi agent run..."

# clear harbor cache
rm -rf /tmp/harbor_cache
uv run harbor run -p "../tasks/0_task_supabase" -a swarm-kimi-multi -m fireworks_ai/accounts/fireworks/models/kimi-k2p5 -k 1 -n 1 --job-name "multi-kimi-agent" --jobs-dir "../tasks/0_task_supabase/execution_logs" --ve FIREWORKS_API_KEY=$FIREWORKS_API_KEY  --ae FIREWORKS_API_KEY=$FIREWORKS_API_KEY  --quiet

echo "Multi agent run completed. Logs are in ../tasks/0_task_supabase/execution_logs/multi-kimi-agent"