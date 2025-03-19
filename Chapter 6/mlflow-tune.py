# A modified version of https://docs.ray.io/en/latest/tune/examples/includes/mlflow_ptl_example.html

"""An example showing how to use Pytorch Lightning training, Ray Tune
HPO, and MLflow autologging all together."""

import os
import tempfile

import mlflow
import pytorch_lightning as pl

from ray import train, tune
from ray.air.integrations.mlflow import setup_mlflow, MLflowLoggerCallback
from ray.tune.examples.mnist_ptl_mini import LightningMNISTClassifier, MNISTDataModule
from ray.tune.integration.pytorch_lightning import TuneReportCallback, TuneReportCheckpointCallback


def train_mnist_tune(config, data_dir=None, num_epochs=10, num_gpus=0):
    model = LightningMNISTClassifier(config, data_dir)
    dm = MNISTDataModule(
        data_dir=data_dir, batch_size=config["batch_size"]
    )
    metrics = {"loss": "ptl/val_loss", "acc": "ptl/val_accuracy"}
    
    mlflow.set_tracking_uri(mlflow.get_tracking_uri())
    mlflow.set_experiment(config.get("experiment_name"))
    
    mlflow.pytorch.autolog()
    trainer = pl.Trainer(
        max_epochs=num_epochs,
        accelerator="auto",
        callbacks=[TuneReportCallback(metrics, on="validation_epoch_end")]
    )
    trainer.fit(model, dm)

def tune_mnist(
    num_samples=10,
    num_epochs=10,
    gpus_per_trial=0,
    tracking_uri=None,
    experiment_name="ptl_autologging",
):
    data_dir = os.path.join(tempfile.gettempdir(), "mnist_data_")
    # Download data
    MNISTDataModule(data_dir=data_dir, batch_size=32).prepare_data()

    # Set the MLflow experiment, or create it if it does not exist.
    mlflow.set_tracking_uri(tracking_uri)
    mlflow.set_experiment(experiment_name)

    config = {
        # layer_1 and layer_2 are the number of neurons in the first and second layers
        "layer_1": tune.choice([32, 64, 128]),
        "layer_2": tune.choice([64, 128, 256]),
        # The learning rate
        "lr": tune.loguniform(1e-4, 1e-1),
        "batch_size": tune.choice([32, 64, 128]),
        "experiment_name": experiment_name,
        # The MLflow tracking URI
        "tracking_uri": mlflow.get_tracking_uri(),
        "data_dir": os.path.join(tempfile.gettempdir(), "mnist_data_"),
        "num_epochs": num_epochs,
    }

    trainable = tune.with_parameters(
        train_mnist_tune,
        data_dir=data_dir,
        num_epochs=num_epochs,
        num_gpus=gpus_per_trial,
    )

    tuner = tune.Tuner(
        tune.with_resources(trainable, resources={"cpu": 1, "gpu": gpus_per_trial}),
        tune_config=tune.TuneConfig(
            metric="loss",
            mode="min",
            num_samples=num_samples,
        ),
        run_config=train.RunConfig(
            name="tune_mnist",
            callbacks=[
                MLflowLoggerCallback(
                    tracking_uri=tracking_uri,
                    experiment_name=experiment_name,
                    save_artifact=True,
                )
            ],
        ),
        param_space=config,
    )
    results = tuner.fit()

    print("Best hyperparameters found were: ", results.get_best_result().config)


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--smoke-test", action="store_true", help="Finish quickly for testing"
    )
    parser.add_argument(
        "--tracking-uri",
        type=str,
        help="The tracking URI for the MLflow tracking server.",
    )
    args, _ = parser.parse_known_args()

    if args.smoke_test:
        mlflow_tracking_uri = os.path.join(tempfile.gettempdir(), "mlruns")
    else:
        mlflow_tracking_uri = args.tracking_uri
        

    if args.smoke_test:
        tune_mnist(
            num_samples=1,
            num_epochs=1,
            gpus_per_trial=0,
            tracking_uri=os.path.join(tempfile.gettempdir(), "mlruns"),
        )
    else:
        # num_epochs is set to 2 to shorten the experiment duration
        tune_mnist(num_samples=10, num_epochs=2, gpus_per_trial=0, tracking_uri=mlflow_tracking_uri)
