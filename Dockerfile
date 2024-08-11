FROM public.ecr.aws/docker/library/python:3.10

WORKDIR /app

COPY /analytics/ /app

RUN apt update -y
RUN apt install build-essential libpq-dev -y
RUN pip install --upgrade pip setuptools wheel 
RUN pip install pipenv
RUN pipenv install --python $(which python) --skip-lock
RUN pipenv install -r requirements.txt --skip-lock --verbose 

EXPOSE 5153

ENV DB_USERNAME=myuser
ENV DB_PASSWORD=mypassword
ENV DB_HOST=127.0.0.1
ENV DB_PORT=5433
ENV DB_NAME=mydatabase

CMD pipenv run python app.py
