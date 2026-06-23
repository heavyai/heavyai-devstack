# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

# Configuration file for JupyterHub
import os

c = get_config()  # type: ignore # noqa: F821

# Spawn single-user servers as Docker containers
c.JupyterHub.spawner_class = "dockerspawner.DockerSpawner"

# Spawn containers from this image
c.DockerSpawner.image = os.environ["DOCKER_NOTEBOOK_IMAGE"]

# Default to using the start-singleuser.sh script included in the
# jupyter/docker-stacks *-notebook images as the Docker run command
spawn_cmd = os.environ.get("DOCKER_SPAWN_CMD", "start-singleuser.sh")
c.DockerSpawner.cmd = spawn_cmd

# Connect containers to this Docker network
c.DockerSpawner.network_name = os.environ["DOCKER_NETWORK_NAME"]

# Explicitly set notebook directory
notebook_dir = os.environ.get("DOCKER_NOTEBOOK_DIR", "/home/jovyan/work")
c.DockerSpawner.notebook_dir = notebook_dir

# Mount volumes for users and shared data
c.DockerSpawner.volumes = {
    "jupyterhub-user-{username}": notebook_dir,
    "/var/lib/heavyai": "/var/lib/heavyai"
}

# Remove containers once they are stopped (set this to True or False based on your needs)
c.DockerSpawner.remove = True

# For debugging arguments passed to spawned containers
c.DockerSpawner.debug = True

# Set additional environment variables and user privileges
c.DockerSpawner.extra_create_kwargs = {'user': 'root'}
c.DockerSpawner.environment = {
    'GRANT_SUDO': '1',
    'UID': '0',
}

# Networking configuration
c.Spawner.default_url = '/lab'
c.Spawner.args = ['--NotebookApp.allow_origin=*']

# JupyterHub network settings
c.JupyterHub.hub_ip = '0.0.0.0'
c.JupyterHub.base_url = '/jupyter/'

# Persist hub data on volume mounted inside container
c.JupyterHub.cookie_secret_file = "/data/jupyterhub_cookie_secret"
c.JupyterHub.db_url = "sqlite:////data/jupyterhub.sqlite"

# Authenticate users with Dummy Authenticator for testing (remove for production)
c.JupyterHub.authenticator_class = "dummyauthenticator.DummyAuthenticator"
