FROM python:3.9-alpine

WORKDIR /app

RUN pip install flask flask-cors

CMD ["python", "app.py"]