cd /w/git/harbor
echo "Running oracle..."
export FIREWORKS_API_KEY=fw_fcxAa4Ds1z7Ue81Q5ynvF
echo "FIREWORKS_API_KEY: $FIREWORKS_API_KEY"

rm -rf ../tasks/0_task_supabase/execution_logs/oracle
echo "Cleaned up old execution logs."

echo "Starting oracle job..."
# clear harbor cache
rm -rf /tmp/harbor_cache
uv run harbor run -p "../tasks/0_task_supabase" -a oracle --job-name "oracle" --jobs-dir "../tasks/0_task_supabase/execution_logs" --ve FIREWORKS_API_KEY=$FIREWORKS_API_KEY
echo "Oracle run completed. Logs are in ../tasks/0_task_supabase/execution_logs/oracle"