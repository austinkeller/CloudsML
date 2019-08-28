FROM jupyter/datascience-notebook:58169ec3cfd3

USER root

# Install system packages here, if necessary
# RUN apt-get update -y && apt-get install -y yourdesiredpackage

WORKDIR /home/jovyan

USER $NB_USER

