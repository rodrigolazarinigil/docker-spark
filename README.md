# Pyspark 3.0.1 (docker)
> Versão customizada do pyspark


## Comandos

- Baixar imagem docker. Confira no GCR qual a versão mais nova:
    ```
    docker pull us.gcr.io/<company_prefix>/custom-spark-py:latest
    ```

- Executar submit local para rodar no kubernetes:
    1. Tenha seu código em um repositório no git
    2. Crie uma chave deploy key: https://developer.github.com/v3/guides/managing-deploy-keys/
    3. Adicione chave numa secret no kubernetes:
        ```
        kubectl create secret generic ${SECRET_NAME} --from-file id_rsa=${PRIVATE_KEY_PATH}
        ```
    4. Execute o `docker run`
        ```
        docker run --rm \
        -v ${HOME}/.kube/config:/root/.kube/config \
        -v ${HOME}/.ssh/id_rsa:/root/.ssh/id_rsa us.gcr.io/<company_prefix>-datalake-prod/custom-spark-py:latest \
        spark-submit \
            --master k8s://${K8S_URL} \
            --name k8stest \
            --deploy-mode cluster \
            --conf spark.driver.instances=1 \
            --conf spark.executor.instances=1 \
            --conf spark.driver.cores=1 \
            --conf spark.executor.cores=1 \
            --conf spark.driver.memory=1g \
            --conf spark.executor.memory=1g \
            --properties-file /opt/spark/spark-defaults.conf \
            --conf spark.kubernetes.namespace=dataplatform \
            --conf spark.kubernetes.container.image=us.gcr.io/<company_prefix>-datalake-prod/custom-spark-py:latest \
            --conf spark.kubernetes.container.image.pullPolicy=Always \
            --conf spark.kubernetes.driver.secrets.${SECRET_NAME}=/tmp/git \
            --conf spark.kubernetes.executor.secrets.${SECRET_NAME}=/tmp/git \
            --conf spark.executorEnv.GIT_DEPLOY_KEY_PATH="/tmp/git" \
            --conf spark.executorEnv.REPOSITORY_URL="${GIT_URL}" \
            --conf spark.executorEnv.REPOSITORY_BRANCH="${GIT_BRANCH}" \
            --conf spark.executorEnv.REPOSITORY_DIRECTORY="${GIT_DIR}" \
            /opt/dist/dir/file.py ${JOB_ARGS}
        ```
        _Ex. de K8S_URL: https://35.233.230.128_
        _Ex. de GIT_URL: git@github.com:<company_name>/datalake.git_
