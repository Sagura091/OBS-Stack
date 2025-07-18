FROM python:3.12-slim

# system deps
RUN apt-get update && apt-get install -y git gcc g++ curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY pyproject.toml .
RUN pip install --no-cache-dir -r <(python -m pip install --dry-run -r pyproject.toml 2>&1 | grep -o '/.*\.whl')
COPY . .

RUN pip install --no-cache-dir .

ENTRYPOINT ["./entrypoint.sh"]
