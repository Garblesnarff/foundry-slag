# Foundry Slag Backend

FastAPI + rembg backend for local background removal.

## Run

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload --port 3458
```

## Notes
- First model run downloads weights into `~/.u2net/`.
- Data is stored under `~/Documents/FoundrySlag/`.
