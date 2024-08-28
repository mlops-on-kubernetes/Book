from ray.job_submission import JobSubmissionClient
from os import environ

client = JobSubmissionClient()

run_torch = (
    "python pytorch-sample.py"
)

submission_id = client.submit_job(
    entrypoint = run_torch,
    runtime_env = {
        "pip": ["torch", "torchvision"],
        "working_dir": "./",
    }
)

print("Use the following command to follow this Job's logs:")
print(f"ray job logs '{submission_id}' --follow")

