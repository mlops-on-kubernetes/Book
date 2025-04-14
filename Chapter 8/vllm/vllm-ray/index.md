Deploying vLLM on Ray

This guide walks through the steps to deploy vLLM on a Ray cluster running in Kubernetes. vLLM is a high-throughput and memory-efficient LLM inference engine. When combined with Ray, you can scale inference workloads efficiently across a Kubernetes cluster.

Step 1: Configure Hugging Face API Access

To download models from the Hugging Face Hub, vLLM needs access to your Hugging Face account. This is typically done using a Hugging Face API token.

1.1 Generate a Hugging Face API Token

Go to https://huggingface.co/settings/tokens

Create a new token with read access

Copy the token securely — you will use it in the next step

1.2 Create a Kubernetes Secret for the Token

Use the following command to create a secret in your Kubernetes cluster:

kubectl create secret generic hf-token \
  --from-literal=HUGGING_FACE_HUB_TOKEN=<your-token-here>

Replace <your-token-here> with the actual token you copied in step 1.1.

This secret will be mounted into the vLLM pods so the engine can authenticate with Hugging Face to pull models.

