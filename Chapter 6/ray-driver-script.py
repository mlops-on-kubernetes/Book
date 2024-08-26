from ray.job_submission import JobSubmissionClient
from os import environ
#ray_address = environ['RAY_ADDRESS']
#client = JobSubmissionClient("http://"+ray_address+":8265")
client = JobSubmissionClient()

run_torch = (
    "git clone https://github.com/ray-project/ray || true; "
    "python ray/release/air_tests/air_benchmarks/workloads/torch_benchmark.py"
    " --num-workers 2"
)


submission_id = client.submit_job(
    entrypoint = run_torch,
    runtime_env = {
        "pip": ["torch", "torchvision"],
    }
)

print("Use the following command to follow this Job's logs:")
print(f"ray job logs '{submission_id}' --follow")

