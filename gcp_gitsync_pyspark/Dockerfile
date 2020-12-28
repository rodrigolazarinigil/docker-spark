ARG base_spark_image

FROM ${base_spark_image}

USER root

ENV APP_HOME /opt
ENV PYSPARK_PYTHON python3
ENV PATH ${PATH}:${SPARK_HOME}/bin
ENV PYTHONPATH /opt/dist/

ADD poetry.lock pyproject.toml ./
ENV POETRY_VERSION=1.1.4

RUN pip3 install --upgrade pip && \
    pip3 install "poetry==$POETRY_VERSION" && \
	poetry config virtualenvs.create false && \
	poetry install --no-dev --no-interaction --no-ansi && \
	apt-get install -y git && \
	mkdir /root/.ssh/ && \
	touch /root/.ssh/known_hosts && \
	ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts

RUN mkdir -p /opt/dist/

ADD jars/* ${SPARK_HOME}/jars
ADD ./entrypoint.sh /opt/custom_entrypoint.sh
ADD spark-defaults.conf ${SPARK_HOME}/

WORKDIR ${SPARK_HOME}

ENTRYPOINT [ "/opt/custom_entrypoint.sh" ]
