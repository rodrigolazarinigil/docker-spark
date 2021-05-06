ARG base_spark_image

FROM ${base_spark_image}

USER root

ENV APP_HOME /opt
ENV GOOGLE_APPLICATION_CREDENTIALS=${APP_HOME}/gcp/service_account.json
ENV PYSPARK_PYTHON python3
ENV PATH ${PATH}:${SPARK_HOME}/bin
ENV PYTHONPATH /opt/dist/
ENV PATH $PATH:/root/google-cloud-sdk/bin

ADD poetry.lock pyproject.toml ./
ENV POETRY_CORE=1.0.2
ENV POETRY_VERSION=1.1.4

RUN pip3 install --upgrade pip && \
    pip3 install "poetry-core==$POETRY_CORE" "poetry==$POETRY_VERSION" && \
	poetry config virtualenvs.create false && \
	poetry install --no-dev --no-interaction --no-ansi && \
	apt-get install -y git curl && \
	mkdir /root/.ssh/ && \
	touch /root/.ssh/known_hosts && \
	ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts && \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    mkdir -p /opt/dist/ && \
    mkdir -p ~/.local/bin/ && \
    mv ./kubectl ~/.local/bin/kubectl && \
    chmod u+x ~/.local/bin/kubectl && \
    curl -sSL https://sdk.cloud.google.com | bash

ADD jars/* ${SPARK_HOME}/jars/
ADD ./entrypoint.sh /opt/custom_entrypoint.sh
ADD spark-defaults.conf ${SPARK_HOME}/

WORKDIR ${SPARK_HOME}

ENTRYPOINT [ "/opt/custom_entrypoint.sh" ]
