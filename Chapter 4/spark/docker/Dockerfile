FROM spark:3.5.0
USER root
RUN pip install kaggle
RUN apt update && \
    apt install -y vim 
RUN pip install pyspark
WORKDIR /opt/spark
ADD sleep.py .
