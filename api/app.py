import os
from pathlib import Path
import numpy as np
import tensorflow as tf
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

MODEL_PATH=Path(os.getenv("MODEL_PATH","/models/tumor_unet.keras"))
SIZE=int(os.getenv("IMAGE_SIZE","256")); THRESHOLD=float(os.getenv("THRESHOLD","0.5"))
app=FastAPI(title="MRI Tumor Segmentation API",version="1.0")
model=None; load_error=None
class Request(BaseModel):
    image: list = Field(...,description="RGB image as [height,width,3], values 0..255")
@app.on_event("startup")
def startup():
    global model,load_error
    try:
        if not MODEL_PATH.exists(): raise FileNotFoundError(f"Model missing: {MODEL_PATH}")
        model=tf.keras.models.load_model(MODEL_PATH,compile=False); load_error=None
    except Exception as e: model=None; load_error=str(e)
@app.get("/health")
def health():
    return {"status":"ok" if model is not None else "model_unavailable","model_path":str(MODEL_PATH),"image_size":SIZE,"threshold":THRESHOLD,"error":load_error}
@app.post("/predict")
def predict(req:Request):
    if model is None: raise HTTPException(503,detail=f"Model unavailable: {load_error}")
    try:
        a=np.asarray(req.image,dtype=np.float32)
        if a.ndim!=3 or a.shape[2] not in (1,3,4): raise ValueError("Expected [height,width,3] RGB image.")
        if a.shape[2]==1: a=np.repeat(a,3,axis=2)
        if a.shape[2]==4: a=a[:,:,:3]
        if not np.isfinite(a).all() or a.size==0: raise ValueError("Image is empty or invalid.")
        if a.max()>1: a/=255.
        a=np.clip(a,0,1)
        x=tf.image.resize(a[None,...],[SIZE,SIZE])
        prob=model.predict(x,verbose=0)[0,:,:,0]
        mask=(prob>=THRESHOLD).astype(np.uint8)
        return {"mask":mask.tolist(),"threshold":THRESHOLD,"model":"tumor_unet.keras","note":"Research prediction only; not a diagnosis."}
    except ValueError as e: raise HTTPException(400,detail=str(e))
