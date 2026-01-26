# Module: 1

### 1.2.1: Intro to Docker

- Data Pipeline
    - Source (CSV) ⇒ Data pipeline (Python scripts) ⇒ Destination (Postgres)
- Docker
    - Completely isolated containers on host OS
    - Docker image provides Reproducibility
- Why Docker?
    - Reproducibility
    - Local experiments
    - Integration tests (CI/CD)
    - Running pipelines on Cloud (AWS Batch, Kubernetes Jobs)
    - Spark
    - Serverless (AWS Lambda, Google Functions)
- Commands
    - Hello World
        - `docker run hello-world`
    - To run in interactive mode
        - `docker run -it <image>`
            - i → interactive
            - t → terminal
    - To change entrypoint
        - `docker run -it --entrypoint=bash <image>`
- Dockerfile
    - Adding all the instructions required to create a new image
    - Syntax
        - FROM
            - Base image
        - RUN
            - To run command
        - ENTRYPOINT [”python”, “pipeline.py”]
            - The starting point when docker runs
        - WORKDIR
            - The working directory when docker runs
        - COPY
            - To copy files
    - Commands
        - To build a image
            - `docker build -t <image-name>:<version> .`
        - To run the pipeline
            - docker run -it pipeline:latest <date>

### Workshop

- What is docker?
    - To provide completely isolated container environment from the host machine
- Stateless container
    - Containers are created from the image without the state
- Overriding entry-point
    - Entry-point can be overridden by `--entrypoint` argument
- To remove all dockers
    - `docker rm `docker ps -aq``
- Data pipeline
    - It takes inputs, process it and provide outputs to the destinations
- Running pipeline with Docker
- `click`
    - For creating parameter in CLI app
- Docker network
    - Within the same network, docker containers can communicate each other

### 1.3.1: Terraform Primer

- Why Terraform?
    - Simplicity in keeping track of infrastructure
    - Easier collaboration
    - Reproducibility
    - Ensure resources are removed
- Terraform providers
    - Code that allows terraform to communicate to manage resources on
- Key cmds
    - `init` - Get me providers I need
    - `plan` - What am I about to do?
    - `apply` - Do what is in the tf files
    - `destroy` - Remove everything defined in the tf files

### 1.3.2: Terraform  Basics

- `terraform fmt`
    - To format tf files

### 1.3.3: Terraform Variables

- variables.tf
- var.<var-name>