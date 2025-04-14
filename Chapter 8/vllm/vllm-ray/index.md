# Deploying vLLM on Ray

This guide walks through the steps to deploy [vLLM](https://github.com/vllm-project/vllm) on a Ray cluster running in Kubernetes. vLLM is a high-throughput and memory-efficient LLM inference engine. When combined with Ray, you can scale inference workloads efficiently across a Kubernetes cluster.

## Step 1: Configure Hugging Face API Access

To download models from the Hugging Face Hub, vLLM needs access to your Hugging Face account. This is typically done using a Hugging Face API token.

### 1.1 Generate a Hugging Face API Token

1. Go to [https://huggingface.co/settings/tokens](https://huggingface.co/settings/tokens)
2. Create a new token with `read` access
3. Copy the token securely — you will use it in the next step

### 1.2 Create a Kubernetes Secret for the Token

Use the following command to create a secret in your Kubernetes cluster:

```bash
kubectl create secret generic hf-token \
  --from-literal=HUGGING_FACE_HUB_TOKEN=<your-token-here>
```

Replace `<your-token-here>` with the actual token you copied in step 1.1.

This secret will be mounted into the vLLM pods so the engine can authenticate with Hugging Face to pull models.

---

## Step 2: Apply the vLLM RayService Manifest

Once the secret is created, you can deploy the vLLM workload using the provided RayService manifest.

The file is named `ray-service.vllm.yaml` and is included in the GitHub repository for this book. It is based on the official example from the [KubeRay repository](https://github.com/ray-project/kuberay/blob/master/ray-operator/config/samples/vllm/ray-service.vllm.yaml).

Apply the manifest using the following command:

```bash
kubectl apply -f ray-service.vllm.yaml
```

This will deploy a Ray cluster with vLLM configured to serve the Meta LLaMA 3 8B Instruct model. The service exposes an HTTP route for inference requests and leverages GPU resources for fast generation.

