FROM 763104351884.dkr.ecr.us-west-2.amazonaws.com/tensorflow-training:2.14.1-cpu-py310-ubuntu20.04-ec2

RUN pip install tensorflow_datasets

COPY multi_worker_strategy-with-keras.py /
ENTRYPOINT ["python", "/multi_worker_strategy-with-keras.py", "--saved_model_dir", "/train/saved_model/", "--checkpoint_dir", "/train/checkpoint"]
