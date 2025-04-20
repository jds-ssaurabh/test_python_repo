from fastapi import FastAPI, Request, Form
from starlette.responses import RedirectResponse
from fastapi.templating import Jinja2Templates
from fastapi.responses import HTMLResponse
from typing import Dict
from pydantic import BaseModel
from uuid import uuid4

app = FastAPI()
templates = Jinja2Templates(directory="templates")

# In-memory DB
items_db: Dict[str, Dict] = {}

@app.get("/", response_class=HTMLResponse)
def read_items(request: Request):
    return templates.TemplateResponse("index.html", {"request": request, "items": items_db})


@app.get("/create", response_class=HTMLResponse)
def create_form(request: Request):
    return templates.TemplateResponse("create.html", {"request": request})


@app.post("/create")
def create_item(name: str = Form(...), description: str = Form(...), price: float = Form(...)):
    item_id = str(uuid4())
    items_db[item_id] = {"name": name, "description": description, "price": price}
    return RedirectResponse("/", status_code=303)


@app.get("/edit/{item_id}", response_class=HTMLResponse)
def edit_item(request: Request, item_id: str):
    item = items_db.get(item_id)
    return templates.TemplateResponse("update.html", {"request": request, "item": item, "item_id": item_id})


@app.post("/edit/{item_id}")
def update_item(item_id: str, name: str = Form(...), description: str = Form(...), price: float = Form(...)):
    if item_id in items_db:
        items_db[item_id] = {"name": name, "description": description, "price": price}
    return RedirectResponse("/", status_code=303)


@app.get("/delete/{item_id}")
def delete_item(item_id: str):
    items_db.pop(item_id, None)
    return RedirectResponse("/", status_code=303)
